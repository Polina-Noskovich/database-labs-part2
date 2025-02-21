
CREATE OR REPLACE TRIGGER student_id_autoinc BEFORE
    INSERT ON students FOR EACH ROW 
BEGIN
    IF :NEW.STUDENT_ID IS NULL THEN
        :NEW.STUDENT_ID := STUDENT_ID_SEQ.NEXTVAL;
    END IF;
END;

CREATE OR REPLACE TRIGGER group_id_autoinc BEFORE
    INSERT ON groups FOR EACH ROW
BEGIN
    :NEW.id := GROUP_ID_SEQ.NEXTVAL;
END;

CREATE OR REPLACE TRIGGER check_student_id_uniqueness
BEFORE INSERT ON students
FOR EACH ROW
DECLARE
    duplicate_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO duplicate_count
    FROM students
    WHERE student_id = :new.student_id;

    IF duplicate_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Student ID must be unique ' || :new.student_id);
    END IF;
END;

CREATE OR REPLACE TRIGGER check_group_id_name_uniqueness
BEFORE INSERT OR UPDATE ON groups
FOR EACH ROW
DECLARE
    duplicate_id_count NUMBER;
    duplicate_name_count NUMBER;
BEGIN
    IF INSERTING OR UPDATING('ID') THEN
        SELECT COUNT(*) INTO duplicate_id_count
        FROM groups
        WHERE id = :new.id;

        IF duplicate_id_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'group_id must be unique');
        END IF;
    END IF;

    IF INSERTING OR UPDATING('GROUP_NAME') THEN
        SELECT COUNT(*) INTO duplicate_name_count
        FROM groups
        WHERE LOWER(group_name) = LOWER(:new.group_name);

        IF duplicate_name_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'group_name must be unique');
        END IF;
    END IF;
END;
