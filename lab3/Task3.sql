CREATE OR REPLACE PROCEDURE determine_table_creation_order(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
) IS
    TYPE table_name_array IS TABLE OF VARCHAR2(30);
    v_independent_tables table_name_array := table_name_array(); 
    v_dependent_tables table_name_array := table_name_array();
    v_non_circular_dependent_tables table_name_array := table_name_array();
    v_circular_tables table_name_array := table_name_array(); 
    v_is_circular BOOLEAN;

    TYPE cycle_pair IS RECORD (
        table1 VARCHAR2(30),
        table2 VARCHAR2(30)
    );
    TYPE cycle_list IS TABLE OF cycle_pair;
    v_cycles cycle_list := cycle_list();

    TYPE dependency_pair IS RECORD (
        child_table VARCHAR2(30),
        parent_table VARCHAR2(30)
    );
    TYPE dependency_list IS TABLE OF dependency_pair;
    v_dependencies dependency_list := dependency_list();

    PROCEDURE topological_dfs(
        table_name IN VARCHAR2,
        dependencies IN dependency_list,
        visited IN OUT table_name_array,
        sorted IN OUT table_name_array
    ) IS
    BEGIN
        visited.EXTEND;
        visited(visited.COUNT) := table_name;

        FOR i IN 1 .. dependencies.COUNT LOOP
            IF dependencies(i).child_table = table_name AND NOT dependencies(i).parent_table MEMBER OF visited THEN
                topological_dfs(dependencies(i).parent_table, dependencies, visited, sorted);
            END IF;
        END LOOP;

        sorted.EXTEND;
        sorted(sorted.COUNT) := table_name;
    END topological_dfs;

    FUNCTION topological_sort(tables IN table_name_array, dependencies IN dependency_list)
    RETURN table_name_array IS
        v_sorted table_name_array := table_name_array();
        v_visited table_name_array := table_name_array();
        v_temp table_name_array;
    BEGIN
        FOR i IN 1 .. tables.COUNT LOOP
            IF NOT tables(i) MEMBER OF v_visited THEN
                v_temp := table_name_array();
                topological_dfs(tables(i), dependencies, v_visited, v_temp);
                v_sorted := v_sorted MULTISET UNION v_temp;
            END IF;
        END LOOP;
        RETURN v_sorted;
    END topological_sort;
BEGIN
    SELECT table_name BULK COLLECT INTO v_independent_tables
    FROM all_tables
    WHERE owner = dev_schema_name
    AND table_name NOT IN (
        SELECT a.table_name
        FROM all_constraints a
        WHERE a.owner = dev_schema_name
            AND a.constraint_type = 'R'
    )
    AND table_name NOT IN (
        SELECT c.table_name
        FROM all_constraints c
        WHERE c.owner = dev_schema_name
            AND c.constraint_type = 'P'
    )
    AND table_name NOT IN (
        SELECT table_name
        FROM all_tables
        WHERE owner = prod_schema_name
    );

    SELECT table_name BULK COLLECT INTO v_dependent_tables
    FROM all_tables
    WHERE owner = dev_schema_name
    AND (
        table_name IN (
            SELECT a.table_name
            FROM all_constraints a
            WHERE a.owner = dev_schema_name
                AND a.constraint_type = 'R'
        )
        OR table_name IN (
            SELECT c.table_name
            FROM all_constraints c
            WHERE c.owner = dev_schema_name
                AND c.constraint_type = 'P'
        )
    )
    AND table_name NOT IN (
        SELECT table_name
        FROM all_tables
        WHERE owner = prod_schema_name
    );

    IF v_independent_tables.COUNT = 0 AND v_dependent_tables.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Нет таблиц для создания: все таблицы из DEV_SCHEMA уже присутствуют в PROD_SCHEMA.');
        RETURN;
    END IF;

    SELECT a.table_name AS child_table, c.table_name AS parent_table
    BULK COLLECT INTO v_dependencies
    FROM all_constraints a
    JOIN all_constraints c ON a.r_constraint_name = c.constraint_name
    WHERE a.owner = dev_schema_name
    AND c.owner = dev_schema_name
    AND a.constraint_type = 'R'
    AND a.table_name NOT IN (SELECT table_name FROM all_tables WHERE owner = prod_schema_name)
    AND c.table_name NOT IN (SELECT table_name FROM all_tables WHERE owner = prod_schema_name);

    WITH cycle_detection AS (
        SELECT a.table_name AS child_table, c.table_name AS parent_table
        FROM all_constraints a
        JOIN all_constraints c ON a.r_constraint_name = c.constraint_name
        WHERE a.owner = dev_schema_name
        AND c.owner = dev_schema_name
        AND a.constraint_type = 'R'
        AND a.table_name NOT IN (SELECT table_name FROM all_tables WHERE owner = prod_schema_name)
        AND c.table_name NOT IN (SELECT table_name FROM all_tables WHERE owner = prod_schema_name)
    )
    SELECT child_table, parent_table
    BULK COLLECT INTO v_cycles
    FROM cycle_detection d1
    WHERE EXISTS (
        SELECT 1 FROM cycle_detection d2
        WHERE d1.child_table = d2.parent_table 
        AND d1.parent_table = d2.child_table
    );

    FOR i IN 1 .. v_dependent_tables.COUNT LOOP
        v_is_circular := FALSE;
        FOR j IN 1 .. v_cycles.COUNT LOOP
            IF v_dependent_tables(i) = v_cycles(j).table1 OR v_dependent_tables(i) = v_cycles(j).table2 THEN
                v_is_circular := TRUE;
                EXIT;
            END IF;
        END LOOP;

        IF v_is_circular THEN
            v_circular_tables.EXTEND;
            v_circular_tables(v_circular_tables.COUNT) := v_dependent_tables(i);
        ELSE
            v_non_circular_dependent_tables.EXTEND;
            v_non_circular_dependent_tables(v_non_circular_dependent_tables.COUNT) := v_dependent_tables(i);
        END IF;
    END LOOP;

    v_non_circular_dependent_tables := topological_sort(v_non_circular_dependent_tables, v_dependencies);

    IF v_independent_tables.COUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблицы без зависимостей:');
        FOR i IN 1 .. v_independent_tables.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('  - ' || v_independent_tables(i));
        END LOOP;
    END IF;

    IF v_non_circular_dependent_tables.COUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблицы с зависимостями:');
        FOR i IN 1 .. v_non_circular_dependent_tables.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('  - ' || v_non_circular_dependent_tables(i));
        END LOOP;
    END IF;

    IF v_circular_tables.COUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Обнаруженные циклические зависимости:');
        FOR i IN 1 .. v_circular_tables.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('  - ' || v_circular_tables(i));
        END LOOP;
    END IF;
END determine_table_creation_order;

CREATE OR REPLACE PROCEDURE compare_schemes(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
) IS
    v_ddl_commands CLOB_LIST := CLOB_LIST();
    v_has_differences BOOLEAN := FALSE;
    v_table_differences BOOLEAN := FALSE;
    v_any_differences BOOLEAN := FALSE;
    v_has_circular_dependencies BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--------------------- Сравнение таблиц ---------------------');
    v_table_differences := compare_tables(dev_schema_name, prod_schema_name, v_ddl_commands);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('------------------------ Структуры таблиц --------------------------');
    v_has_differences := compare_table_structure(dev_schema_name, prod_schema_name, v_ddl_commands);
    add_constraints(dev_schema_name, prod_schema_name, v_ddl_commands);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
        
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--------------------- Сравнение процедур и функций  ---------------------');
    compare_functions_and_procedures(dev_schema_name, prod_schema_name, v_ddl_commands);
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------');

    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--------------------- Сравнение индексов ---------------------');
    compare_indexes(dev_schema_name, prod_schema_name, v_ddl_commands);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------');

    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('---------------------- Сравнение пакетов --------------------');
    compare_packages(dev_schema_name, prod_schema_name, v_ddl_commands);
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');

    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('-------------------- Сортировка зависимостей--------------------');
    determine_table_creation_order(dev_schema_name, prod_schema_name);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------');

    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--------------------- DLL команды ---------------------');
    FOR i IN 1 .. v_ddl_commands.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_ddl_commands(i));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------');

    DBMS_OUTPUT.PUT_LINE('');
END;


SET SERVEROUTPUT ON;
BEGIN
    compare_schemes('DEV_USER','PROD_USER');
END;
/

