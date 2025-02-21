
CREATE OR REPLACE TRIGGER update_c_val_trigger AFTER
  INSERT OR UPDATE OR DELETE ON students FOR EACH ROW
DECLARE
  new_group_id NUMBER;
  old_group_id NUMBER;
BEGIN
  IF inserting THEN
    UPDATE groups
    SET
      c_val = c_val + 1
    WHERE
      id = :new.gr_id;
  ELSIF updating THEN
    new_group_id := :new.gr_id;
    old_group_id := :old.gr_id;
    IF new_group_id <> old_group_id THEN
      UPDATE groups
      SET
        c_val = c_val + 1
      WHERE
        id = new_group_id;
      UPDATE groups
      SET
        c_val = c_val - 1
      WHERE
        id = old_group_id;
    END IF;
  ELSIF deleting THEN
    UPDATE groups
    SET
      c_val = c_val - 1
    WHERE
      id = :old.gr_id;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error updating c_val ' || sqlerrm);
END;