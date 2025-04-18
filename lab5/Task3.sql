-- 3

ALTER SESSION SET CURRENT_SCHEMA = test_user;
GRANT CREATE TRIGGER TO test_user;

CREATE OR REPLACE PACKAGE recovery_package AS
    PROCEDURE Tables_recovery(p_datetime TIMESTAMP);
    PROCEDURE Tables_recovery(p_seconds INT);
END recovery_package;
/

CREATE OR REPLACE PACKAGE BODY recovery_package AS

    PROCEDURE Tables_recovery(p_datetime TIMESTAMP) AS
        Table1Record LoggingForTESTTABLE1%ROWTYPE;
        Table2Record LoggingForTESTTABLE2%ROWTYPE;
        Table3Record LoggingForTESTTABLE3%ROWTYPE;
    BEGIN
        FOR action IN (SELECT * FROM TablesLog WHERE p_datetime < operation_time ORDER BY id DESC)
        LOOP
            -- Если действие для первой таблицы
            IF action.table_number = 1 THEN
                SELECT * INTO Table1Record FROM LoggingForTESTTABLE1 WHERE id = action.table_id;

                IF Table1Record.operation = 'INSERT' THEN
                    DELETE FROM TestTable1 WHERE id = Table1Record.new_ID;
                END IF;

                IF Table1Record.operation = 'UPDATE' THEN
                    UPDATE TestTable1 SET
                        id = Table1Record.old_ID,
                        name = Table1Record.old_NAME,
                        value = Table1Record.old_VALUE
                    WHERE id = Table1Record.new_ID;
                END IF;

                IF Table1Record.operation = 'DELETE' THEN
                    INSERT INTO TestTable1 VALUES (Table1Record.old_ID, Table1Record.old_NAME, Table1Record.old_VALUE);
                END IF;

            -- Если действие для второй таблицы
            ELSIF action.table_number = 2 THEN
                SELECT * INTO Table2Record FROM LoggingForTESTTABLE2 WHERE id = action.table_id;

                IF Table2Record.operation = 'INSERT' THEN
                    DELETE FROM TestTable2 WHERE id = Table2Record.new_ID;
                END IF;

                IF Table2Record.operation = 'UPDATE' THEN
                    UPDATE TestTable2 SET
                        id = Table2Record.old_ID,
                        name = Table2Record.old_NAME,
                        datetime = Table2Record.old_DATETIME
                    WHERE id = Table2Record.new_ID;
                END IF;

                IF Table2Record.operation = 'DELETE' THEN
                    INSERT INTO TestTable2 VALUES (Table2Record.old_ID, Table2Record.old_NAME, Table2Record.old_DATETIME);
                END IF;

            -- Если действие для третьей таблицы
            ELSIF action.table_number = 3 THEN
                SELECT * INTO Table3Record FROM LoggingForTESTTABLE3 WHERE id = action.table_id;

                IF Table3Record.operation = 'INSERT' THEN
                    DELETE FROM TestTable3 WHERE id = Table3Record.new_ID;
                END IF;

                IF Table3Record.operation = 'UPDATE' THEN
                    UPDATE TestTable3 SET
                        id = Table3Record.old_ID,
                        name = Table3Record.old_NAME,
                        fk_id = Table3Record.old_FK_ID
                    WHERE id = Table3Record.new_ID;
                END IF;

                IF Table3Record.operation = 'DELETE' THEN
                    INSERT INTO TestTable3 VALUES (Table3Record.old_ID, Table3Record.old_NAME, Table3Record.old_FK_ID);
                END IF;
            END IF;
        END LOOP;

        DELETE FROM LoggingForTESTTABLE1 WHERE datetime > p_datetime;
        DELETE FROM LoggingForTESTTABLE2 WHERE datetime > p_datetime;
        DELETE FROM LoggingForTESTTABLE3 WHERE datetime > p_datetime;
    END Tables_recovery;

    PROCEDURE Tables_recovery(p_seconds INT) AS
    BEGIN
        Tables_recovery(CURRENT_TIMESTAMP - INTERVAL '1' SECOND * p_seconds);
    END Tables_recovery;

END recovery_package;
/

