CREATE OR REPLACE PROCEDURE get_plsql_procs_and_funcs(
  p_schema_name IN VARCHAR2, 
  p_object_name IN VARCHAR2, 
  p_code OUT VARCHAR2
) IS
  v_code VARCHAR2(32767);
BEGIN
  v_code := '';

  FOR r IN (
    SELECT object_name, object_type
    FROM all_objects
    WHERE (object_type = 'FUNCTION' OR object_type = 'PROCEDURE')
    AND owner = UPPER(p_schema_name)
    AND object_name = UPPER(p_object_name)
  ) LOOP
    FOR proc_func IN (
      SELECT text AS text 
      FROM all_source
      WHERE owner = UPPER(p_schema_name)
      AND name = r.object_name
      ORDER BY line
    ) LOOP
      DECLARE
        v_text VARCHAR2(32767);
      BEGIN
        v_text := TRIM(TRIM(CHR(10) FROM proc_func.text)); 
        IF LENGTH(v_text) > 0 THEN
           v_text := REGEXP_REPLACE(v_text, '\s+', ' ');
           v_code := v_code || v_text || CHR(10);
        END IF;
      END;
    END LOOP;
  END LOOP;

  p_code := v_code;
END get_plsql_procs_and_funcs;

CREATE OR REPLACE PROCEDURE compare_functions_and_procedures(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,
    v_ddl_commands IN OUT CLOB_LIST
) IS
    v_dev_code CLOB; 
    v_prod_code CLOB; 
    v_has_diff BOOLEAN := FALSE;
BEGIN
    FOR dev_only IN (
        SELECT object_name, object_type
        FROM all_objects
        WHERE (object_type = 'FUNCTION' OR object_type = 'PROCEDURE')
        AND owner = UPPER(dev_schema_name)
        AND object_name NOT IN (
            SELECT object_name
            FROM all_objects
            WHERE (object_type = 'FUNCTION' OR object_type = 'PROCEDURE')
            AND owner = UPPER(prod_schema_name)
        )
    ) LOOP
        IF NOT v_has_diff THEN
            DBMS_OUTPUT.PUT_LINE('Функции и процедуры, которые есть в ' || UPPER(dev_schema_name) || ', но отсутствуют в ' || UPPER(prod_schema_name) || ':');
            v_has_diff := TRUE;
        END IF;

        get_plsql_procs_and_funcs(dev_schema_name, dev_only.object_name, v_dev_code);

        IF v_dev_code LIKE 'PROCEDURE%' THEN
            v_dev_code := SUBSTR(v_dev_code, INSTR(v_dev_code, 'IS') + 2); 
        ELSIF v_dev_code LIKE 'FUNCTION%' THEN
            v_dev_code := SUBSTR(v_dev_code, INSTR(v_dev_code, 'IS') + 2);  
        END IF;

        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := '';  
        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := '';  
        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := 'CREATE OR REPLACE ' || dev_only.object_type || ' ' || prod_schema_name || '.' || dev_only.object_name || ' AS ' || v_dev_code;

        DBMS_OUTPUT.PUT_LINE('  - ' || dev_only.object_name);
    END LOOP;


    FOR prod_only IN (
        SELECT object_name, object_type
        FROM all_objects
        WHERE (object_type = 'FUNCTION' OR object_type = 'PROCEDURE')
        AND owner = UPPER(prod_schema_name)
        AND object_name NOT IN (
            SELECT object_name
            FROM all_objects
            WHERE (object_type = 'FUNCTION' OR object_type = 'PROCEDURE')
            AND owner = UPPER(dev_schema_name)
        )
    ) LOOP
        IF NOT v_has_diff THEN
            DBMS_OUTPUT.PUT_LINE('Функции и процедуры, которые есть в ' || UPPER(prod_schema_name) || ', но отсутствуют в ' || UPPER(dev_schema_name) || ':');
            v_has_diff := TRUE;
        END IF;

        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := '';
        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := '';
        v_ddl_commands.EXTEND;
        v_ddl_commands(v_ddl_commands.COUNT) := 'DROP ' || prod_only.object_type || ' ' || prod_schema_name || '.' || prod_only.object_name;

        DBMS_OUTPUT.PUT_LINE('  - ' || prod_only.object_name);
    END LOOP;


   FOR common_obj IN (
        SELECT dev.object_name, dev.object_type
        FROM all_objects dev
        JOIN all_objects prod
        ON dev.object_name = prod.object_name
        AND dev.object_type = prod.object_type
        WHERE (dev.object_type = 'FUNCTION' OR dev.object_type = 'PROCEDURE')
        AND dev.owner = UPPER(dev_schema_name)
        AND prod.owner = UPPER(prod_schema_name)
    ) LOOP
        get_plsql_procs_and_funcs(dev_schema_name, common_obj.object_name, v_dev_code);
        get_plsql_procs_and_funcs(prod_schema_name, common_obj.object_name, v_prod_code);

        IF v_dev_code <> v_prod_code THEN
            IF NOT v_has_diff THEN
                DBMS_OUTPUT.PUT_LINE('Функции и процедуры, которые отличаются между ' || UPPER(dev_schema_name) || ' и ' || UPPER(prod_schema_name) || ':');
                v_has_diff := TRUE;
            END IF;

            IF v_dev_code LIKE 'PROCEDURE%' OR v_dev_code LIKE 'FUNCTION%' THEN
                IF INSTR(v_dev_code, 'IS') > 0 THEN
                    v_dev_code := SUBSTR(v_dev_code, INSTR(v_dev_code, 'IS') + 2);
                ELSIF INSTR(v_dev_code, 'AS') > 0 THEN
                    v_dev_code := SUBSTR(v_dev_code, INSTR(v_dev_code, 'AS') + 2);
                END IF;
            END IF;

            v_ddl_commands.EXTEND;
            v_ddl_commands(v_ddl_commands.COUNT) := '';
            v_ddl_commands.EXTEND;
            v_ddl_commands(v_ddl_commands.COUNT) := ''; 
            v_ddl_commands.EXTEND;
            v_ddl_commands(v_ddl_commands.COUNT) := 'CREATE OR REPLACE ' || common_obj.object_type || ' ' || prod_schema_name || '.' || common_obj.object_name || ' AS ' || v_dev_code;

            DBMS_OUTPUT.PUT_LINE('  - ' || common_obj.object_name);
        END IF;
    END LOOP;


    IF NOT v_has_diff THEN
        DBMS_OUTPUT.PUT_LINE('Функции и процедуры в схемах ' || UPPER(dev_schema_name) || ' и ' || UPPER(prod_schema_name) || ' совпадают.');
    END IF;
END compare_functions_and_procedures;

CREATE OR REPLACE PROCEDURE compare_indexes(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,
    ddl_commands IN OUT CLOB_LIST
) IS
    v_has_index_differences BOOLEAN := FALSE;
BEGIN
    FOR r_index IN (
        SELECT i.INDEX_NAME, i.TABLE_NAME, LISTAGG(c.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLUMN_LIST
        FROM ALL_INDEXES i
        JOIN ALL_IND_COLUMNS c ON i.INDEX_NAME = c.INDEX_NAME AND i.TABLE_NAME = c.TABLE_NAME AND i.OWNER = c.INDEX_OWNER
        WHERE i.OWNER = dev_schema_name
        AND i.TABLE_NAME IN (
            SELECT TABLE_NAME
            FROM ALL_TABLES
            WHERE OWNER = prod_schema_name
        )
        AND i.INDEX_NAME NOT IN (
            SELECT INDEX_NAME
            FROM ALL_INDEXES
            WHERE OWNER = prod_schema_name
        )
        GROUP BY i.INDEX_NAME, i.TABLE_NAME
    ) LOOP
        IF NOT v_has_index_differences THEN
            v_has_index_differences := TRUE;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Индекс ' || r_index.INDEX_NAME || ' есть в DEV_SCHEMA, но отсутствует в PROD_SCHEMA.');
        ddl_commands.EXTEND;
        ddl_commands(ddl_commands.COUNT) := 'CREATE INDEX ' || prod_schema_name || '.' || r_index.INDEX_NAME || ' ON ' || prod_schema_name || '.' || r_index.TABLE_NAME || '(' || r_index.COLUMN_LIST || ');';
    END LOOP;

    FOR r_index IN (
        SELECT i.INDEX_NAME, i.TABLE_NAME, LISTAGG(c.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLUMN_LIST
        FROM ALL_INDEXES i
        JOIN ALL_IND_COLUMNS c ON i.INDEX_NAME = c.INDEX_NAME AND i.TABLE_NAME = c.TABLE_NAME AND i.OWNER = c.INDEX_OWNER
        WHERE i.OWNER = prod_schema_name
        AND i.TABLE_NAME IN (
            SELECT TABLE_NAME
            FROM ALL_TABLES
            WHERE OWNER = dev_schema_name
        )
        AND i.INDEX_NAME NOT IN (
            SELECT INDEX_NAME
            FROM ALL_INDEXES
            WHERE OWNER = dev_schema_name
        )
        GROUP BY i.INDEX_NAME, i.TABLE_NAME
    ) LOOP
        IF NOT v_has_index_differences THEN
            v_has_index_differences := TRUE;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Индекс ' || r_index.INDEX_NAME || ' есть в PROD_SCHEMA, но отсутствует в DEV_SCHEMA.');
        ddl_commands.EXTEND;
        ddl_commands(ddl_commands.COUNT) := 'DROP INDEX ' || prod_schema_name || '.' || r_index.INDEX_NAME || ';';
    END LOOP;

    IF NOT v_has_index_differences THEN
        DBMS_OUTPUT.PUT_LINE('Отличий в индексах между DEV_SCHEMA и PROD_SCHEMA не обнаружено.');
    END IF;
END compare_indexes;

CREATE OR REPLACE PROCEDURE compare_packages(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,
    ddl_commands IN OUT CLOB_LIST
) IS
    v_has_package_differences BOOLEAN := FALSE;
BEGIN
    FOR r_package IN (
        SELECT OBJECT_NAME
        FROM ALL_OBJECTS
        WHERE OWNER = dev_schema_name
          AND OBJECT_TYPE = 'PACKAGE'
          AND OBJECT_NAME NOT IN (
              SELECT OBJECT_NAME
              FROM ALL_OBJECTS
              WHERE OWNER = prod_schema_name
                AND OBJECT_TYPE = 'PACKAGE'
          )
    ) LOOP
        IF NOT v_has_package_differences THEN
            v_has_package_differences := TRUE;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Пакет ' || r_package.OBJECT_NAME || ' есть в DEV_SCHEMA, но отсутствует в PROD_SCHEMA.');
        ddl_commands.EXTEND;
        ddl_commands(ddl_commands.COUNT) := 'CREATE OR REPLACE PACKAGE ' || prod_schema_name || '.' || r_package.OBJECT_NAME || ' AS <код_пакета>;';
    END LOOP;

    FOR r_package IN (
        SELECT OBJECT_NAME
        FROM ALL_OBJECTS
        WHERE OWNER = prod_schema_name
          AND OBJECT_TYPE = 'PACKAGE'
          AND OBJECT_NAME NOT IN (
              SELECT OBJECT_NAME
              FROM ALL_OBJECTS
              WHERE OWNER = dev_schema_name
                AND OBJECT_TYPE = 'PACKAGE'
          )
    ) LOOP
        IF NOT v_has_package_differences THEN
            v_has_package_differences := TRUE;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Пакет ' || r_package.OBJECT_NAME || ' есть в PROD_SCHEMA, но отсутствует в DEV_SCHEMA.');
        ddl_commands.EXTEND;
        ddl_commands(ddl_commands.COUNT) := 'DROP PACKAGE ' || prod_schema_name || '.' || r_package.OBJECT_NAME || ';';
    END LOOP;

    IF NOT v_has_package_differences THEN
        DBMS_OUTPUT.PUT_LINE('Отличий в пакетах между DEV_SCHEMA и PROD_SCHEMA не обнаружено.');
    END IF;
END compare_packages;
