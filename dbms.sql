
CREATE DATABASE IF NOT EXISTS E_Commerce_Customer_Intelligence;

USE E_Commerce_Customer_Intelligence;


-- 1. PRODUCTS TABLE
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(150),
    price DECIMAL(10,2) NOT NULL,
    rating_avg DECIMAL(3,2),
    review_count INT DEFAULT 0,
    stock_quantity INT DEFAULT 0,
    date_added DATE,

    CONSTRAINT chk_product_price
        CHECK (price >= 0),

    CONSTRAINT chk_product_rating
        CHECK (rating_avg IS NULL OR
               (rating_avg >= 0 AND rating_avg <= 5)),

    CONSTRAINT chk_product_reviews
        CHECK (review_count >= 0),

    CONSTRAINT chk_product_stock
        CHECK (stock_quantity >= 0)
);


-- 2. USERS TABLE
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    age INT,
    gender VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    signup_date DATE,
    income_level VARCHAR(50),
    preferred_category VARCHAR(100),
    loyalty_tier VARCHAR(50),

    CONSTRAINT chk_user_age
        CHECK (age IS NULL OR age >= 0)
);


-- 3. SESSIONS TABLE
CREATE TABLE sessions (
    session_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    start_time DATETIME,
    device_type VARCHAR(50),
    referrer_source VARCHAR(100),
    is_converted BOOLEAN,

    CONSTRAINT fk_sessions_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);


-- 4. INTERACTIONS TABLE
CREATE TABLE interactions (
    interaction_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    session_id VARCHAR(50) NOT NULL,
    interaction_type VARCHAR(50),
    timestamp DATETIME,
    dwell_time_ms BIGINT,

    CONSTRAINT fk_interactions_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_interactions_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_interactions_session
        FOREIGN KEY (session_id)
        REFERENCES sessions(session_id),

    CONSTRAINT chk_dwell_time
        CHECK (dwell_time_ms IS NULL OR dwell_time_ms >= 0)
);


-- 5. PURCHASES TABLE
CREATE TABLE purchases (
    purchase_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    session_id VARCHAR(50),
    interaction_id VARCHAR(50),
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    order_date DATETIME,

    CONSTRAINT fk_purchases_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_purchases_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_purchases_session
        FOREIGN KEY (session_id)
        REFERENCES sessions(session_id),

    CONSTRAINT fk_purchases_interaction
        FOREIGN KEY (interaction_id)
        REFERENCES interactions(interaction_id),

    CONSTRAINT chk_purchase_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_purchase_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_purchase_total
        CHECK (total_amount >= 0),

    INDEX idx_purchases_order (order_id),
    INDEX idx_purchases_order_date (order_date)
);


-- 6. REVIEWS TABLE
CREATE TABLE reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    purchase_id VARCHAR(50),
    rating INT NOT NULL,
    title VARCHAR(255),
    review_text TEXT,
    review_date DATE,

    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_reviews_purchase
        FOREIGN KEY (purchase_id)
        REFERENCES purchases(purchase_id),

    CONSTRAINT chk_review_rating
        CHECK (rating BETWEEN 1 AND 5)
);

DELIMITER //

CREATE TRIGGER before_purchase_insert
BEFORE INSERT ON purchases
FOR EACH ROW
BEGIN
    SET NEW.total_amount =
        NEW.quantity * NEW.unit_price;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER before_purchase_update
BEFORE UPDATE ON purchases
FOR EACH ROW
BEGIN
    SET NEW.total_amount =
        NEW.quantity * NEW.unit_price;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER before_product_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Product price cannot be negative';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER before_review_insert
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Review rating must be between 1 and 5';
    END IF;
END //

DELIMITER ;

