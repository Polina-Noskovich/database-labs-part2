-- Task 6
CREATE OR REPLACE FUNCTION calculate_yearly_reward(p_monthly_salary IN NUMBER, p_annual_bonus_percent IN NUMBER)
RETURN NUMBER
IS
    v_yearly_reward NUMBER;
BEGIN
    -- �������� �� ������������ ������ (�������� � ������� ������ ���� �������������� ������� � ������� �� ������ ���� ������ 100)
    IF p_monthly_salary < 0 THEN
        DBMS_OUTPUT.PUT_LINE('������: �������� �������� �� ����� ���� �������������.');
        RETURN -1; -- ���������� ������
    ELSIF p_annual_bonus_percent < 0 THEN
        DBMS_OUTPUT.PUT_LINE('������: ������� ����������� �� ����� ���� �������������.');
        RETURN -1; -- ���������� ������
    ELSIF p_annual_bonus_percent > 100 THEN
        DBMS_OUTPUT.PUT_LINE('������: ������� ����������� �� ����� ���� ������ 100.');
        RETURN -1; -- ���������� ������
    END IF;

    -- ����������� ������� � ������� �����
    v_yearly_reward := (1 + p_annual_bonus_percent / 100) * 12 * p_monthly_salary;

    -- ������� ������������ ��������������
    DBMS_OUTPUT.PUT_LINE('����� �������������� �� ���: ' || v_yearly_reward);
    
    RETURN v_yearly_reward;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������: ' || SQLERRM);
        RETURN -1; -- ���������� ������
END;
/
SELECT calculate_yearly_reward(null,null) FROM dual;