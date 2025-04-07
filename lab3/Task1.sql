CREATE OR REPLACE TYPE CLOB_LIST AS TABLE OF CLOB;
/

-- Затем создайте все процедуры и функции в правильном порядке:
-- 1. compare_tables
-- 2. compare_table_structure
-- 3. add_constraints


-- 4. get_plsql_procs_and_funcs
-- 5. compare_functions_and_procedures
-- 6. compare_indexes
-- 7. compare_packages

-- 8. determine_table_creation_order
-- 9. compare_schemes


CREATE OR REPLACE FUNCTION compare_tables(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,
    v_ddl_commands IN OUT CLOB_LIST
) RETURN BOOLEAN IS
    TYPE table_list IS TABLE OF VARCHAR2(30);
    v_tables table_list;
    v_table_differences BOOLEAN := FALSE;

    PROCEDURE compare_and_generate_ddl(source_schema IN VARCHAR2, target_schema IN VARCHAR2, ddl_action IN VARCHAR2) IS
    BEGIN
        SELECT TABLE_NAME BULK COLLECT INTO v_tables
        FROM ALL_TABLES WHERE OWNER = source_schema
        AND TABLE_NAME NOT IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = target_schema);

        IF v_tables.COUNT > 0 THEN
            FOR i IN 1 .. v_tables.COUNT LOOP
                DBMS_OUTPUT.PUT_LINE('  - ' || v_tables(i));
                v_ddl_commands.EXTEND;
                IF ddl_action = 'CREATE' THEN
                    v_ddl_commands(v_ddl_commands.COUNT) := 'CREATE TABLE ' || target_schema || '.' || v_tables(i) || ' AS SELECT * FROM ' || source_schema || '.' || v_tables(i) || ' WHERE 1 = 0;';
                ELSIF ddl_action = 'DROP' THEN
                    v_ddl_commands(v_ddl_commands.COUNT) := 'DROP TABLE ' || target_schema || '.' || v_tables(i) || ';';
                END IF;
            END LOOP;
            v_table_differences := TRUE;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Все таблицы из ' || source_schema || ' присутствуют в ' || target_schema || '.');
        END IF;
    END compare_and_generate_ddl;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Таблицы, которые есть в DEV_SCHEMA, но отсутствуют в PROD_SCHEMA:');
    compare_and_generate_ddl(dev_schema_name, prod_schema_name, 'CREATE');
    DBMS_OUTPUT.PUT_LINE('Таблицы, которые есть в PROD_SCHEMA, но отсутствуют в DEV_SCHEMA:');
    compare_and_generate_ddl(prod_schema_name, dev_schema_name, 'DROP');

    RETURN v_table_differences;
END compare_tables;
/
CREATE OR REPLACE FUNCTION compare_table_structure(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,
    v_ddl_commands IN OUT CLOB_LIST
) RETURN BOOLEAN IS
    v_has_differences BOOLEAN := FALSE;
    v_any_differences BOOLEAN := FALSE;

    PROCEDURE log_difference(table_name IN VARCHAR2, message IN VARCHAR2) IS
    BEGIN
        IF NOT v_has_differences THEN
            DBMS_OUTPUT.PUT_LINE('Таблица ' || table_name || ' в DEV_SCHEMA и PROD_SCHEMA отличается:');
            v_has_differences := TRUE;
            v_any_differences := TRUE;
        END IF;
        DBMS_OUTPUT.PUT_LINE('  - ' || message);
    END log_difference;

    PROCEDURE add_ddl_command(command IN VARCHAR2) IS
    BEGIN
        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := command;
    END add_ddl_command;
BEGIN
    FOR r_table IN (
        SELECT TABLE_NAME
        FROM ALL_TABLES
        WHERE OWNER = dev_schema_name
          AND TABLE_NAME IN (
              SELECT TABLE_NAME
              FROM ALL_TABLES
              WHERE OWNER = prod_schema_name
          )
    ) LOOP
        v_has_differences := FALSE;

        FOR r_column IN (
            SELECT column_name, data_type, data_length, 'ADD' as action
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = dev_schema_name AND table_name = r_table.TABLE_NAME
            MINUS
            SELECT column_name, data_type, data_length, 'ADD'
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = prod_schema_name AND table_name = r_table.TABLE_NAME

            UNION ALL

            SELECT column_name, NULL, NULL, 'DROP'
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = prod_schema_name AND table_name = r_table.TABLE_NAME
            MINUS
            SELECT column_name, NULL, NULL, 'DROP'
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = dev_schema_name AND table_name = r_table.TABLE_NAME

            UNION ALL

            SELECT dev.column_name, dev.data_type, dev.data_length, 'MODIFY'
            FROM ALL_TAB_COLUMNS dev
            JOIN ALL_TAB_COLUMNS prod ON dev.column_name = prod.column_name
            WHERE dev.OWNER = dev_schema_name
              AND prod.OWNER = prod_schema_name
              AND dev.table_name = r_table.TABLE_NAME
              AND prod.table_name = r_table.TABLE_NAME
              AND (dev.data_type != prod.data_type OR dev.data_length != prod.data_length)
        ) LOOP
            IF r_column.action = 'ADD' THEN
                log_difference(r_table.TABLE_NAME, 'Столбец ' || r_column.column_name || ' есть в DEV_SCHEMA но отсутствует в PROD_SCHEMA.');
                add_ddl_command('ALTER TABLE ' || prod_schema_name || '.' || r_table.TABLE_NAME ||
                                ' ADD ' || r_column.column_name || ' ' || r_column.data_type ||
                                '(' || r_column.data_length || ');');

            ELSIF r_column.action = 'DROP' THEN
                log_difference(r_table.TABLE_NAME, 'Столбец ' || r_column.column_name || ' есть в PROD_SCHEMA но отсутствует в DEV_SCHEMA.');
                add_ddl_command('ALTER TABLE ' || prod_schema_name || '.' || r_table.TABLE_NAME ||
                                ' DROP COLUMN ' || r_column.column_name || ';');

            ELSIF r_column.action = 'MODIFY' THEN
                log_difference(r_table.TABLE_NAME, 'Столбец ' || r_column.column_name || ' отличается.');
                add_ddl_command('ALTER TABLE ' || prod_schema_name || '.' || r_table.TABLE_NAME ||
                                ' MODIFY ' || r_column.column_name || ' ' || r_column.data_type ||
                                '(' || r_column.data_length || ');');
            END IF;
        END LOOP;
    END LOOP;

    IF NOT v_any_differences THEN
        DBMS_OUTPUT.PUT_LINE('Отличий в структуре таблиц между DEV_SCHEMA и PROD_SCHEMA не обнаружено.');
    END IF;

    RETURN v_any_differences;
END compare_table_structure;

CREATE OR REPLACE PROCEDURE add_constraints(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,
    v_ddl_commands IN OUT CLOB_LIST
) IS
    PROCEDURE add_command(command IN VARCHAR2) IS
    BEGIN
        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := command;
    END add_command;
BEGIN
    FOR r_table IN (
        SELECT TABLE_NAME 
        FROM ALL_TABLES 
        WHERE OWNER = dev_schema_name
        AND TABLE_NAME NOT IN (
            SELECT TABLE_NAME 
            FROM ALL_TABLES 
            WHERE OWNER = prod_schema_name
        )
    ) LOOP
        FOR r_constraint IN (
            SELECT ac.constraint_name, acc.column_name,
                   CASE ac.constraint_type 
                       WHEN 'P' THEN 'PRIMARY KEY'
                       WHEN 'U' THEN 'UNIQUE'
                   END AS constraint_type,
                   NULL AS referenced_table,
                   NULL AS referenced_column
            FROM ALL_CONSTRAINTS ac
            JOIN ALL_CONS_COLUMNS acc ON ac.constraint_name = acc.constraint_name
            WHERE ac.OWNER = dev_schema_name
              AND ac.table_name = r_table.TABLE_NAME
              AND ac.constraint_type IN ('P', 'U')

            UNION ALL

            SELECT a.constraint_name, acc.column_name, 
                   'FOREIGN KEY' AS constraint_type,
                   c.table_name AS referenced_table,
                   c.column_name AS referenced_column
            FROM ALL_CONSTRAINTS a
            JOIN ALL_CONS_COLUMNS acc ON a.constraint_name = acc.constraint_name
            JOIN ALL_CONS_COLUMNS c ON a.r_constraint_name = c.constraint_name
            WHERE a.OWNER = dev_schema_name
              AND a.table_name = r_table.TABLE_NAME
              AND a.constraint_type = 'R'
        ) LOOP
            IF r_constraint.constraint_type = 'FOREIGN KEY' THEN
                add_command('ALTER TABLE ' || prod_schema_name || '.' || r_table.TABLE_NAME || 
                            ' ADD CONSTRAINT ' || r_constraint.constraint_name || 
                            ' FOREIGN KEY (' || r_constraint.column_name || 
                            ') REFERENCES ' || prod_schema_name || '.' || 
                            r_constraint.referenced_table || '(' || r_constraint.referenced_column || ');');
            ELSE
                add_command('ALTER TABLE ' || prod_schema_name || '.' || r_table.TABLE_NAME || 
                            ' ADD CONSTRAINT ' || r_constraint.constraint_name || 
                            ' ' || r_constraint.constraint_type || 
                            ' (' || r_constraint.column_name || ');');
            END IF;
        END LOOP;
    END LOOP;
END add_constraints;
