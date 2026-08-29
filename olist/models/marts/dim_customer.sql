with first_customer_order as (

    select 
        customer_unique_id,
        orders.order_purchase_timestamp as first_order_purchase_timestamp
    from 
        {{ ref('dim_order_customer') }} dim_customer_order
        left outer join {{ ref('stg__orders') }} orders on dim_customer_order.order_id = orders.order_id 
    where
        dim_customer_order.is_customers_first_order = true

), 

latest_customer_order as (

   select 
        customer_unique_id,
        customer_city,
        customer_state,
        customer_zip_code,
        customer_latitude,
        customer_longitude,
        orders.order_purchase_timestamp as latest_order_purchase_timestamp
    from 
        {{ ref('dim_order_customer') }} dim_customer_order
        left outer join {{ ref('stg__orders') }} orders on dim_customer_order.order_id = orders.order_id
    where
        dim_customer_order.is_customers_latest_order = true
    
),

customer_summary as (
  
    select * from dev.jlsmith025_staging.int__customer_summary

),

flattened_customer_combined as (

    select
        md5(latest_customer_order.customer_unique_id) as customer_unique_key,
        
        latest_customer_order.customer_unique_id,
        latest_customer_order.customer_city as current_customer_city,
        latest_customer_order.customer_state current_customer_state,
        latest_customer_order.customer_zip_code current_customer_zip_code,
        latest_customer_order.customer_latitude current_customer_latitude,
        latest_customer_order.customer_longitude current_customer_longitude,

        to_date(first_customer_order.first_order_purchase_timestamp) as first_order_date,
        to_date(latest_customer_order.latest_order_purchase_timestamp) as last_order_date,

        customer_summary.total_completed_orders,
        customer_summary.lifetime_completed_order_revenue,
        
        current_timestamp() as dw_loaded_at
    from
        latest_customer_order
        inner join first_customer_order on latest_customer_order.customer_unique_id = first_customer_order.customer_unique_id
        inner join customer_summary on latest_customer_order.customer_unique_id = customer_summary.customer_unique_id

)

select * from flattened_customer_combined