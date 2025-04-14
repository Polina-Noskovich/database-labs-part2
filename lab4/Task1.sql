CREATE USER MYUSER IDENTIFIED BY 1111;
GRANT CONNECT, RESOURCE TO MYUSER;

SELECT USER FROM DUAL;

ALTER SESSION SET CURRENT_SCHEMA = MYUSER;

CREATE OR REPLACE PROCEDURE EXECUTE_SELECT(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2
) IS
    temp_string VARCHAR2(1000);
BEGIN
    v_sql_query := JSON_VALUE(json_data, '$.type') || ' ';

    FOR rec IN (
        SELECT value AS column_name
        FROM JSON_TABLE(json_data, '$.columns[*]' COLUMNS (value PATH '$'))
    )
    LOOP
        v_sql_query := v_sql_query || rec.column_name || ', ';
    END LOOP;
    v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 2);

    v_sql_query := v_sql_query || ' FROM ';
    FOR rec IN (
        SELECT value AS table_name
        FROM JSON_TABLE(json_data, '$.tables[*]' COLUMNS (value PATH '$'))
    )
    LOOP
        v_sql_query := v_sql_query || rec.table_name || ', ';
    END LOOP;
    v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 2) || CHR(10);

    FOR rec IN (
        SELECT join_table.*
        FROM JSON_TABLE(json_data, '$.joins[*]'
            COLUMNS (
                table_name VARCHAR2(100) PATH '$.table',
                operator VARCHAR2(100) PATH '$.operator',
                condition JSON PATH '$.condition'
            )
        ) join_table
    )
    LOOP
        v_sql_query := v_sql_query || 'JOIN ' || rec.table_name || ' ON ';

        FOR cond_rec IN (
            SELECT value AS condition
            FROM JSON_TABLE(rec.condition, '$[*]' COLUMNS (value VARCHAR2(100) PATH '$'))
        )
        LOOP
            IF rec.operator IS NULL THEN
                v_sql_query := v_sql_query || cond_rec.condition || ' AND ';
            ELSE
                v_sql_query := v_sql_query || cond_rec.condition || ' ' || rec.operator || ' ';
            END IF;
        END LOOP;

        IF rec.operator IS NULL THEN
            v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 5);
        ELSE
            v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - (2 + LENGTH(rec.operator)));
        END IF;

        v_sql_query := v_sql_query || CHR(10);
    END LOOP;
    
    FOR rec IN (
        SELECT filter_table.*
        FROM JSON_TABLE(json_data, '$.filters[*]'
            COLUMNS (
                filter_type VARCHAR2(100) PATH '$.type',
                operator VARCHAR2(100) PATH '$.operator',
                filter_body VARCHAR2(4000) FORMAT JSON PATH '$.body' 
            )
        ) filter_table
    )
    LOOP
        v_sql_query := v_sql_query || rec.filter_type || ' ';

        FOR body_rec IN ( 
            SELECT value AS element
            FROM JSON_TABLE(rec.filter_body, '$[*]' COLUMNS (value VARCHAR2(4000) FORMAT JSON PATH '$'))
        )
        LOOP
            IF JSON_EXISTS(body_rec.element, '$.type') THEN
                v_sql_query := v_sql_query || JSON_VALUE(JSON_QUERY(body_rec.element, '$.body'), '$.value') || ' '
                                || JSON_VALUE(body_rec.element, '$.type') || ' ';
                EXECUTE_SELECT(JSON_QUERY(JSON_QUERY(body_rec.element, '$.body'), '$.condition'), temp_string);
                v_sql_query := v_sql_query || '(' || temp_string || ')';
            ELSE
                v_sql_query := v_sql_query || REPLACE(body_rec.element, '"', '');
            END IF;

            IF rec.operator IS NULL THEN
                v_sql_query := v_sql_query || ' AND ';
            ELSE
                v_sql_query := v_sql_query || ' ' || rec.operator || ' ';
            END IF;
        END LOOP;

        IF rec.operator IS NULL THEN
            v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 5);
        ELSE
            v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - (2 + LENGTH(rec.operator)));
        END IF;
    END LOOP;
END;
/