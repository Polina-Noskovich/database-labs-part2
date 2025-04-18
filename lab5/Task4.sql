-- 4

ALTER SESSION SET CURRENT_SCHEMA = test_user;
GRANT CREATE TRIGGER TO test_user;

CREATE OR REPLACE DIRECTORY my_directory AS '/opt/oracle';
GRANT READ, WRITE ON DIRECTORY my_directory TO PUBLIC;

CREATE OR REPLACE PACKAGE create_report_package AS
    FUNCTION create_report(title VARCHAR2, insert_count1  NUMBER, update_count1  NUMBER, delete_count1  NUMBER,
     insert_count2  NUMBER, update_count2  NUMBER, delete_count2  NUMBER,
     insert_count3  NUMBER, update_count3  NUMBER, delete_count3  NUMBER) RETURN VARCHAR2;
    PROCEDURE create_report_for_TestTable(p_datetime TIMESTAMP);
    PROCEDURE create_report_for_TestTable;
END create_report_package;
/

CREATE OR REPLACE PACKAGE BODY create_report_package AS
    FUNCTION create_report (title IN VARCHAR2,
     insert_count1 IN NUMBER, update_count1 IN NUMBER, delete_count1 IN NUMBER,
     insert_count2 IN NUMBER, update_count2 IN NUMBER, delete_count2 IN NUMBER,
     insert_count3 IN NUMBER, update_count3 IN NUMBER, delete_count3 IN NUMBER)
    RETURN VARCHAR2 IS
        result VARCHAR(4000);
    BEGIN
        result :=  '<!DOCTYPE html>
                    <html lang="en">
                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Report</title>
                        <style>
                            body {
                                font-family: Arial, sans-serif; /* Updated font */
                            }
                            table {
                                border-collapse: separate;
                                border-spacing: 0;
                                width: 100%; /* Full width */
                                margin: 20px 0;
                                border-radius: 10px;
                                overflow: hidden; /* Helps in applying border-radius */
                            }
                            th, td {
                                border-right: 1px solid #dddddd; /* Lighter border color */
                                padding: 12px 15px; /* Increased padding */
                                text-align: left;
                            }
                            th:last-child, td:last-child {
                                border-right: none;
                            }
                            th {
                                background-color: #4CAF50; /* Dark green header */
                                color: white;
                            }
                            tr:nth-child(even) {
                                background-color: #f9f9f9; /* Zebra striping for rows */
                            }
                            tr:hover {
                                background-color: #f1f1f1; /* Hover effect */
                            }
                        </style>
                    </head>
                    <body>
                    <h2>' || title || '</h2>
                    <table>
                        <tr>
                            <th>Operation</th>
                            <th>Count</th>
                        </tr>
                        <tr>
                            <td>INSERTs count into tab1</td>
                            <td>' || insert_count1 || '</td>
                        </tr>
                        <tr>
                            <td>UPDATEs count into tab1</td>
                            <td>' || update_count1 || '</td>
                        </tr>
                        <tr>
                            <td>DELETEs count into tab1</td>
                            <td>' || delete_count1 || '</td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                        </tr>
                        <tr>
                            <td>INSERTs count into tab2</td>
                            <td>' || insert_count2 || '</td>
                        </tr>
                        <tr>
                            <td>UPDATEs count into tab2</td>
                            <td>' || update_count2 || '</td>
                        </tr>
                        <tr>
                            <td>DELETEs count into tab2</td>
                            <td>' || delete_count2 || '</td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                        </tr>
                        <tr>
                            <td>INSERTs count into tab3</td>
                            <td>' || insert_count3 || '</td>
                        </tr>
                        <tr>
                            <td>UPDATEs count into tab3</td>
                            <td>' || update_count3 || '</td>
                        </tr>
                        <tr>
                            <td>DELETEs count into tab3</td>
                            <td>' || delete_count3 || '</td>
                        </tr>
                    </table>
                    </body>
                    </html>';

        DBMS_OUTPUT.PUT_LINE(result);
        RETURN result;
    END create_report;


    PROCEDURE create_report_for_TestTable(p_datetime TIMESTAMP) AS
        v_file_handle UTL_FILE.FILE_TYPE;
        report VARCHAR2(4000);
        title VARCHAR2(100);
        insert_count1 NUMBER;
        update_count1 NUMBER;
        delete_count1 NUMBER;
        insert_count2 NUMBER;
        update_count2 NUMBER;
        delete_count2 NUMBER;
        insert_count3 NUMBER;
        update_count3 NUMBER;
        delete_count3 NUMBER;
        result VARCHAR(4000);
    BEGIN
        title := 'Since ' || p_datetime;
        SELECT COUNT(*) INTO insert_count1 FROM LoggingForTestTable1 WHERE operation = 'INSERT' AND p_datetime <= datetime;
        SELECT COUNT(*) INTO update_count1 FROM LoggingForTestTable1 WHERE operation = 'UPDATE' AND p_datetime <= datetime;
        SELECT COUNT(*) INTO delete_count1 FROM LoggingForTestTable1 WHERE operation = 'DELETE' AND p_datetime <= datetime;

        SELECT COUNT(*) INTO insert_count2 FROM LoggingForTestTable2 WHERE operation = 'INSERT' AND p_datetime <= datetime;
        SELECT COUNT(*) INTO update_count2 FROM LoggingForTestTable2 WHERE operation = 'UPDATE' AND p_datetime <= datetime;
        SELECT COUNT(*) INTO delete_count2 FROM LoggingForTestTable2 WHERE operation = 'DELETE' AND p_datetime <= datetime;

        SELECT COUNT(*) INTO insert_count3 FROM LoggingForTestTable3 WHERE operation = 'INSERT' AND p_datetime <= datetime;
        SELECT COUNT(*) INTO update_count3 FROM LoggingForTestTable3 WHERE operation = 'UPDATE' AND p_datetime <= datetime;
        SELECT COUNT(*) INTO delete_count3 FROM LoggingForTestTable3 WHERE operation = 'DELETE' AND p_datetime <= datetime;

        result := create_report(title, insert_count1, update_count1, delete_count1, insert_count2, update_count2, delete_count2, insert_count3, update_count3, delete_count3);

        v_file_handle := UTL_FILE.FOPEN('MY_DIRECTORY', 'report.html', 'W');
        UTL_FILE.PUT_LINE(v_file_handle, result);
        UTL_FILE.FCLOSE(v_file_handle);

        UPDATE LastReport SET datetime = CURRENT_TIMESTAMP WHERE ROWNUM = 1;
    END create_report_for_TestTable;

    PROCEDURE create_report_for_TestTable AS
        v_time TIMESTAMP;
    BEGIN
        SELECT datetime INTO v_time FROM LastReport WHERE ROWNUM = 1;

        -- Если таблица со временем пустая, то берем минимальное из нынешних логов
        IF v_time IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('If');
            SELECT MIN(datetime) INTO v_time FROM (
                SELECT datetime  FROM LOGGINGFORTESTTABLE1
                UNION ALL
                SELECT datetime  FROM LOGGINGFORTESTTABLE2
                UNION ALL
                SELECT datetime FROM LOGGINGFORTESTTABLE3);
        END IF;

        create_report_for_TestTable(v_time);
    END create_report_for_TestTable;
END create_report_package;
/


-- for testing
INSERT INTO TestTable1 VALUES(1, 'first table 1', 10);
INSERT INTO TestTable1 VALUES(2, 'first table 2', 11);
INSERT INTO TestTable1 VALUES(3, 'first table 3', 12);

INSERT INTO TestTable2 VALUES(1, 'second table 1', '11.11.11');
INSERT INTO TestTable2 VALUES(2, 'second table 2', '11.09.01');
INSERT INTO TestTable2 VALUES(3, 'second table 3', '12.02.02');

INSERT INTO TestTable3 VALUES(1, 'third table 1', 1);
INSERT INTO TestTable3 VALUES(2, 'third table 2', 1);
INSERT INTO TestTable3 VALUES(3, 'third table 3', 1);

UPDATE TestTable1 SET value = 20 WHERE Id = 2;

UPDATE TestTable2 SET name = 'second table second row new' WHERE Id = 2;

UPDATE TestTable3 SET name = 'third table second row new' WHERE Id = 2;


DELETE FROM TestTable2 WHERE Id = 3;

DELETE FROM TestTable1 WHERE Id = 1;

DELETE FROM TestTable3 WHERE Id = 1;

DELETE FROM TestTable2 WHERE Id = 1;

BEGIN
    --recovery_package.Tables_recovery(5);
    recovery_package.Tables_recovery(TO_TIMESTAMP('09.05.24 13:42:49'));
END;
/

begin
create_report_package.create_report_for_TestTable();
end;


drop table TablesLog;
drop table TestTable1;
drop table TestTable3;
drop table TestTable2;
drop table LastReport;
drop table LOGGINGFORTESTTABLE1;
drop table LOGGINGFORTESTTABLE2;
drop table LOGGINGFORTESTTABLE3;

