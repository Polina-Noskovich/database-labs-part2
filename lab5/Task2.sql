CREATE TABLE TablesLog(
    id NUMBER PRIMARY KEY,
    operation_time TIMESTAMP,
    table_id NUMBER,
    table_number NUMBER
);

CREATE TABLE LastReport (
    id NUMBER PRIMARY KEY,
    datetime TIMESTAMP
);

INSERT INTO LastReport VALUES(1, NULL);


begin
GenerateLoggingTable('TESTTABLE1');
GenerateLoggingTable('TESTTABLE2');
GenerateLoggingTable('TESTTABLE3');
end;

GRANT EXECUTE ON test_user.GenerateLoggingTable TO TEST_USER;

GRANT EXECUTE ON test_user.GenerateLoggingTable TO TEST_USER;
GRANT CREATE TABLE, CREATE TRIGGER TO TEST_USER;



ALTER SESSION SET CURRENT_SCHEMA = test_user;
GRANT CREATE TRIGGER TO test_user;


CREATE OR REPLACE TRIGGER LoggingTable1_logger
BEFORE INSERT OR DELETE
ON LOGGINGFORTESTTABLE1 FOR EACH ROW
DECLARE
    log_id NUMBER;
BEGIN
    SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM TablesLog;

    IF INSERTING THEN
        INSERT INTO TablesLog (id, operation_time, table_id, table_number)
        VALUES (log_id, CURRENT_TIMESTAMP, :NEW.id, 1);
    ELSIF DELETING THEN
        DELETE FROM TablesLog WHERE table_id = :OLD.id AND table_number = 1;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER LoggingTable2_logger
BEFORE INSERT OR DELETE
ON LOGGINGFORTESTTABLE2 FOR EACH ROW
DECLARE
    log_id NUMBER;
BEGIN
    SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM TablesLog;

    IF INSERTING THEN
        INSERT INTO TablesLog (id, operation_time, table_id, table_number)
        VALUES (log_id, CURRENT_TIMESTAMP, :NEW.id, 2);
    ELSIF DELETING THEN
        DELETE FROM TablesLog WHERE table_id = :OLD.id AND table_number = 2;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER LoggingTable3_logger
BEFORE INSERT OR DELETE
ON LOGGINGFORTESTTABLE3 FOR EACH ROW
DECLARE
    log_id NUMBER;
BEGIN
    SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM TablesLog;

    IF INSERTING THEN
        INSERT INTO TablesLog (id, operation_time, table_id, table_number)
        VALUES (log_id, CURRENT_TIMESTAMP, :NEW.id, 3);
    ELSIF DELETING THEN
        DELETE FROM TablesLog WHERE table_id = :OLD.id AND table_number = 3;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Trigger_TESTTABLE1
    BEFORE INSERT OR UPDATE
    ON TESTTABLE1 FOR EACH ROW
    DECLARE
        log_id NUMBER;
    BEGIN
        SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM LOGGINGFORTESTTABLE1;

        IF INSERTING THEN
            INSERT INTO LOGGINGFORTESTTABLE1 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_VALUE, OLD_VALUE)
            VALUES (log_id, 'INSERT', CURRENT_TIMESTAMP, :NEW.ID, NULL, :NEW.NAME, NULL, :NEW.VALUE, NULL);
        ELSIF UPDATING THEN
            INSERT INTO LOGGINGFORTESTTABLE1 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_VALUE, OLD_VALUE)
            VALUES (log_id, 'UPDATE', CURRENT_TIMESTAMP, :NEW.ID, :OLD.ID, :NEW.NAME, :OLD.NAME, :NEW.VALUE, :OLD.VALUE);
        END IF;
    END;
/

CREATE OR REPLACE TRIGGER Deletion_Trigger_TESTTABLE1
    AFTER delete
    ON TESTTABLE1 FOR EACH ROW
    DECLARE
        log_id NUMBER;
    BEGIN
        SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM LOGGINGFORTESTTABLE1;

        INSERT INTO LOGGINGFORTESTTABLE1 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_VALUE, OLD_VALUE)
        VALUES (log_id, 'DELETE', CURRENT_TIMESTAMP, NULL, :OLD.ID, NULL, :OLD.NAME, NULL, :OLD.VALUE);
    END;
/

CREATE OR REPLACE TRIGGER Trigger_TESTTABLE2
    BEFORE INSERT OR UPDATE OR DELETE
    ON TESTTABLE2 FOR EACH ROW
    DECLARE
        log_id NUMBER;
    BEGIN
        SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM LOGGINGFORTESTTABLE2;

        IF INSERTING THEN
            INSERT INTO LOGGINGFORTESTTABLE2 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_DATETIME, OLD_DATETIME)
            VALUES (log_id, 'INSERT', CURRENT_TIMESTAMP, :NEW.ID, NULL, :NEW.NAME, NULL, :NEW.DATETIME, NULL);
        ELSIF UPDATING THEN
            INSERT INTO LOGGINGFORTESTTABLE2 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_DATETIME, OLD_DATETIME)
            VALUES (log_id, 'UPDATE', CURRENT_TIMESTAMP, :NEW.ID, :OLD.ID, :NEW.NAME, :OLD.NAME, :NEW.DATETIME, :OLD.DATETIME);
        END IF;
    END;
/

CREATE OR REPLACE TRIGGER Deletion_Trigger_TESTTABLE2
AFTER DELETE
ON TESTTABLE2 FOR EACH ROW
DECLARE
    log_id NUMBER;
BEGIN
    SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM LOGGINGFORTESTTABLE2;

    INSERT INTO LOGGINGFORTESTTABLE2 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_DATETIME, OLD_DATETIME)
    VALUES (log_id, 'DELETE', CURRENT_TIMESTAMP, NULL, :OLD.ID, NULL, :OLD.NAME, NULL, :OLD.DATETIME);
END;
/

CREATE OR REPLACE TRIGGER Trigger_TESTTABLE3
    BEFORE INSERT OR UPDATE OR DELETE
    ON TESTTABLE3 FOR EACH ROW
    DECLARE
        log_id NUMBER;
    BEGIN
        SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM LOGGINGFORTESTTABLE3;

        IF INSERTING THEN
            INSERT INTO LOGGINGFORTESTTABLE3 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_FK_ID, OLD_FK_ID)
            VALUES (log_id, 'INSERT', CURRENT_TIMESTAMP, :NEW.ID, NULL, :NEW.NAME, NULL, :NEW.FK_ID, NULL);
        ELSIF UPDATING THEN
            INSERT INTO LOGGINGFORTESTTABLE3 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_FK_ID, OLD_FK_ID)
            VALUES (log_id, 'UPDATE', CURRENT_TIMESTAMP, :NEW.ID, :OLD.ID, :NEW.NAME, :OLD.NAME, :NEW.FK_ID, :OLD.FK_ID);
        END IF;
    END;
/

CREATE OR REPLACE TRIGGER Deletion_Trigger_TESTTABLE3
    AFTER DELETE
    ON TESTTABLE3 FOR EACH ROW
    DECLARE
        log_id NUMBER;
    BEGIN
        SELECT NVL(MAX(ID), 0) + 1 INTO log_id FROM LOGGINGFORTESTTABLE3;

        INSERT INTO LOGGINGFORTESTTABLE3 (ID, OPERATION, DATETIME, NEW_ID, OLD_ID, NEW_NAME, OLD_NAME, NEW_FK_ID, OLD_FK_ID)
        VALUES (log_id, 'DELETE', CURRENT_TIMESTAMP, NULL, :OLD.ID, NULL, :OLD.NAME, NULL, :OLD.FK_ID);
    END;
/

CREATE OR REPLACE PROCEDURE GenerateLoggingTable(p_table_name VARCHAR2) AS
    v_logging_table_name VARCHAR2(100);
    v_column_list VARCHAR2(1000);
BEGIN
    -- Determine the logging table name based on the existing table name
    v_logging_table_name := 'LoggingFor' || p_table_name;

    -- Build column list for logging table
    v_column_list := '
id NUMBER PRIMARY KEY,
operation VARCHAR2(50) NOT NULL,
datetime TIMESTAMP NOT NULL,' || CHR(10);

    -- Add columns from the existing table to the column list
    FOR column_info IN (
        SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH
        FROM USER_TAB_COLUMNS
        WHERE TABLE_NAME = p_table_name
    ) LOOP
            v_column_list := v_column_list
                            || 'new_' || column_info.COLUMN_NAME || ' ' || column_info.DATA_TYPE ||
                             CASE
                                WHEN column_info.DATA_TYPE = 'VARCHAR2' THEN '(' || column_info.DATA_LENGTH || ')'
                                ELSE NULL
                             END || ',' || CHR(10)
                            || 'old_' || column_info.COLUMN_NAME || ' ' || column_info.DATA_TYPE ||
                             CASE
                                WHEN column_info.DATA_TYPE = 'VARCHAR2' THEN '(' || column_info.DATA_LENGTH || ')'
                                ELSE NULL
                             END || ',' || CHR(10);
    END LOOP;
    v_column_list := SUBSTR(v_column_list, 1, LENGTH(v_column_list) - 2) || CHR(10);

    -- Create logging table dynamically
    EXECUTE IMMEDIATE 'CREATE TABLE ' || v_logging_table_name || ' (' || v_column_list || ')';
END;
/


