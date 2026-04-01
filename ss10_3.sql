CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    salary DECIMAL(15, 2)
);

CREATE TABLE employees_log (
    log_id SERIAL PRIMARY KEY,
    employee_id INT,
    operation VARCHAR(10), -- INSERT, UPDATE hoặc DELETE
    old_data JSONB,        -- Dữ liệu trước khi sửa/xóa
    new_data JSONB,        -- Dữ liệu sau khi thêm/sửa
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_employee_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO employees_log (employee_id, operation, new_data)
        VALUES (NEW.id, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
        
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO employees_log (employee_id, operation, old_data, new_data)
        VALUES (NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
        
    ELSIF (TG_OP = 'DELETE') THEN
        -- Với DELETE, chúng ta dùng OLD vì NEW không tồn tại
        INSERT INTO employees_log (employee_id, operation, old_data)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_employees_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
EXECUTE FUNCTION log_employee_changes();

INSERT INTO employees (name, position, salary) 
VALUES ('Đinh Quốc Huy', 'Backend Developer', 15000000);


UPDATE employees 
SET salary = 18000000 
WHERE name = 'Đinh Quốc Huy';


DELETE FROM employees WHERE id = 1;


SELECT * FROM employees_log ORDER BY change_time ASC;