
CREATE OR REPLACE PROCEDURE EXECUTE_CREATE(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2,
    trigger_query OUT VARCHAR2
) IS
    table_name VARCHAR2(100);
    primary_name VARCHAR2(100);
BEGIN
    table_name := JSON_VALUE(json_data, '$.table');
    primary_name := JSON_VALUE(json_data, '$.primary');

    v_sql_query := JSON_VALUE(json_data, '$.type') || ' TABLE ' || table_name || ' (' || CHR(10);

    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(json_data, '$.columns[*]'
            COLUMNS (
                column_name VARCHAR2(100) PATH '$.name',
                column_datatype VARCHAR2(100) PATH '$.datatype',
                column_constraint VARCHAR2(100) PATH '$.constraint' 
            )
        ) 
    )
    LOOP
        v_sql_query := v_sql_query || '    ' || rec.column_name || ' ' || rec.column_datatype;
        IF rec.column_constraint IS NOT NULL THEN
            v_sql_query := v_sql_query || ' ' || rec.column_constraint;
        END IF;
        v_sql_query := v_sql_query || ', ' || CHR(10);
    END LOOP;

    v_sql_query := v_sql_query || '    PRIMARY KEY (' || primary_name || '), ' || CHR(10);

    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(json_data, '$.foreign[*]'
            COLUMNS (
                column_name VARCHAR2(100) PATH '$.column',
                refcolumn_name VARCHAR2(100) PATH '$.refcolumn',
                reftable_name VARCHAR2(100) PATH '$.reftable' 
            )
        ) 
    )
    LOOP
        v_sql_query := v_sql_query || '    FOREIGN KEY (' || rec.column_name || ') REFERENCES '
                        || rec.reftable_name || ' (' || rec.refcolumn_name || '), ' || CHR(10);
    END LOOP;

    v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 3);

    v_sql_query := v_sql_query || CHR(10) || ')' || CHR(10);

    trigger_query := 'CREATE OR REPLACE TRIGGER trg_generate_pk_on_' || table_name || CHR(10) ||
                    'BEFORE INSERT ON ' || table_name || CHR(10) ||
                    'FOR EACH ROW' || CHR(10) ||
                    'BEGIN' || CHR(10) ||
                    '    IF :NEW.' || primary_name || ' IS NULL THEN' || CHR(10) ||
                    '        SELECT NVL(MAX(' || primary_name || '), 0) + 1 INTO :NEW.' || primary_name || ' FROM ' || table_name || ';' || CHR(10) ||
                    '    END IF;' || CHR(10) ||
                    'END;' || CHR(10);
END;
/





CREATE OR REPLACE PROCEDURE EXECUTE_DROP(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2
) IS
BEGIN
    v_sql_query := JSON_VALUE(json_data, '$.type') || ' TABLE ' || JSON_VALUE(json_data, '$.table');
END;
/
