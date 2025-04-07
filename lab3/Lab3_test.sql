CREATE USER admin_schema IDENTIFIED BY admin_password;
GRANT CONNECT, RESOURCE TO admin_schema;
GRANT SELECT ANY DICTIONARY TO admin_schema;
GRANT ALL PRIVILEGES TO ADMIN_SCHEMA;
SET SERVEROUTPUT ON;

SELECT owner, object_name, object_type, status 
FROM all_objects 
WHERE object_name = 'COMPARE_SCHEMES';

ALTER SESSION SET CURRENT_SCHEMA = admin_schema;

SET SERVEROUTPUT ON;
BEGIN
    compare_schemes('DEV_SCHEMA','PROD_SCHEMA');
END;
/


DROP TABLE DEV_USER.MY_TABLE;

CREATE USER dev_schema IDENTIFIED BY dev_password;
CREATE USER prod_schema IDENTIFIED BY prod_password;
GRANT CONNECT, RESOURCE TO dev_schema, prod_schema;

ALTER SESSION SET CURRENT_SCHEMA = dev_schema;
ALTER SESSION SET CURRENT_SCHEMA = prod_schema;

CREATE TABLE my_table (
    id NUMBER,
    name NUMBER
);

CREATE TABLE test_table (
    id NUMBER,
    name VARCHAR2(200)
    );

DROP TABLE my_table;

CREATE TABLE dev_table1 (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    t3_id NUMBER
);

CREATE TABLE dev_table2 (
    id NUMBER PRIMARY KEY,
    description VARCHAR2(200)
);

CREATE TABLE dev_table3 (
    id NUMBER PRIMARY KEY,
    description VARCHAR2(200),
    t2_id NUMBER
);

ALTER TABLE dev_table1 ADD CONSTRAINT FK_13 FOREIGN KEY (t3_id) REFERENCES dev_table3(id);
ALTER TABLE dev_table3 ADD CONSTRAINT FK_32 FOREIGN KEY (t2_id) REFERENCES dev_table2(id);


ALTER TABLE DEV_SCHEMA.GRANDCHILD_TABLE ADD CONSTRAINT FK_GRANDCHILD FOREIGN KEY (CHILD_ID) REFERENCES DEV_SCHEMA.CHILD_TABLE(ID);

CREATE TABLE dev_a (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    b_id NUMBER
);

CREATE TABLE dev_b (
    id NUMBER PRIMARY KEY,
    description VARCHAR2(200),
    a_id NUMBER
);

ALTER TABLE dev_a ADD CONSTRAINT FK_ab FOREIGN KEY (b_id) REFERENCES dev_b(id);
ALTER TABLE dev_b ADD CONSTRAINT FK_ba FOREIGN KEY (a_id) REFERENCES dev_a(id);

CREATE OR REPLACE PROCEDURE hello_world IS 
BEGIN
    DBMS_OUTPUT.PUT_LINE('Привет, мир!');
END hello_world;


ALTER SESSION SET CURRENT_SCHEMA = prod_schema;

DROP TABLE prod_table3;

CREATE TABLE prod_table1 (
    id NUMBER,
    name VARCHAR2(100)
);
CREATE TABLE prod_table3 (
    id NUMBER,
    details VARCHAR2(200)
);
CREATE TABLE common_table (
    id NUMBER,
    name VARCHAR2(100),
    email VARCHAR2(100) 
);

