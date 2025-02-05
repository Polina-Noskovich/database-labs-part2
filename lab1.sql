SET SERVEROUTPUT ON SIZE UNLIMITED;
-- Task 2
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO MyTable (id, val)
        VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 1000)));
    END LOOP;
    COMMIT;
END;
/

DECLARE
    v_id MyTable.id%TYPE;
    v_val MyTable.val%TYPE;
BEGIN
    FOR rec IN (SELECT id, val FROM MyTable WHERE ROWNUM <= 100) LOOP
        v_id := rec.id;
        v_val := rec.val;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', VAL: ' || v_val);
    END LOOP;
END;
/

-- Task 3
CREATE OR REPLACE FUNCTION compare_even_odd
RETURN VARCHAR2
IS
    even_count NUMBER;
    odd_count  NUMBER;
BEGIN
    -- Считаем количество четных значений
    SELECT COUNT(*)
    INTO even_count
    FROM MyTable
    WHERE MOD(val, 2) = 0;
    
    -- Считаем количество нечетных значений
    SELECT COUNT(*)
    INTO odd_count
    FROM MyTable
    WHERE MOD(val, 2) <> 0;
    
    -- Сравниваем количества и возвращаем результат
    IF even_count > odd_count THEN
        RETURN 'TRUE';
    ELSIF odd_count > even_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Если произошла ошибка, выводим сообщение и возвращаем текст ошибки
        RETURN 'ERROR: ' || SQLERRM;
END;
/

DECLARE
    result VARCHAR2(10);
BEGIN
    result := compare_even_odd;
    DBMS_OUTPUT.PUT_LINE('Результат сравнения: ' || result);
END;
/

-- SELECT * FROM MyTable WHERE ROWNUM <= 10;

-- Task 4
CREATE OR REPLACE FUNCTION generate_insert_command(p_id IN NUMBER)
RETURN VARCHAR2
IS
    v_id MyTable.id%TYPE;
    v_val MyTable.val%TYPE;
    v_insert_command VARCHAR2(4000);
BEGIN
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
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Запрашиваем значение ID от пользователя
ACCEPT p_id CHAR PROMPT 'Введите ID: ';

-- Вызов функции с введенным значением ID
DECLARE
    v_command VARCHAR2(4000);
BEGIN
    -- Читаем значение переменной p_id, введенное пользователем
    v_command := generate_insert_command(&p_id); -- Подставляется введенное значение
    DBMS_OUTPUT.PUT_LINE('Сгенерированная команда: ' || v_command);
END;
/

