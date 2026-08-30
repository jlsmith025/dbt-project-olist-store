-- models/marts/fact_order_reviews.sql
with reviews as (
    
    select * from {{ ref('stg__order_reviews') }}

),

order_customer as (
    
    select
        order_id,
        customer_city,
        customer_state,
        customer_zip_code,
        customer_latitude,
        customer_longitude
    from 
        {{ ref('dim_order_customer') }}

),

order_lifecycle as (

    select
        order_id,
        order_purchase_date_key,
        order_delivered_date_key,
        order_estimated_delivery_date_key,
        delivery_variance_to_estimate_days,
        purchase_to_delivery_duration_days,
        delivery_performance_status
    from 
        {{ ref('fact_order_lifecycle') }}

),

/* 
* Weight = 1 / number of orders sharing this review_id.
* SUM(review_score * review_weight) per review_id then equals the review's score once, 
* no matter how many order rows it fans out to. 
*/
reviews_weight_added as (
    /* Weight = 1 / number of orders sharing this review_id.
     * SUM(review_score * review_weight) per review_id then equals the review's score once, 
     * no matter how many order rows it fans out to. */

    select
        reviews.*,
        1.0 / count(*) over (partition by reviews.review_id) as review_weight,
        count(*) over (partition by reviews.review_id) as orders_per_review

    from reviews

),

final as (

    select
        -- primary key
        md5(review.review_id || review.order_id) as order_review_key,
        
        -- surrogate date keys and timestamps
        to_number(
            to_char(review.review_creation_date, 'YYYYMMDD')
        ) as review_created_date_key,

        to_number(
            to_char(review.review_answer_timestamp, 'YYYYMMDD')
        ) as review_answer_date_key,
        to_time(review.review_answer_timestamp) as review_answer_at,
                
        -- natural keys
        review.review_id,
        review.order_id,

        -- review dimensions       
        review.review_comment_title,
        review.review_comment_message,
        iff(review.review_comment_message is not null, true, false) as has_comment,
        
        -- denormalized delivery timing
        order_lifecycle.delivery_variance_to_estimate_days,
        order_lifecycle.purchase_to_delivery_duration_days,
        order_lifecycle.delivery_performance_status,

        -- denormalized location
        order_customer.customer_city,
        order_customer.customer_state,
        order_customer.customer_zip_code,
        order_customer.customer_latitude,
        order_customer.customer_longitude,

        -- review measures
        review.review_score,
        review.review_weight,
        review.orders_per_review,
        datediff('day', review.review_creation_date, review.review_answer_timestamp) as review_response_days,

    from reviews_weight_added review
    left join order_customer on review.order_id = order_customer.order_id
    left join order_lifecycle on review.order_id = order_lifecycle.order_id

)

select * from final