-- Task 5
-- DML операции (INSERT, UPDATE, DELETE)

-- 1. Процедура для вставки новой строки
CREATE OR REPLACE PROCEDURE insert_record(p_val IN NUMBER) 
IS
    v_id NUMBER;
BEGIN
    -- Получаем максимальный ID из таблицы
    SELECT NVL(MAX(id), 0) + 1 INTO v_id FROM MyTable;

    -- Вставляем новую строку
    INSERT INTO MyTable (id, val) 
    VALUES (v_id, p_val);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Запись успешно вставлена: ID = ' || v_id || ', VAL = ' || p_val);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка при вставке: ' || SQLERRM);
END;
/

-- 2. Процедура для обновления существующей записи
CREATE OR REPLACE PROCEDURE update_record(p_id IN NUMBER, p_new_val IN NUMBER) 
IS
BEGIN
    UPDATE MyTable
    SET val = p_new_val
    WHERE id = p_id;

    -- Проверяем, была ли затронута хотя бы одна строка
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Запись с ID = ' || p_id || ' не найдена.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Запись успешно обновлена: ID = ' || p_id || ', Новый VAL = ' || p_new_val);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка при обновлении: ' || SQLERRM);
END;
/

-- 3. Процедура для удаления записи
CREATE OR REPLACE PROCEDURE delete_record(p_id IN NUMBER) 
IS
BEGIN
    DELETE FROM MyTable
    WHERE id = p_id;

    -- Проверяем, была ли затронута хотя бы одна строка
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Запись с ID = ' || p_id || ' не найдена.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Запись успешно удалена: ID = ' || p_id);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка при удалении: ' || SQLERRM);
END;
/

-- Пример вызова процедур:

EXEC insert_record(500);

EXEC update_record(600,50);

EXEC delete_record(10001);
/