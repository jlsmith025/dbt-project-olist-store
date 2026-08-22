create database if not exists raw;

create schema if not exists olist;

create table if not exists raw.olist.customers (

	customer_id varchar(16777216),
	customer_unique_id varchar(16777216),
	customer_zip_code_prefix varchar(5),
	customer_city varchar(16777216),
	customer_state varchar(16777216)

);

create table if not exists raw.olist.geolocation (

	geolocation_zip_code_prefix varchar(5),
	geolocation_lat geography,
	geolocation_lng geography,
	geolocation_city varchar(16777216),
	geolocation_state varchar(16777216)

);

create table if not exists raw.olist.orders (
	
    order_id varchar(16777216),
	customer_id varchar(16777216),
	order_status varchar(16777216),
	order_purchase_timestamp timestamp_ntz(9),
	order_approved_at timestamp_ntz(9),
	order_delivered_carrier_date timestamp_ntz(9),
	order_delivered_customer_date timestamp_ntz(9),
	order_estimated_delivery_date timestamp_ntz(9)
    
);

create table if not exists raw.olist.order_items (

    order_id varchar(16777216),
	order_item_id number(2,0),
	product_id varchar(16777216),
	seller_id varchar(16777216),
	shipping_limit_date timestamp_ntz(9),
	price number(18,2),
	freight_value number(18,2)
    
);

create table if not exists raw.olist.order_payments (

    order_id varchar(16777216),
	payment_sequential number(2,0),
	payment_type varchar(16777216),
	payment_installments number(2,0),
	payment_value number(18,2)

);

create table if not exists raw.olist.order_reviews (
	
	review_id varchar(16777216),
	order_id varchar(16777216),
	review_score number(1,0),
	review_comment_title varchar(16777216),
	review_comment_message varchar(16777216),
	review_creation_date timestamp_ntz(9),
	review_answer_timestamp timestamp_ntz(9)

);

create table if not exists raw.olist.products (
	
    product_id varchar(16777216),
	product_category_name varchar(16777216),
	product_name_lenght number(5,0),
	/* product_description_lenght typo matches source csv file */
    product_description_lenght number(5,0),
	product_photos_qty number(2,0),
	product_weight_g number(5,0),
	product_length_cm number(5,0),
	product_height_cm number(5,0),
	product_width_cm number(5,0)
    
);

create table if not exists raw.olist.product_category_name_translation (
	
    product_category_name varchar(16777216),
	product_category_name_english varchar(16777216)
    
);

create table if not exists raw.olist.sellers (
	
    seller_id varchar(16777216),
	seller_zip_code_prefix varchar(5),
	seller_city varchar(16777216),
	seller_state varchar(16777216),
    seller_name varchar(16777216) 
    
);