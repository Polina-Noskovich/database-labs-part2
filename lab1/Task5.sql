-- Task 5
-- DML �������� (INSERT, UPDATE, DELETE)

-- 1. ��������� ��� ������� ����� ������
CREATE OR REPLACE PROCEDURE insert_record(p_val IN NUMBER) 
IS
    v_id NUMBER;
BEGIN
    -- �������� ������������ ID �� �������
    SELECT NVL(MAX(id), 0) + 1 INTO v_id FROM MyTable;

    -- ��������� ����� ������
    INSERT INTO MyTable (id, val) 
    VALUES (v_id, p_val);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('������ ������� ���������: ID = ' || v_id || ', VAL = ' || p_val);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������ ��� �������: ' || SQLERRM);
END;
/

-- 2. ��������� ��� ���������� ������������ ������
CREATE OR REPLACE PROCEDURE update_record(p_id IN NUMBER, p_new_val IN NUMBER) 
IS
BEGIN
    UPDATE MyTable
    SET val = p_new_val
    WHERE id = p_id;

    -- ���������, ���� �� ��������� ���� �� ���� ������
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('������ � ID = ' || p_id || ' �� �������.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('������ ������� ���������: ID = ' || p_id || ', ����� VAL = ' || p_new_val);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������ ��� ����������: ' || SQLERRM);
END;
/

-- 3. ��������� ��� �������� ������
CREATE OR REPLACE PROCEDURE delete_record(p_id IN NUMBER) 
IS
BEGIN
    DELETE FROM MyTable
    WHERE id = p_id;

    -- ���������, ���� �� ��������� ���� �� ���� ������
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('������ � ID = ' || p_id || ' �� �������.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('������ ������� �������: ID = ' || p_id);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������ ��� ��������: ' || SQLERRM);
END;
/

-- ������ ������ ��������:

EXEC insert_record(500);

EXEC update_record(600,50);

EXEC delete_record(10001);
/