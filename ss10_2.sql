CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    credit_limit DECIMAL(15, 2) NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id),
    order_amount DECIMAL(15, 2) NOT NULL
);

CREATE OR REPLACE FUNCTION check_credit_limit()
RETURNS TRIGGER AS $$
DECLARE
    current_total_spent DECIMAL(15, 2);
    allowed_limit DECIMAL(15, 2);
BEGIN
    SELECT COALESCE(SUM(order_amount), 0) INTO current_total_spent
    FROM orders
    WHERE customer_id = NEW.customer_id;

    SELECT credit_limit INTO allowed_limit
    FROM customers
    WHERE id = NEW.customer_id;

    IF (current_total_spent + NEW.order_amount) > allowed_limit THEN
        RAISE EXCEPTION 'Khách hàng % vượt hạn mức! (Hạn mức: %, Đã dùng: %, Đơn mới: %)', 
            NEW.customer_id, allowed_limit, current_total_spent, NEW.order_amount;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_credit
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION check_credit_limit();

INSERT INTO customers (name, credit_limit) VALUES ('Nguyễn Anh Sơn', 10000000);

INSERT INTO orders (customer_id, order_amount) VALUES (1, 5000000);

INSERT INTO orders (customer_id, order_amount) VALUES (1, 6000000);