SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Task 2: Вставка случайных данных в таблицу MyTable
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

-- Task 3: Функция для сравнения четных и нечетных значений
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

-- Task 4: Функция для генерации команды INSERT по введенному ID
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

-- Task 5
-- DML операции (INSERT, UPDATE, DELETE)

-- 1. Процедура для вставки новой строки
CREATE OR REPLACE PROCEDURE insert_record(p_id IN NUMBER, p_val IN NUMBER) 
IS
BEGIN
    INSERT INTO MyTable (id, val) 
    VALUES (p_id, p_val);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Запись успешно вставлена: ID = ' || p_id || ', VAL = ' || p_val);
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

-- Вставка записи с ID = 10001 и значением VAL = 500
EXEC insert_record(10001, 500);

-- Обновление записи с ID = 10001, новый VAL = 600
EXEC update_record(10001, 600);

-- Удаление записи с ID = 10001
EXEC delete_record(10001);
/

-- Task 6
CREATE OR REPLACE FUNCTION calculate_yearly_reward(p_monthly_salary IN NUMBER, p_annual_bonus_percent IN NUMBER)
RETURN NUMBER
IS
    v_yearly_reward NUMBER;
BEGIN
    -- Проверка на корректность данных
    IF p_monthly_salary < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Месячная зарплата не может быть отрицательной.');
        RETURN -1; -- Возвращаем ошибку
    ELSIF p_annual_bonus_percent < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Процент премиальных не может быть отрицательным.');
        RETURN -1; -- Возвращаем ошибку
    END IF;

    -- Преобразуем процент в дробную форму
    v_yearly_reward := (1 + p_annual_bonus_percent / 100) * 12 * p_monthly_salary;

    -- Выводим рассчитанное вознаграждение
    DBMS_OUTPUT.PUT_LINE('Общее вознаграждение за год: ' || v_yearly_reward);
    
    RETURN v_yearly_reward;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
        RETURN -1; -- Возвращаем ошибку
END;
/

-- Пример вызова функции для вычисления вознаграждения:
DECLARE
    v_monthly_salary NUMBER := &p_monthly_salary; -- Месячная зарплата
    v_annual_bonus_percent NUMBER := &p_annual_bonus_percent; -- Процент премиальных
    v_yearly_reward NUMBER;
BEGIN
    v_yearly_reward := calculate_yearly_reward(v_monthly_salary, v_annual_bonus_percent);
    IF v_yearly_reward >= 0 THEN
        DBMS_OUTPUT.PUT_LINE('Рассчитанное общее вознаграждение: ' || v_yearly_reward);
    END IF;
END;
/