import sqlite3

# Connect to database (or create it)
conn = sqlite3.connect("product_db.db")
cursor = conn.cursor()

# Create the table
cursor.execute('''
CREATE TABLE IF NOT EXISTS products (
  product_id INTEGER PRIMARY KEY,
  name TEXT,
  quantity INTEGER,
  unit_price REAL,
  image_path TEXT
);
''')

# Product entries
products = [
    (293073, 'Strawberry 1kg', 50, 3.99, 'assets/images/db/293073.png'),
    (926868, 'Cola', 100, 1.49, 'assets/images/db/926868.png'),
    (417009, 'Fresh Lemons', 5, 2.20, 'assets/images/db/417009.png'),
    (424718, 'Toothbrush Pro', 75, 0.99, 'assets/images/db/424718.jpg'),
    (799380, 'Farm Eggs', 300, 2.79, 'assets/images/db/799380.jpg'),
    (644730, 'Rain Umbrella', 40, 5.49, 'assets/images/db/644730.jpg'),
    (417528, 'Sun Blocker SPF50', 50, 6.99, 'assets/images/db/417528.jpg'),
    (575961, 'Toilet Tissue Pack', 150, 3.29, 'assets/images/db/575961.jpg'),
    (740474, 'Whole Wheat Bread', 180, 2.49, 'assets/images/db/740474.jpg'),
    (129553, 'Notebook', 100, 1.99, 'assets/images/db/129553.jpg'),
    (240196, 'Toy Truck', 25, 4.50, 'assets/images/db/240196.jpg'),
    (966126, 'Wall Clock', 15, 8.00, 'assets/images/db/966126.jpg'),
    (876627, 'Hand Sanitizer', 80, 2.49, 'assets/images/db/876627.jpg'),
    (457848, 'Choco Delights', 120, 1.89, 'assets/images/db/457848.jpg'),
    (357966, 'Wine', 40, 12.99, 'assets/images/db/357966.jpg'),
    (846554, 'Diet Coke', 220, 1.29, 'assets/images/db/846554.jpg'),
    (542696, 'Nacho Crunch', 90, 2.79, 'assets/images/db/542696.jpg'),
    (203454, 'Lays Classic', 300, 1.99, 'assets/images/db/203454.jpg'),
    (656573, 'Running Shoes', 35, 25.00, 'assets/images/db/656573.jpg'),
    (855119, 'Bluetooth Headphones', 20, 29.99, 'assets/images/db/855119.jpg'),
    (741835, 'Steel Water Bottle', 100, 3.49, 'assets/images/db/741835.jpg'),
    (391708, 'Chicken Breast', 120, 6.75, 'assets/images/db/391708.jpg'),
    (120672, 'Turkey Slices', 90, 5.80, 'assets/images/db/120672.jpg'),
    (221626, 'Pepsi Can', 250, 1.50, 'assets/images/db/221626.jpg'),
    (782729, 'Tomato Ketchup', 110, 2.20, 'assets/images/db/782729.jpg'),

]

# Insert entries
cursor.executemany("INSERT INTO products VALUES (?, ?, ?, ?, ?)", products)

# Commit and close
conn.commit()
conn.close()

print("Database created and populated.")
