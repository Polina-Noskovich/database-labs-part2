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

SELECT compare_even_odd FROM dual;
  

