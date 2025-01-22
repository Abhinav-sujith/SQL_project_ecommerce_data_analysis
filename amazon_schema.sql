-- AMAZON E-COMMERCE DATABASE SCHEMA
-- CREATE PARENT TABLE STRUCTURE

-- CREATE SELLERS TABLE 
CREATE TABLE sellers
(
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(25),
    origin VARCHAR(5)
);
-- UPDATING COLUMN ORIGIN 
ALTER TABLE sellers 
ALTER COLUMN origin TYPE VARCHAR(15);

-- CREATE CATEGORY MASTER TABLE
CREATE TABLE category 
(
    category_id INT PRIMARY KEY,
    category_name VARCHAR(30)
);

-- CREATE CUSTOMER TABLE 
CREATE TABLE customer 
(
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(25),
    last_name VARCHAR(25),
    state VARCHAR(20),
    address VARCHAR(5) DEFAULT '***'
);

-- CREATE CHILD TABLE STRUCTURE
-- CREATE PRODUCTS TABLE
CREATE TABLE products 
(
    product_id INT PRIMARY KEY, 
    product_name VARCHAR(50),
    price FLOAT,
    cogs FLOAT,
    category_id INT,  -- FK 
    CONSTRAINT fk_prod_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- CREATE ORDER TABLE 
CREATE TABLE orders 
(
    order_id INT PRIMARY KEY,
    order_date DATE,
    customer_id INT,  -- FK 
    seller_id INT,  -- FK 
    order_status VARCHAR(20),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_orders_seller FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- CREATE ORDER_ITEM TABLE 
CREATE TABLE order_items 
(
    order_item_id INT PRIMARY KEY,
    order_id INT,  -- FK 
    product_id INT,  -- FK
    quantity INT, 
    price_per_unit FLOAT,
    CONSTRAINT fk_order_item_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_product_id_orders FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- CREATE PAYMENT TABLE 
CREATE TABLE payments 
(
    payment_id INT PRIMARY KEY, 
    order_id INT, 
    payment_date DATE,
    payment_status VARCHAR(20),
    CONSTRAINT fk_order_id_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- CREATE SHIPPING TABLE 
CREATE TABLE shipping 
(
    shipping_id INT PRIMARY KEY, 
    order_id INT,  -- FK
    shipping_date DATE,  
    return_date DATE,
    shipping_provider VARCHAR(15),
    delivery_status VARCHAR(15),
    CONSTRAINT fk_order_id_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- CREATE INVENTORY TABLE 
CREATE TABLE inventory 
(
    inventory_id INT PRIMARY KEY,  
    product_id INT,  -- FK
    stock INT,
    warehouse_id INT,
    last_stock_date DATE,
    CONSTRAINT fk_product_id_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- END OF SCHEMA




