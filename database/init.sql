CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO products (name, price) VALUES
    ('Wireless Mouse', 19.99),
    ('Mechanical Keyboard', 79.99),
    ('USB-C Hub', 34.50);