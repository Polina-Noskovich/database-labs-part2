CREATE OR REPLACE TRIGGER cascade_delete_students
BEFORE DELETE ON groups
FOR EACH ROW
BEGIN
    DELETE FROM students
    WHERE gr_id = :old.id;
END;