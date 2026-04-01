CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    stock INT NOT NULL DEFAULT 0 -- Số lượng tồn kho
);


CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(id),
    quantity INT NOT NULL CHECK (quantity > 0) -- Số lượng mua
);

CREATE OR REPLACE FUNCTION sync_inventory()
RETURNS TRIGGER AS $$
BEGIN
    -- TRƯỜNG HỢP 1: Thêm đơn hàng mới (INSERT) -> Trừ kho
    IF (TG_OP = 'INSERT') THEN
        UPDATE products 
        SET stock = stock - NEW.quantity 
        WHERE id = NEW.product_id;
        RETURN NEW;

    -- TRƯỜNG HỢP 2: Chỉnh sửa đơn hàng (UPDATE) -> Cập nhật lại kho
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Công thức: Tồn kho mới = Tồn kho hiện tại + Số lượng cũ - Số lượng mới
        UPDATE products 
        SET stock = stock + OLD.quantity - NEW.quantity 
        WHERE id = NEW.product_id;
        RETURN NEW;

    -- TRƯỜNG HỢP 3: Hủy đơn hàng (DELETE) -> Trả lại kho
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE products 
        SET stock = stock + OLD.quantity 
        WHERE id = OLD.product_id;
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_inventory
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION sync_inventory();

-- THỰC HÀNH KIỂM TRA

-- Bước A: Chuẩn bị kho hàng (Ví dụ: 10 cái bàn, 20 cái ghế)
INSERT INTO products (name, stock) VALUES ('Bàn làm việc', 10), ('Ghế xoay', 20);
SELECT * FROM products;

-- Bước B: Test INSERT (Mua 3 cái bàn)
INSERT INTO orders (product_id, quantity) VALUES (1, 3);
-- Kiểm tra: Bàn làm việc còn lại 7 cái
SELECT * FROM products;

-- Bước C: Test UPDATE (Đổi từ mua 3 cái thành mua 8 cái bàn)
UPDATE orders SET quantity = 8 WHERE product_id = 1;
-- Kiểm tra: Bàn làm việc từ 7 cái trừ tiếp 5 cái (chênh lệch) còn 2 cái
SELECT * FROM products;

-- Bước D: Test DELETE (Hủy đơn hàng mua bàn)
DELETE FROM orders WHERE product_id = 1;
-- Kiểm tra: Bàn làm việc quay lại đủ 10 cái
SELECT * FROM products;