-- Task 6
CREATE OR REPLACE FUNCTION calculate_yearly_reward(p_monthly_salary IN NUMBER, p_annual_bonus_percent IN NUMBER)
RETURN NUMBER
IS
    v_yearly_reward NUMBER;
BEGIN
    -- Проверка на корректность данных (зарплата и процент должны быть положительными числами и процент не должен быть больше 100)
    IF p_monthly_salary < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Месячная зарплата не может быть отрицательной.');
        RETURN -1; -- Возвращаем ошибку
    ELSIF p_annual_bonus_percent < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Процент премиальных не может быть отрицательным.');
        RETURN -1; -- Возвращаем ошибку
    ELSIF p_annual_bonus_percent > 100 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Процент премиальных не может быть больше 100.');
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
SELECT calculate_yearly_reward(null,null) FROM dual;