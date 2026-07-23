CREATE DATABASE  ecommerce_analytics;
USE ecommerce_analytics;

-------------------------
-- Customers
-------------------------
CREATE TABLE customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-------------------------
-- Sellers
-------------------------
CREATE TABLE sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-------------------------
-- Products
-------------------------
CREATE TABLE products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm DECIMAL(8,2),
    product_height_cm DECIMAL(8,2),
    product_width_cm DECIMAL(8,2)
);

-------------------------
-- Category Translation
-------------------------
CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-------------------------
-- Orders
-------------------------
CREATE TABLE orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-------------------------
-- Order Items
-------------------------
CREATE TABLE order_items (
    order_id CHAR(32),
    order_item_id INT,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),

    PRIMARY KEY(order_id, order_item_id),

    CONSTRAINT fk_item_order
        FOREIGN KEY(order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_item_product
        FOREIGN KEY(product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_item_seller
        FOREIGN KEY(seller_id)
        REFERENCES sellers(seller_id)
);

-------------------------
-- Payments
-------------------------
CREATE TABLE order_payments (
    order_id CHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2),

    PRIMARY KEY(order_id, payment_sequential),

    CONSTRAINT fk_payment_order
        FOREIGN KEY(order_id)
        REFERENCES orders(order_id)
);

-------------------------
-- Reviews
-------------------------
CREATE TABLE order_reviews (
    review_id CHAR(32) PRIMARY KEY,
    order_id CHAR(32),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,

    CONSTRAINT fk_review_order
        FOREIGN KEY(order_id)
        REFERENCES orders(order_id)
);

-------------------------
-- Geolocation
-------------------------
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

-------------------------
-- Indexes
-------------------------

-- Customers
CREATE INDEX idx_customers_unique
ON customers(customer_unique_id);

-- Orders
CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX idx_orders_status
ON orders(order_status);

CREATE INDEX idx_orders_purchase_date
ON orders(order_purchase_timestamp);

-- Order Items
CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

-- Order Payments
CREATE INDEX idx_payments_type
ON order_payments(payment_type);

-- Order Reviews
CREATE INDEX idx_order_reviews_order_id
ON order_reviews(order_id);

CREATE INDEX idx_reviews_score
ON order_reviews(review_score);

-- Products
CREATE INDEX idx_products_category
ON products(product_category_name);

-- Geolocation
CREATE INDEX idx_geo_prefix
ON geolocation(geolocation_zip_code_prefix);
