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
    FOR rec IN (SELECT id, val FROM MyTable) LOOP
        v_id := rec.id;
        v_val := rec.val;
        
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', VAL: ' || v_val);
    END LOOP;
END;
/

-- Task 3
