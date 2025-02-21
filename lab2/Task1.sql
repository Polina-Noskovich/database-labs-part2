
CREATE TABLE groups (
    id NUMBER NOT NULL,
    group_name VARCHAR2(20) NOT NULL,
    C_VAL NUMBER NOT NULL,
    CONSTRAINT group_id_pk PRIMARY KEY (id)
)
CREATE TABLE students (
    student_id NUMBER NOT NULL,
    student_name VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    CONSTRAINT student_id_pk PRIMARY KEY (student_id)
)


CREATE TABLE students_log (
    log_id NUMBER NOT NULL,
    action VARCHAR2(6) NOT NULL,
    new_student_id NUMBER,
    old_student_id NUMBER,
    new_student_name VARCHAR2(20),
    old_student_name VARCHAR2(20),
    new_gr_id NUMBER,
    old_gr_id NUMBER,
    action_date TIMESTAMP NOT NULL,
    CONSTRAINT log_id_pk PRIMARY KEY (log_id)
);

CREATE SEQUENCE STUDENT_ID_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE GROUP_ID_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE students_log_seq START WITH 1 INCREMENT BY 1;

SELECT USER FROM DUAL;


