select * from olist_customers_dataset

select COUNT(customer_id)
from olist_customers_dataset

select COUNT(DISTINCT(customer_id))
from olist_customers_dataset

/*
	First --> when I explore customer table, I find that there are two columns describe each customer, so we need to delete one 
	from them, after some exploration we find that other tables are related to this table via customer_id (this's unique)
	- So I decided to reomve customer_unique_id
*/

select * from olist_geolocation_dataset
/*
	there's an important problem --> the zip_code is duplicated because the same zip_code may has more than one GPS point
	In this case we take the average geolocation_lat and geolocation_lng
*/

/*				select 
					geolocation_zip_code_prefix,
					avg(geolocation_lat) as geolocation_lat,
					avg(geolocation_lng) as geolocation_lng,
					max(geolocation_city) as geolocation_city,
					max(geolocation_state) as geolocation_state
				from olist_geolocation_dataset
				group by geolocation_zip_code_prefix
*/

-- this table have a lot of null values in some columns 
select * from olist_orders_dataset
where order_delivered_customer_date is null

/*
	first(order_approved_at) --> if it is NULL & order_status is delivered
								--> I put the order_purchase_timestamp value in it
							 --> if order_status is canceled or created we make it equal '1990-01-01'

	second(order_delivered_carrier_date)	--> if order_status is canceled or created --> we make it '1990-01-01'
										--> else make it equal order_purchase_timestamp

	third(order_delivered_customer_date)	--> if order_status is canceled or created --> we make it '1990-01-01'
										--> else make if equal order_estimated_delivary_date
			
			---- I will handle these columns in SSIS tool 
*/


select * from olist_order_items_dataset
-- This table doesn't have any problems 

select * from olist_order_payments_dataset
-- This table doesn't have any problems 



select * from olist_order_reviews_dataset
/*
		here we can replace nulls in review_comment_title by 'no_title'
		and replace nulls in review_comment_message by 'no_message'
*/

select * from olist_products_dataset

/*
		We can replace category_name by 'unknown' and replace the aother columns with zoer value
*/


select * from olist_sellers_dataset
-- This table doesn't have any problems  



select * from product_category_name_translation
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

