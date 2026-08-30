with geolocation as (
    
    select * from {{ ref('int__geolocation_flattened') }}
),

customers as (

    select * from {{ ref('stg__customers') }}

),

orders as (

    select * from {{ ref('stg__orders') }}

),

customers_orders_joined as (

    select
        customers.order_customer_id,
        customers.customer_unique_id,
        customers.customer_city,
        customers.customer_state,
        customers.customer_zip_code,
        orders.order_id,
        orders.order_status,
        orders.order_purchase_timestamp,
        row_number() over (
            partition by customers.customer_unique_id
            order by orders.order_purchase_timestamp
        ) as order_sequence_number,
        row_number() over (
            partition by customers.customer_unique_id
            order by orders.order_purchase_timestamp desc
        ) as reverse_order_sequence_number
    from
        customers
        inner join orders on customers.order_customer_id = orders.order_customer_id

),

order_customers_combined as (

    select
        md5(customers_orders_joined.order_customer_id) as order_customer_key,
        customers_orders_joined.order_id,
        customers_orders_joined.order_customer_id,
        customers_orders_joined.customer_unique_id,
        
        /* Capitalize cities as proper nouns. Leave appropriate portuguese words lowercase */
        array_to_string(
            transform(
                split(lower(customers_orders_joined.customer_city), ' '),
                word -> iff(word in ('de', 'dos', 'da', 'do', 'e'), word, initcap(word))
            ),
            ' '
        ) as customer_city,
        customers_orders_joined.customer_state,
        customers_orders_joined.customer_zip_code,
        geolocation.geolocation_latitude as customer_latitude,
        geolocation.geolocation_longitude as customer_longitude,
        
        customers_orders_joined.order_status as current_order_status,
        iff(customers_orders_joined.order_sequence_number = 1, true, false) as is_customers_first_order,
        iff(customers_orders_joined.reverse_order_sequence_number = 1, true, false) as is_customers_latest_order,
        customers_orders_joined.order_sequence_number as customer_order_sequence_number,
        
        current_timestamp() as dw_loaded_at
    from
        customers_orders_joined
        left outer join geolocation on customers_orders_joined.customer_zip_code = geolocation.geolocation_zip_code

)

select * from order_customers_combined