CREATE OR REPLACE PROCEDURE JSON_ORM(
    json_data IN CLOB,
    v_sql_query OUT VARCHAR2,
    v_cursor OUT SYS_REFCURSOR
) IS
    v_sql_type VARCHAR2(100);
    trigger_query VARCHAR2(1000);
BEGIN
    v_sql_type := JSON_VALUE(json_data, '$.type');

    IF v_sql_type = 'SELECT' THEN
        EXECUTE_SELECT(json_data, v_sql_query); 
        OPEN v_cursor FOR v_sql_query;
    ELSIF v_sql_type = 'INSERT' THEN
        EXECUTE_INSERT(json_data, v_sql_query); 
        EXECUTE IMMEDIATE v_sql_query;
    ELSIF v_sql_type = 'UPDATE' THEN
        EXECUTE_UPDATE(json_data, v_sql_query);
        EXECUTE IMMEDIATE v_sql_query; 
    ELSIF v_sql_type = 'DELETE' THEN
        EXECUTE_DELETE(json_data, v_sql_query); 
        EXECUTE IMMEDIATE v_sql_query;
    ELSIF v_sql_type = 'CREATE' THEN
        EXECUTE_CREATE(json_data, v_sql_query, trigger_query); 
        EXECUTE IMMEDIATE v_sql_query;
        EXECUTE IMMEDIATE trigger_query;
        v_sql_query := v_sql_query || trigger_query;
    ELSIF v_sql_type = 'DROP' THEN
        EXECUTE_DROP(json_data, v_sql_query); 
        EXECUTE IMMEDIATE v_sql_query;
    END IF;   
END;

