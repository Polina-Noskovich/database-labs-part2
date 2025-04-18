-- for testing

ALTER SESSION SET CURRENT_SCHEMA = test_user;
GRANT CREATE TRIGGER TO test_user;

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