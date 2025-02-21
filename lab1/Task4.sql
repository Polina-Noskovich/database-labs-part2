-- Task 4: Функция для генерации команды INSERT по введенному ID с проверкой на отрицательное значение ID
CREATE OR REPLACE FUNCTION generate_insert_command(p_id IN NUMBER)
RETURN VARCHAR2
IS
    v_id MyTable.id%TYPE;
    v_val MyTable.val%TYPE;
    v_insert_command VARCHAR2(4000);
BEGIN
    -- Проверка на отрицательное значение ID
    IF p_id < 0 THEN
        RETURN 'ERROR: ID не может быть отрицательным.';
    END IF;

    -- Получаем данные по указанному ID
    SELECT id, val
    INTO v_id, v_val
    FROM MyTable
    WHERE id = p_id;

    -- Формируем строку команды INSERT
    v_insert_command := 'INSERT INTO MyTable (id, val) VALUES (' || v_id || ', ' || v_val || ');';
    
    -- Выводим сгенерированную команду
    DBMS_OUTPUT.PUT_LINE(v_insert_command);

    -- Возвращаем строку команды INSERT
    RETURN v_insert_command;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Нет данных с таким ID: ' || p_id);
        RETURN 'ERROR: No data found for ID ' || p_id;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
        RETURN 'ERROR: ' || SQLERRM;
END;
/
-- Запрашиваем значение ID от пользователя
ACCEPT p_id CHAR PROMPT 'Введите ID: ';
SELECT generate_insert_command(&p_id) FROM dual;
