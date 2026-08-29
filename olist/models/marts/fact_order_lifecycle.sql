with order_data as (

    select 
       customers.customer_unique_id,
       orders.*
    from
        {{ ref('stg__customers') }} customers
        inner join {{ ref('stg__orders') }} orders on customers.order_customer_id = orders.order_customer_id

),

orders_calculations as (

    select 
        md5(order_customer_id) as order_customer_key,
        md5(customer_unique_id) as customer_unique_key,
    
        customer_unique_id,
        order_customer_id,
        order_id,
        initcap(order_status) as order_status,
        
        /* Lifecycle dates and timestamps */
        to_number(
            to_char(order_purchase_timestamp, 'YYYYMMDD')
        ) as order_purchase_date_key,
        to_time(order_purchase_timestamp) as order_purchase_at,
    
        to_number(
            to_char(order_approved_timestamp, 'YYYYMMDD')
        ) as order_approved_date_key,
        to_time(order_approved_timestamp) as order_approved_at,
    
        to_number(
            to_char(order_delivered_carrier_timestamp, 'YYYYMMDD')
        ) as order_carrier_handoff_date_key,
        to_time(order_delivered_carrier_timestamp) as order_carrier_handoff_at,
    
        to_number(
            to_char(order_delivered_customer_timestamp, 'YYYYMMDD')
        ) as order_delivered_date_key,
        to_time(order_delivered_customer_timestamp) as order_delivered_at,
    
        to_number(
            to_char(order_estimated_delivery_date, 'YYYYMMDD')
        ) as order_estimated_delivery_date_key,
    
        /* Lifecycle durations */
        datediff(
            'minute',
            order_purchase_timestamp,
            order_approved_timestamp
        ) as approval_duration_minutes,
    
        datediff(
            'hour',
            order_purchase_timestamp,
            order_delivered_carrier_timestamp
        ) as purchase_to_carrier_handoff_duration_hours,
    
        datediff(
            'day',
            order_purchase_timestamp,
            order_delivered_customer_timestamp
        ) as purchase_to_delivery_duration_days,
    
        datediff(
            'day',
            order_delivered_carrier_timestamp,
            order_delivered_customer_timestamp
        ) as carrier_handoff_to_delivery_duration_days,
    
        /* Delivery performance */
        datediff(
            'day',
            order_estimated_delivery_date,
            order_delivered_customer_timestamp
        ) as delivery_variance_to_estimate_days, /* negative is early, positive late */
    
        iff(delivery_variance_to_estimate_days < 0,
            abs(delivery_variance_to_estimate_days),
            null) as days_delivered_early,
    
        iff(delivery_variance_to_estimate_days > 0,
            delivery_variance_to_estimate_days,
            null) as days_delivered_late,
    
        case
            when order_delivered_customer_timestamp is null
                then 'Not Delivered'
            when order_estimated_delivery_date is null
                then 'Estimate Unavailable'
            when cast(order_delivered_customer_timestamp as date)
                 < order_estimated_delivery_date
                then 'Delivered - Early'
            when cast(order_delivered_customer_timestamp as date)
                 = order_estimated_delivery_date
                then 'Delivered - On Time'
            when cast(order_delivered_customer_timestamp as date)
                 > order_estimated_delivery_date
                then 'Delivered - Late'
        end as delivery_performance_status,
    
        case
            when order_delivered_customer_timestamp is null then null
            when cast(order_delivered_customer_timestamp as date)
                 < order_estimated_delivery_date then 1
            else 0
        end as was_delivered_early,
    
        case
            when order_delivered_customer_timestamp is null then null
            when cast(order_delivered_customer_timestamp as date)
                 = order_estimated_delivery_date then 1
            else 0
        end as was_delivered_on_time,
    
        case
            when order_delivered_customer_timestamp is null then null
            when cast(order_delivered_customer_timestamp as date)
                 > order_estimated_delivery_date then 1
            else 0
        end as was_delivered_late,
    
        /* Lifecycle flags */
        iff(order_approved_timestamp is not null, 1, 0) as was_approved,
        iff(order_delivered_carrier_timestamp is not null, 1, 0) as was_handed_to_carrier,
        iff(order_delivered_customer_timestamp is not null, 1, 0) as was_delivered,
        iff(order_status = 'canceled', 1, 0) as was_canceled,
        
        /* dw load time */
        current_timestamp() as dw_loaded_at
    
    from 
        order_data
    
)

select * from orders_calculations