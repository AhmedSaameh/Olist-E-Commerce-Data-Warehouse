
-- Table(1) : olist_customers_dataset

SELECT
	COUNT(*) as total, COUNT(DISTINCT customer_id) as customer_id, COUNT(DISTINCT customer_unique_id) as customer_unique_id
FROM olist_customers_dataset
/*
	We'll explore each table to select a primary key column 
	In this table we find that values of customer_id is unique and other tables have a customer_id not (customer_unique_id)
	- So I decide to remove customer_unique_id column 
*/
ALTER TABLE olist_customers_dataset
DROP COLUMN customer_unique_id



-- Table(2) : olist_geolocation_dataset
select * 
from olist_geolocation_dataset

/*
	I find that the same zip_code appeared one than one time, that because the same zip_code has one than one GPS point
	- In this case we take the AVG of geolocation_lat and geolocation_lng
*/

/*
	SELECT 
		geolocation_zip_code_prefix,
		AVG(geolocation_lat) as geolocation_lat,
		AVG(geolocation_lng) as geolocation_lng,
		MAX(geolocation_city) as geolocation_city,
		MAX(geolocation_state) as geolocation_state
	INTO olist_geolocation_dataset_new
	FROM olist_geolocation_dataset
	GROUP BY geolocation_zip_code_prefix
	DROP TABLE olist_geolocation_dataset
	EXEC sp_rename 'olist_geolocation_dataset_new', 'olist_geolocation_dataset'
*/


-- Table(3) : olist_orders_dataset

SELECT *
FROM olist_orders_dataset


/*
	first(order_approved_at)
					--> if it is NULL & order_status is delivered
					--> I put the order_purchase_timestamp value instead of null value
					--> if order_status is canceled or created we make it equal '1990-01-01'

	second(order_delivered_carrier_date)	
					--> if order_status is canceled or created --> we make it '1990-01-01'
					--> else make it equal order_purchase_timestamp

	third(order_delivered_customer_date)	
					--> if order_status is canceled or created --> we make it '1990-01-01'
					--> else make if equal order_estimated_delivary_date
			
			---- I will handle these columns in SSIS tool 
*/





-- Table(4) : olist_order_items_dataset
SELECT  * 
FROM olist_order_items_dataset
-- This table doesn't have any problems 



-- Table(5) : olist_order_payments_dataset
SELECT * 
FROM olist_order_payments_dataset
-- This table doesn't have any problems 



-- Table(6) : olist_order_reviews_dataset
SELECT * 
FROM olist_order_reviews_dataset
/*
		here we can replace nulls in review_comment_title by 'no_title'
		and replace nulls in review_comment_message by 'no_message'
*/


-- Table(7) : olist_products_dataset
SELECT * 
FROM olist_products_dataset
SELECT *
FROM product_category_name_translation


/*
		We can replace category_name by 'unknown' and replace the aother columns with zoer value
*/


-- Table(8) : olist_sellers_dataset
SELECT * 
FROM olist_sellers_dataset
-- This table doesn't have any problems  



-- Table(9) : product_category_name_translation
SELECT *
FROM product_category_name_translation
-- This table doesn't have any problems  




-----------------------------------------------------------------------------------------------
-- Here we add all Primary keys constraints on each table 


-- PK_customer
alter table olist_customers_dataset
add constraint PK_customer primary key (customer_id)


-- PK_orders
alter table olist_orders_dataset
add constraint PK_order primary key (order_id)

-- PK_product
alter table olist_products_dataset
add constraint PK_product primary key (product_id)

-- PK_sellers
alter table olist_sellers_dataset 
add constraint PK_seller primary key (seller_id)

-- PK_category_name 
alter table product_category_name_translation
add constraint PK_translation primary key (product_category_name)

-- PK_order_payment
alter table olist_order_payments_dataset
add constraint PK_order_payment primary key (order_id, payment_sequential)

-- PK_order_items
alter table olist_order_items_dataset 
add constraint PK_order_item primary key (order_id, order_item_id)

-- PK_order_reviews 
alter table olist_order_reviews_dataset
add constraint PK_order_review primary key (order_id, review_id)


-- Before we add a primary key to geolocation table we must first remove duplicates 
SELECT 
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) as geolocation_lat,
    AVG(geolocation_lng) as geolocation_lng,
    MAX(geolocation_city) as geolocation_city,
    MAX(geolocation_state) as geolocation_state
INTO olist_geolocation_clean
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix
-- PK_geolocation
alter table olist_geolocation_clean
add constraint PK_geolocation primary key (geolocation_zip_code_prefix)








-------------------------------------------------------------------------------------------------
-- Here we add all Foreign keys constriants between the tables to create the database schema 


-- relationship between orders and order_review 
alter table olist_order_reviews_dataset
add constraint FK_order_review foreign key (order_id) references olist_orders_dataset(order_id)


-- relationship between orders and order_payment
alter table olist_order_payments_dataset
add constraint FK_order_payment foreign key (order_id) references olist_orders_dataset(order_id)


-- relationship between orders and order_item 
alter table olist_order_items_dataset
add constraint FK_order_item foreign key (order_id) references olist_orders_dataset(order_id)


-- relationship between products and order_item 
alter table olist_order_items_dataset
add constraint FK_product_item foreign key (product_id) references olist_products_dataset(product_id)


-- relationship between sellers and order_item 
alter table olist_order_items_dataset
add constraint FK_seller_order foreign key (seller_id) references olist_sellers_dataset(seller_id)


-- relationship between sellers and geolocation

INSERT INTO olist_geolocation_clean
SELECT DISTINCT seller_zip_code_prefix, 0, 0, 'unknown', 'unknown'
FROM olist_sellers_dataset
WHERE seller_zip_code_prefix NOT IN (
    SELECT geolocation_zip_code_prefix 
    FROM olist_geolocation_clean
)
alter table olist_sellers_dataset
add constraint FK_seller_location foreign key (seller_zip_code_prefix) references olist_geolocation_clean(geolocation_zip_code_prefix)



-- relationship between customer and geolocation
INSERT INTO olist_geolocation_clean
SELECT DISTINCT customer_zip_code_prefix, 0, 0, 'unknown', 'unknown'
FROM olist_customers_dataset
WHERE customer_zip_code_prefix NOT IN (
    SELECT geolocation_zip_code_prefix 
    FROM olist_geolocation_clean
)
alter table olist_customers_dataset
add constraint FK_customer_location foreign key (customer_zip_code_prefix) references olist_geolocation_clean(geolocation_zip_code_prefix)


-- relationship between customer and orders 
alter table olist_orders_dataset
add constraint FK_customer_order foreign key (customer_id) references olist_customers_dataset(customer_id)


-- relationship between product and product_category
INSERT INTO product_category_name_translation
SELECT DISTINCT product_category_name, 'unknown'
FROM olist_products_dataset
WHERE product_category_name NOT IN (
    SELECT product_category_name 
    FROM product_category_name_translation
)
alter table olist_products_dataset
add constraint FK_product_category foreign key (product_category_name) references product_category_name_translation(product_category_name)

