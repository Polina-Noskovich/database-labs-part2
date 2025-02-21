

CREATE OR REPLACE PROCEDURE restore_students_state(
    p_timestamp TIMESTAMP,
    time_offset INTERVAL DAY TO SECOND DEFAULT NULL
) IS
    effective_time TIMESTAMP;
BEGIN
    IF time_offset IS NOT NULL THEN
        effective_time := SYSTIMESTAMP - time_offset;
    ELSE
        effective_time := p_timestamp;
    END IF;

    FOR lg IN (
        SELECT *
        FROM students_log
        WHERE action_date >= effective_time
        ORDER BY action_date DESC
    ) LOOP
        IF lg.action = 'INSERT' THEN
            DELETE FROM students
            WHERE student_id = lg.new_student_id;

        ELSIF lg.action = 'UPDATE' THEN
            UPDATE students
            SET student_name = lg.old_student_name,
                gr_id = lg.old_gr_id,
                student_id = lg.old_student_id
            WHERE student_id = lg.new_student_id;

        ELSIF lg.action = 'DELETE' THEN
            INSERT INTO students (student_id, student_name, gr_id)
            VALUES (lg.old_student_id, lg.old_student_name, lg.old_gr_id);
        END IF;
    END LOOP;
END;
/