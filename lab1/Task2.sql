-- Task 2: Вставка случайных данных в таблицу MyTable
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO MyTable (id, val)
        VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 10)));
    END LOOP;
    COMMIT;
END;
/

SELECT * FROM MyTable;



