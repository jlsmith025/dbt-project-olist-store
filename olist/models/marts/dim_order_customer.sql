with geolocation as (

    select * from {{ ref('int__geolocation_flattened') }}

), 

customers as (

    select * from {{ ref('stg__customers') }}
    
),

orders as (

    select * from {{ ref('stg__orders') }}

),

order_customer_summary as (
  
    select
        customers.customer_id,
        count(*) as customer_total_number_of_purchases
    from 
        customers
    group by 1

),

order_customer_sequencing as (
    
    select 
        customers.customer_id,
        orders.order_customer_id,
        /* these arent working because order does not have a unique customer id */
        row_number() over (partition by customers.customer_id order by orders.order_purchase_timestamp) as order_sequence_number,
        row_number() over (partition by customers.customer_id order by orders.order_purchase_timestamp desc) as reverse_order_sequence_number,
    from 
        customers
        inner join orders on customers.order_customer_id = orders.order_customer_id

),

order_customers_combined as (

select 
    md5(customers.order_customer_id) as order_key,
    customers.order_customer_id,
    customers.customer_id,
    /* Capitalizes proper nouns of city names */
    array_to_string(
            transform(
                split(
                    lower(
                        replace(customers.customer_city, '_', ' ')
                    ), ' '
                ),
                word ->
                    iff(
                        /* Leave appropriate Portuguese words lowercase */
                        word in ('de', 'dos', 'da', 'do', 'e'),
                        word,
                        initcap(word)
                    )
            ),
            ' '
    ) as customer_city,
    customers.customer_state,
    customers.customer_zip_code,
    geolocation.geolocation_latitude,
    geolocation.geolocation_longitude,
    orders.order_status,
    orders.order_purchase_timestamp,
    orders.order_approved_timestamp,
    orders.order_delivered_carrier_timestamp,
    orders.order_delivered_customer_timestamp,
    orders.order_estimated_delivery_date,
    /* order sequencing, flagging first and last order, and order total aggregation */
    case when order_customer_sequencing.order_sequence_number = 1 then 'Y' else 'N' end as is_customers_first_order,
    case when order_customer_sequencing.reverse_order_sequence_number = 1 then 'Y' else 'N' end as is_customer_latest_order,
    order_customer_sequencing.order_sequence_number as customer_order_sequence_number,
    order_customer_summary.customer_total_number_of_purchases,
    /* Timing of the delivery and comparison to estimate */
    cast(orders.order_delivered_carrier_timestamp as date) - cast(orders.order_approved_timestamp as date) as days_order_to_carrier,
    cast(orders.order_delivered_customer_timestamp as date) - cast(orders.order_delivered_carrier_timestamp as date) as days_carrier_to_customer,
    case
        when cast(orders.order_delivered_customer_timestamp as date) < orders.order_estimated_delivery_date then 'Early'
        when cast(orders.order_delivered_customer_timestamp as date) = orders.order_estimated_delivery_date then 'On time'
        when cast(orders.order_delivered_customer_timestamp as date) > orders.order_estimated_delivery_date then 'Late'
        when orders.order_delivered_customer_timestamp is null then 'Not yet delivered'
        else 'Not available'
    end as delivery_timing_status,
    cast(orders.order_delivered_customer_timestamp as date) - orders.order_estimated_delivery_date as days_delivery_to_estimate,
    /* dw load time */
    current_timestamp() as dw_loaded_timestamp
from 
    customers
    inner join orders on customers.order_customer_id = orders.order_customer_id
    inner join order_customer_summary on customers.customer_id = order_customer_summary.customer_id
    inner join order_customer_sequencing on customers.order_customer_id = order_customer_sequencing.order_customer_id
    left outer join geolocation on customers.customer_zip_code = geolocation.geolocation_zip_code

)

select * from order_customers_combined