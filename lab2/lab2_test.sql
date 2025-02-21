ALTER USER polina QUOTA UNLIMITED ON SYSTEM;

ALTER TRIGGER POLINA.STUDENT_ID_AUTOINC COMPILE;

SELECT * FROM students;

SELECT * FROM groups;

INSERT INTO groups (group_name, c_val) VALUES ('Group F', 0);
INSERT INTO groups (group_name, c_val) VALUES ('Group A', 0);

INSERT INTO groups (group_name, c_val) VALUES ('GROUP K',2);

INSERT INTO students (student_name, gr_id) VALUES ('St1', 3);
INSERT INTO students (student_name, gr_id) VALUES ('St2', 3);
INSERT INTO students (student_name, gr_id) VALUES ('Vlad', 64);

DELETE FROM groups
WHERE id=3;

-- �������� ��������� STUDENTS_LOG ����� ��������������
SELECT * FROM students_log  ORDER BY action_date ASC;

DECLARE 
    test_time TIMESTAMP;
BEGIN
    SELECT TO_TIMESTAMP('2025-02-21 10:23:49', 'YYYY-MM-DD HH24:MI:SS') INTO test_time FROM dual;
    restore_students_state(test_time, INTERVAL '1' MINUTE);
END;


DECLARE 
    test_time TIMESTAMP;
BEGIN
    SELECT TO_TIMESTAMP('2025-02-21 09:38:08', 'YYYY-MM-DD HH24:MI:SS') INTO test_time FROM dual;
    restore_students_state(test_time);
END;


-- ��������� ��������� � ������� students
INSERT INTO students (student_name, gr_id) VALUES ('Student 11', 61);
INSERT INTO students (student_name, gr_id) VALUES ('Student 21', 61);

SELECT TRIGGER_NAME, TABLE_NAME, STATUS
FROM USER_TRIGGERS
WHERE TABLE_NAME IN ('GROUPS', 'STUDENTS', 'STUDENTS_LOG');

-- �������� ������ � ������� students
SELECT * FROM students;

-- �������� ������ � ������� groups
SELECT * FROM groups;

-- �������� ������ � id = 1
DELETE FROM groups
WHERE id = 61;


SELECT * FROM students;

SELECT * FROM groups;


-- ������� ������ � ������� GROUPS
INSERT INTO groups (group_name, c_val) VALUES ('Group A', 0);
INSERT INTO groups (group_name, c_val) VALUES ('Group B', 0);
INSERT INTO groups (group_name, c_val) VALUES ('Group C', 0);

-- �������� AUTOINCREMENT ��� GROUPS
SELECT * FROM groups;

-- ������� ������ � ������� STUDENTS
INSERT INTO students (student_name, gr_id) VALUES ('Student 1', 1);
INSERT INTO students (student_name, gr_id) VALUES ('Student 2', 1);
INSERT INTO students (student_name, gr_id) VALUES ('Student 3', 2);

SELECT TRIGGER_NAME, TABLE_NAME, STATUS
FROM USER_TRIGGERS
WHERE TABLE_NAME IN ('GROUPS', 'STUDENTS', 'STUDENTS_LOG');


-- �������� AUTOINCREMENT ��� STUDENTS
SELECT * FROM students;

-- �������� ���������� C_VAL � ������� GROUPS
SELECT * FROM groups;

-- ���������� STUDENTS (����������� �������� � ������ ������)
UPDATE students SET gr_id = 2 WHERE student_id = 1;

-- �������� C_VAL � GROUPS ����� ����������
SELECT * FROM groups;

-- �������� �������� � �������� C_VAL
DELETE FROM students WHERE student_id = 3;

-- �������� C_VAL � GROUPS ����� �������� ��������
SELECT * FROM groups;

-- �������� ���� STUDENTS_LOG
SELECT * FROM students_log  ORDER BY action_date ASC;

-- �������� ������ CASCADE DELETE (�������� ������)
DELETE FROM groups WHERE id = 2;

-- �������� ������� STUDENTS ����� ���������� ��������
SELECT * FROM students;

-- �������� ������� STUDENTS_LOG ����� ���������� ��������
SELECT * FROM students_log  ORDER BY action_date ASC;

-- �������� ��������� �������������� ���������
-- ������� ������� ����� ������
INSERT INTO students (student_name, gr_id) VALUES ('Student 4', 1);
INSERT INTO students (student_name, gr_id) VALUES ('Student 5', 3);

-- �������� ������� ���������
SELECT * FROM students;

-- ����� ��������� �������������� ���������
DECLARE
    test_time TIMESTAMP;
BEGIN
    -- ������������� ����� �������������� �� ������ ����� �������������� ������
    SELECT TO_TIMESTAMP('2025-02-21 09:02:06', 'YYYY-MM-DD HH24:MI:SS') INTO test_time FROM dual;
    restore_students_state(test_time, INTERVAL '5' MINUTE);
END;

-- �������� ��������� ������� STUDENTS ����� ��������������
SELECT * FROM students;

-- �������� ��������� STUDENTS_LOG ����� ��������������
SELECT * FROM students_log  ORDER BY action_date ASC;

-- �������� ������������ GROUP_NAME (������ ������� ������)
BEGIN
    INSERT INTO groups (group_name, c_val) VALUES ('Group A', 0); -- ������
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('������: ' || sqlerrm);
END;

-- �������� ������������ STUDENT_ID (������ ������� ������)
BEGIN
    INSERT INTO students (student_id, student_name, gr_id) VALUES (1, 'Duplicate Student', 1); -- ������
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('������: ' || sqlerrm);
END;
