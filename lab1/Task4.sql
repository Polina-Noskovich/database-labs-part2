-- Task 4: ������� ��� ��������� ������� INSERT �� ���������� ID � ��������� �� ������������� �������� ID
CREATE OR REPLACE FUNCTION generate_insert_command(p_id IN NUMBER)
RETURN VARCHAR2
IS
    v_id MyTable.id%TYPE;
    v_val MyTable.val%TYPE;
    v_insert_command VARCHAR2(4000);
BEGIN
    -- �������� �� ������������� �������� ID
    IF p_id < 0 THEN
        RETURN 'ERROR: ID �� ����� ���� �������������.';
    END IF;

    -- �������� ������ �� ���������� ID
    SELECT id, val
    INTO v_id, v_val
    FROM MyTable
    WHERE id = p_id;

    -- ��������� ������ ������� INSERT
    v_insert_command := 'INSERT INTO MyTable (id, val) VALUES (' || v_id || ', ' || v_val || ');';
    
    -- ������� ��������������� �������
    DBMS_OUTPUT.PUT_LINE(v_insert_command);

    -- ���������� ������ ������� INSERT
    RETURN v_insert_command;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('��� ������ � ����� ID: ' || p_id);
        RETURN 'ERROR: No data found for ID ' || p_id;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������: ' || SQLERRM);
        RETURN 'ERROR: ' || SQLERRM;
END;
/
-- ����������� �������� ID �� ������������
ACCEPT p_id CHAR PROMPT '������� ID: ';
SELECT generate_insert_command(&p_id) FROM dual;
