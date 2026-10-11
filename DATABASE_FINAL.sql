create database  if not exists `E_Commerce_Customer_Intelligence`;
use E_Commerce_Customer_Intelligence;
-- create customer table first
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) UNIQUE,
    customer_zip_code_prefix INT NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state VARCHAR(10) NOT NULL
);
-- create sellers table 
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT NOT NULL,
    seller_city VARCHAR(50) NOT NULL,
    seller_state VARCHAR(20) NOT NULL
);
-- create products table
CREATE TABLE products (
    product_id VARCHAR(100) PRIMARY KEY,
    product_category_name VARCHAR(100) NOT NULL,
    product_name_length INT NOT NULL,
    product_description_length INT NOT NULL,
    product_photos_qty INT NOT NULL,
    product_weight_g INT NOT NULL,
    product_length_cm INT NOT NULL,
    product_height_cm INT NOT NULL,
    product_width_cm INT NOT NULL,
    CHECK (product_name_length > 0),
    CHECK (product_description_length > 0),
    CHECK (product_photos_qty > 0),
    CHECK (product_weight_g > 0),
    CHECK (product_length_cm > 0),
    CHECK (product_height_cm > 0),
    CHECK (product_width_cm > 0)
);
-- create geolocation table
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,8) NOT NULL ,
    geolocation_lng DECIMAL(10,8) NOT NULL,
    geolocation_state VARCHAR(2) NOT NULL,
    geolocation_city VARCHAR(20) NOT NULL,
    CHECK (geolocation_state IN ('SP', 'MG', 'RJ', 'RS', 'PR', 'SC', 'BA', 'GO', 'PE', 'ES', 'CE', 'MT',
       'DF', 'MS', 'PA', 'MA', 'PB', 'RN', 'PI', 'AL', 'TO', 'SE', 'RO', 'AM',
       'AC', 'AP', 'RR'))
);
-- create orders table
CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NOT NULL,
    CHECK (order_status IN (
        'delivered','shipped','canceled','unavailable',
        'invoiced','processing','created','approved'
    )),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
-- create order_items
CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date DATETIME NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    CHECK (order_item_id >= 0),
    CHECK (price >= 0),
    CHECK (freight_value >= 0)
);
-- create payments table
CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CHECK (payment_sequential > 0),
    CHECK (payment_installments > 0),
    CHECK (payment_value >= 0),
    CHECK (payment_type IN ('credit_card','boleto','voucher','debit_card'))
);
-- create review
CREATE TABLE order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    review_score INT NOT NULL,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CHECK (review_score BETWEEN 1 AND 5)
);
-- INSERTION IN DATABASE
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
-- INSERT VALUES INTO customers TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/Customer_cleaned_data.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO sellers TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_sellers.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO products TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_products (1).csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO geolocation TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_geolocation.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO orders TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO order_items TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO order_payments TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_payment.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- INSERT VALUES INTO order_reviews TABLE
LOAD DATA LOCAL INFILE 'C:/Users/bg566/Downloads/cleaned_review.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- triggered on insert
DELIMITER $$
CREATE TRIGGER before_orders_insert
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_purchase_timestamp IS NULL THEN
	SET NEW.order_purchase_timestamp = CURRENT_TIMESTAMP;
    END IF;
    IF NEW.order_approved_at IS NOT NULL
	AND NEW.order_approved_at < NEW.order_purchase_timestamp THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT =
	'order_approved_at cannot be earlier than order_purchase_timestamp';
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_order_items_insert
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE purchase_time DATETIME;
    -- Get purchase timestamp from orders
    SELECT order_purchase_timestamp INTO purchase_time FROM orders
    WHERE order_id = NEW.order_id;
    -- Validate shipping limit date
    IF NEW.shipping_limit_date < purchase_time THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT='shipping_limit_date must be greater than or equal to order_purchase_timestamp';
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_order_review
BEFORE INSERT ON order_reviews
FOR EACH ROW
BEGIN
	IF NEW.review_creation_date IS NOT NULL
    AND NEW.review_answer_timestamp IS NOT NULL
    AND NEW.review_creation_date>NEW.review_answer_timestamp THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT='review_answer_timestamp cannot be earlier than review_creation_date';
    END IF;
END$$
DELIMITER ;

-- STORED PROCEDURE
-- Recency → how recently customer purchased
-- Frequency → number of orders
-- Monetary → amount spent
DELIMITER $$
CREATE PROCEDURE customer_rfm()
BEGIN SELECT o.customer_id,
        DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders),
	    MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(
            SUM(oi.price * oi.order_item_quantity),2) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id;
END$$
DELIMITER ;