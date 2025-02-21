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

-- Проверка состояния STUDENTS_LOG после восстановления
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


-- Вставляем студентов в таблицу students
INSERT INTO students (student_name, gr_id) VALUES ('Student 11', 61);
INSERT INTO students (student_name, gr_id) VALUES ('Student 21', 61);

SELECT TRIGGER_NAME, TABLE_NAME, STATUS
FROM USER_TRIGGERS
WHERE TABLE_NAME IN ('GROUPS', 'STUDENTS', 'STUDENTS_LOG');

-- Проверка данных в таблице students
SELECT * FROM students;

-- Проверка данных в таблице groups
SELECT * FROM groups;

-- Удаление группы с id = 1
DELETE FROM groups
WHERE id = 61;


SELECT * FROM students;

SELECT * FROM groups;


-- ВСТАВКА ДАННЫХ В ТАБЛИЦУ GROUPS
INSERT INTO groups (group_name, c_val) VALUES ('Group A', 0);
INSERT INTO groups (group_name, c_val) VALUES ('Group B', 0);
INSERT INTO groups (group_name, c_val) VALUES ('Group C', 0);

-- ПРОВЕРКА AUTOINCREMENT ДЛЯ GROUPS
SELECT * FROM groups;

-- ВСТАВКА ДАННЫХ В ТАБЛИЦУ STUDENTS
INSERT INTO students (student_name, gr_id) VALUES ('Student 1', 1);
INSERT INTO students (student_name, gr_id) VALUES ('Student 2', 1);
INSERT INTO students (student_name, gr_id) VALUES ('Student 3', 2);

SELECT TRIGGER_NAME, TABLE_NAME, STATUS
FROM USER_TRIGGERS
WHERE TABLE_NAME IN ('GROUPS', 'STUDENTS', 'STUDENTS_LOG');


-- ПРОВЕРКА AUTOINCREMENT ДЛЯ STUDENTS
SELECT * FROM students;

-- ПРОВЕРКА ОБНОВЛЕНИЯ C_VAL В ТАБЛИЦЕ GROUPS
SELECT * FROM groups;

-- ОБНОВЛЕНИЕ STUDENTS (ПЕРЕМЕЩЕНИЕ СТУДЕНТА В ДРУГУЮ ГРУППУ)
UPDATE students SET gr_id = 2 WHERE student_id = 1;

-- ПРОВЕРКА C_VAL В GROUPS ПОСЛЕ ОБНОВЛЕНИЯ
SELECT * FROM groups;

-- УДАЛЕНИЕ СТУДЕНТА И ПРОВЕРКА C_VAL
DELETE FROM students WHERE student_id = 3;

-- ПРОВЕРКА C_VAL В GROUPS ПОСЛЕ УДАЛЕНИЯ СТУДЕНТА
SELECT * FROM groups;

-- ПРОВЕРКА ЛОГА STUDENTS_LOG
SELECT * FROM students_log  ORDER BY action_date ASC;

-- ПРОВЕРКА РАБОТЫ CASCADE DELETE (УДАЛЕНИЕ ГРУППЫ)
DELETE FROM groups WHERE id = 2;

-- ПРОВЕРКА ТАБЛИЦЫ STUDENTS ПОСЛЕ КАСКАДНОГО УДАЛЕНИЯ
SELECT * FROM students;

-- ПРОВЕРКА ТАБЛИЦЫ STUDENTS_LOG ПОСЛЕ КАСКАДНОГО УДАЛЕНИЯ
SELECT * FROM students_log  ORDER BY action_date ASC;

-- ПРОВЕРКА ПРОЦЕДУРЫ ВОССТАНОВЛЕНИЯ СОСТОЯНИЯ
-- Сначала добавим новые данные
INSERT INTO students (student_name, gr_id) VALUES ('Student 4', 1);
INSERT INTO students (student_name, gr_id) VALUES ('Student 5', 3);

-- Проверим текущее состояние
SELECT * FROM students;

-- Вызов процедуры восстановления состояния
DECLARE
    test_time TIMESTAMP;
BEGIN
    -- Устанавливаем время восстановления на момент после первоначальных данных
    SELECT TO_TIMESTAMP('2025-02-21 09:02:06', 'YYYY-MM-DD HH24:MI:SS') INTO test_time FROM dual;
    restore_students_state(test_time, INTERVAL '5' MINUTE);
END;

-- Проверка состояния таблицы STUDENTS после восстановления
SELECT * FROM students;

-- Проверка состояния STUDENTS_LOG после восстановления
SELECT * FROM students_log  ORDER BY action_date ASC;

-- ПРОВЕРКА УНИКАЛЬНОСТИ GROUP_NAME (должна вызвать ошибку)
BEGIN
    INSERT INTO groups (group_name, c_val) VALUES ('Group A', 0); -- Ошибка
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Ошибка: ' || sqlerrm);
END;

-- ПРОВЕРКА УНИКАЛЬНОСТИ STUDENT_ID (должна вызвать ошибку)
BEGIN
    INSERT INTO students (student_id, student_name, gr_id) VALUES (1, 'Duplicate Student', 1); -- Ошибка
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Ошибка: ' || sqlerrm);
END;
