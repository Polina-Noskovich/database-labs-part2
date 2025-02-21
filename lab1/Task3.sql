-- Task 3: ������� ��� ��������� ������ � �������� ��������
CREATE OR REPLACE FUNCTION compare_even_odd
RETURN VARCHAR2
IS
    even_count NUMBER;
    odd_count  NUMBER;
BEGIN
    -- ������� ���������� ������ ��������
    SELECT COUNT(*)
    INTO even_count
    FROM MyTable
    WHERE MOD(val, 2) = 0;
    
    -- ������� ���������� �������� ��������
    SELECT COUNT(*)
    INTO odd_count
    FROM MyTable
    WHERE MOD(val, 2) <> 0;
    
    -- ���������� ���������� � ���������� ���������
    IF even_count > odd_count THEN
        RETURN 'TRUE';
    ELSIF odd_count > even_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- ���� ��������� ������, ������� ��������� � ���������� ����� ������
        RETURN 'ERROR: ' || SQLERRM;
END;
/

SELECT compare_even_odd FROM dual;
  

