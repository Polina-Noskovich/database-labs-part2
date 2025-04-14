ALTER SESSION SET CURRENT_SCHEMA = MYUSER;
GRANT CREATE TABLE TO MYUSER;
GRANT CREATE TRIGGER TO MYUSER;
ALTER USER MYUSER QUOTA UNLIMITED ON SYSTEM;

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "CREATE",
        "table": "Department",
        "primary": "DeptID",
        "columns": [
            {"name": "DeptID", "datatype": "NUMBER", "constraint": "NOT NULL"},
            {"name": "DeptName", "datatype": "VARCHAR2(100)", "constraint": "NOT NULL"}
        ]
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('CREATE TABLE Department:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "CREATE",
        "table": "Person",
        "primary": "PersonID",
        "columns": [
            {"name": "PersonID", "datatype": "NUMBER", "constraint": "NOT NULL"},
            {"name": "Name", "datatype": "VARCHAR2(50)", "constraint": "NOT NULL"},
            {"name": "Age", "datatype": "NUMBER", "constraint": ""},
            {"name": "DeptID", "datatype": "NUMBER", "constraint": ""}
        ],
        "foreign": [
            {"column": "DeptID", "refcolumn": "DeptID", "reftable": "Department"}
        ]
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('CREATE TABLE Person (и триггер для автоинкремента):');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "DELETE",
        "table": "Person",
        "where": {
            "PersonID": 3
        }
    }';
    
    -- Проксифункция для логирования запроса
    DBMS_OUTPUT.PUT_LINE('JSON запрос: ' || json_data);
    
    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('DELETE Person:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "SELECT",
        "table": "Person",
        "columns": [
            "PersonID",
            "Name",
            "Age",
            "DeptID"
        ],
        "where": {
            "DeptID": 1
        }
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('SELECT Person:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "INSERT",
        "table": "Department",
        "columns": [
            "DeptName"
        ],
        "values": [
            ["HR"]
        ]
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('INSERT Department:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

CREATE SEQUENCE person_seq START WITH 1 INCREMENT BY 1 NOCACHE;

SELECT * FROM user_tables WHERE table_name = 'PERSON';

DROP TABLE Person;
SELECT USER FROM DUAL;



CREATE OR REPLACE TRIGGER trg_generate_pk_on_person
BEFORE INSERT ON Person
FOR EACH ROW
BEGIN
    IF :NEW.PersonID IS NULL THEN
        SELECT person_seq.NEXTVAL INTO :NEW.PersonID FROM dual;
    END IF;
END;
/


INSERT INTO Department (DeptID, DeptName) VALUES (1, 'Finance');
INSERT INTO Department (DeptName) VALUES ('Finance');
SELECT * FROM Department;

-- Вставка 1-й записи в таблицу Department
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "INSERT",
        "table": "Department",
        "columns": [
            "DeptName"
        ],
        "values": [
            ["Finance"]
        ]
    }';
    
    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('INSERT 1:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

-- Выборка данных из таблицы Department
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    
    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    dept_name VARCHAR2(100);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "DeptName"
        ],
        "tables": [
            "Department"
        ]
    }';

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO dept_name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Department: ' || dept_name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/



DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "SELECT",
        "table": "Person",
        "columns": [
            "PersonID",
            "Name",
            "Age",
            "DeptID"
        ],
        "where": {
            "DeptID": 1
        }
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('SELECT Person:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


-- Вставка 1-й записи
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "INSERT",
        "table": "Person",
        "columns": [
            "Name",
            "Age",
            "DeptID"
        ],
        "values": [
            ["Bob", 21, 1]
        ]
    }';
    
    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('INSERT 1:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

SELECT * FROM Person;

-- Вставка 2-й записи
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "INSERT",
        "table": "Person",
        "columns": [
            "Name",
            "Age",
            "DeptID"
        ],
        "values": [
            ["Kate", 33, 2]
        ]
    }';
    
    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('INSERT 2:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "DELETE",
        "table": "Person",
        "where": {
            "PersonID": 3
        }
    }';
    
    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('DELETE Person:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


-- Удаление всей таблицы Person
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "DROP",
        "table": "Person"
    }';
    
    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('DROP TABLE Person:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
    dept_name VARCHAR2(100);
    num_persons NUMBER;
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "D.DeptName",
            "COUNT(P.PersonID) AS NumPersons"
        ],
        "tables": [
            "Person P"
        ],
        "joins": [
            {
                "table": "Department D",
                "condition": [
                    "P.DeptID = D.DeptID"
                ]
            }
        ],
        "filters": [
            {
                "type": "WHERE",
                "operator": "AND",
                "body": [
                    "P.Age BETWEEN 25 AND 35",
                    "P.Age BETWEEN 20 AND 30"
                ]
            },
            {
                "type": "GROUP BY",
                "body": [
                    "D.DeptName"
                ]
            }
        ]
    }';

    JSON_ORM(json_data, sql_result, v_cursor);
    DBMS_OUTPUT.PUT_LINE('SELECT с JOIN, BETWEEN и GROUP BY:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    -- Если запрос SELECT, открывается курсор, из которого можно извлечь данные:
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO dept_name, num_persons;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Department: ' || dept_name || ' - Количество сотрудников: ' || num_persons);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "INSERT",
        "table": "Department",
        "columns": [
            "DeptName"
        ],
        "values": [
            ["Finance"],
            ["IT"]
        ]
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('INSERT Department:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

SELECT * FROM Person;


DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    dummy_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
        "type": "SELECT",
        "table": "Person",
        "columns": [
            "PersonID",
            "Name",
            "Age",
            "DeptID"
        ],
        "where": {
            "DeptID": 1
        }
    }';

    JSON_ORM(json_data, sql_result, dummy_cursor);
    DBMS_OUTPUT.PUT_LINE('SELECT Person:');
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
    "type": "CREATE",
    "table": "Test1",
    "columns": [
        {
            "name": "Id",
            "datatype": "INT",
            "constraint": "NOT NULL"
        },
        {
            "name": "Name",
            "datatype": "VARCHAR2(100)"
        }
    ],
    "primary": "Id"
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "CREATE",
    "table": "Test2",
    "columns": [
        {
            "name": "Id",
            "datatype": "INT",
            "constraint": "NOT NULL"
        },
        {
            "name": "Name",
            "datatype": "VARCHAR2(100)"
        },
        {
            "name": "Test1Id",
            "datatype": "INT"
        }
    ],
    "primary": "Id",
    "foreign": [
        {
            "column": "Test1Id",
            "refcolumn": "Id",
            "reftable": "Test1"
        }
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

-- INSERT PART
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN

    json_data := '{
    "type": "INSERT",
    "table": "Test1",
    "columns": [
        "Name"
    ],
    "values": [
        [
            "t1"
        ]
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    json_data := '{
    "type": "INSERT",
    "table": "Test1",
    "columns": [
        "Name1"
    ],
    "values": [
        [
            "t2"
        ]
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "INSERT",
    "table": "Test2",
    "columns": [
        "Name",
        "Test1Id"
    ],
    "values": [
        [
            "m1",
            1
        ]
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "INSERT",
    "table": "Test2",
    "columns": [
        "Name",
        "Test1Id"
    ],
    "values": [
        [
            "m2",
            2
        ]
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

-- SELECT PART 1

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);

    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    id INT;
    name VARCHAR2(50);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "Id",
            "Name"
        ],
        "tables": [
            "Test1"
        ]
    }'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO id, name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Result: ' || id || ', ' || name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);

    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    id INT;
    name VARCHAR2(50);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "Id",
            "Name"
        ],
        "tables": [
            "Test2"
        ]
    }'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO id, name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Result: ' || id || ', ' || name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

-- UPDATE PART

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "UPDATE",
    "table": "Test2",
    "set": [
        {
            "column": "Name",
            "value": "m0"
        }
    ],
    "filters": [
        {
            "type": "WHERE",
            "operator": "OR",
            "body": [
                "Id = 1",
                {
                    "type": "=",
                    "body": {
                        "value": "Id",
                        "condition": {
                            "type": "SELECT",
                            "columns": [
                                "MAX(Id)"
                            ],
                            "tables": [
                                "Test1"
                            ]
                        }
                    }
                }
            ]
        }
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/
-- SELECT PART 2

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);

    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    id INT;
    name VARCHAR2(50);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "Id",
            "Name"
        ],
        "tables": [
            "Test2"
        ]
    }'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO id, name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Result: ' || id || ', ' || name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

-- DELETE PART

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "DELETE",
    "table": "Test2",
    "filters": [
        {
            "type": "WHERE",
            "body": [
                "Name = ''m0''"
            ]
        }
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

-- SELECT PART 3

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);

    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    id INT;
    name VARCHAR2(50);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "Id",
            "Name"
        ],
        "tables": [
            "Test2"
        ]
    }'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO id, name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Result: ' || id || ', ' || name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

-- INSER PART 2

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "INSERT",
    "table": "Test2",
    "columns": [
        "Name",
        "Test1Id"
    ],
    "values": [
        [
            "m1",
            1
        ]
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "INSERT",
    "table": "Test2",
    "columns": [
        "Name",
        "Test1Id"
    ],
    "values": [
        [
            "m2",
            2
        ]
    ]
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

--SELECT PART 4

-- SMALL SELECT
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);

    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    id INT;
    name VARCHAR2(50);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "Id",
            "Name"
        ],
        "tables": [
            "Test1"
        ]
    }'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO id, name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Result: ' || id || ', ' || name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

-- HUGE SELECT
DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);

    TYPE GenericCursor IS REF CURSOR;
    v_cursor GenericCursor;
    
    id INT;
    name VARCHAR2(50);
BEGIN
    json_data := '{
        "type": "SELECT",
        "columns": [
            "Test1.Id",
            "Test2.Name"
        ],
        "tables": [
            "Test1"
        ],
        "joins": [
            {
                "table": "Test2",
                "condition": [
                    "Test1.ID = Test2.ID"
                ]
            }
        ],
        "filters": [
            {
                "type": "WHERE",
                "operator": "AND",
                "body": [
                    "Test1.ID = 1",
                    {
                        "type": "NOT IN",
                        "body": {
                            "value": 3,
                            "condition": {
                                "type": "SELECT",
                                "columns": [
                                    "ID"
                                ],
                                "tables": [
                                    "Test2"
                                ]
                            }
                        }
                    }
                ]
            }
        ]
    }'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
    
    IF v_cursor IS NOT NULL THEN
        LOOP
            FETCH v_cursor INTO id, name;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Result: ' || id || ', ' || name);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/

-- DROP PART

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "DROP",
    "table": "Test2"
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/

DECLARE
    json_data CLOB;
    sql_result VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
BEGIN
    -- JSON Object from lab4_tests.json
    json_data := '{
    "type": "DROP",
    "table": "Test1"
}'; 

    JSON_ORM(json_data, sql_result, v_cursor); 
    DBMS_OUTPUT.PUT_LINE(sql_result);
END;
/


SELECT USER FROM DUAL;
