

CREATE OR REPLACE PROCEDURE EXECUTE_INSERT(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2
) IS
    temp_string VARCHAR2(1000);
BEGIN
    v_sql_query := JSON_VALUE(json_data, '$.type') || ' INTO ' || JSON_VALUE(json_data, '$.table') || ' (';

    FOR rec IN (
        SELECT value AS column_name
        FROM JSON_TABLE(json_data, '$.columns[*]' COLUMNS (value PATH '$'))
    )
    LOOP
        v_sql_query := v_sql_query || rec.column_name || ', ';
    END LOOP;
    v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 2) || ') VALUES ';

    FOR rec IN (
        SELECT column_value AS item
        FROM JSON_TABLE(json_data, '$.values[*]' COLUMNS (
            column_value VARCHAR2(4000) FORMAT JSON PATH '$'
        ))
    )
    LOOP
        temp_string := REPLACE(rec.item, '[', '');
        v_sql_query := v_sql_query || '(' || REPLACE(REPLACE(temp_string, ']', ''), '"', '''') || '), ';
    END LOOP;
    v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 2);
END;
/


CREATE OR REPLACE PROCEDURE EXECUTE_UPDATE(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2
) IS
    temp_string VARCHAR2(1000);
    v_number NUMBER;
BEGIN
    v_sql_query := JSON_VALUE(json_data, '$.type') || ' ' || JSON_VALUE(json_data, '$.table') || CHR(10) || 'SET ';

    FOR rec IN (
        SELECT * 
        FROM JSON_TABLE(json_data, '$.set[*]' COLUMNS (
            column_name VARCHAR2(4000) PATH '$.column',
            column_value VARCHAR2(4000) PATH '$.value'
        ))
    )
    LOOP
        BEGIN
            v_number := TO_NUMBER(rec.column_value);
            v_sql_query := v_sql_query || rec.column_name || ' = ' || rec.column_value || ', ';
        EXCEPTION
            WHEN OTHERS THEN
                v_sql_query := v_sql_query || rec.column_name || ' = ''' || rec.column_value || ''', ';
        END;
    END LOOP;

    v_sql_query := SUBSTR(v_sql_query, 1, LENGTH(v_sql_query) - 2) || CHR(10);

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

        v_sql_query := v_sql_query || CHR(10);
    END LOOP;
END;
/







CREATE OR REPLACE PROCEDURE EXECUTE_DELETE(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2
) IS
    temp_string VARCHAR2(1000);
BEGIN
    v_sql_query := JSON_VALUE(json_data, '$.type') || ' FROM ' || JSON_VALUE(json_data, '$.table') || CHR(10);

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

