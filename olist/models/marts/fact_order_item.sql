with order_items as (

    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    from 
        {{ ref('stg__order_items') }}

),

orders as (

    select
        order_id,
        order_customer_id,
        order_status,
        order_purchase_timestamp

    from 
        {{ ref('stg__orders') }}

),

customers as (

    select
        order_customer_id,
        customer_unique_id

    from 
        {{ ref('stg__customers') }}

),

customers_orders_joined as (

    select
        orders.order_id,
        orders.order_customer_id,
        customers.customer_unique_id,
        orders.order_status,
        orders.order_purchase_timestamp

    from orders
    left join customers on orders.order_customer_id = customers.order_customer_id

),

joined as (

    select
        order_items.order_id,
        order_items.order_item_id,
        order_items.product_id,
        order_items.seller_id,
        order_items.shipping_limit_date,
        order_items.price,
        order_items.freight_value,
        customers_orders_joined.order_status,
        customers_orders_joined.order_purchase_timestamp,
        customer_unique_id,
        order_customer_id
    from 
        order_items
        left join customers_orders_joined on order_items.order_id = customers_orders_joined.order_id

),

final as (

    select
        -- primary key
        md5(order_id || order_item_id) as order_item_key,

        -- foreign keys
        md5(customer_unique_id) as customer_unique_key,
        md5(order_customer_id) as order_customer_key,
        md5(product_id) as product_key,
        md5(seller_id) as seller_key,
        
        to_number(
            to_char(order_purchase_timestamp, 'YYYYMMDD')
        ) as order_purchase_date_key,
        to_time(order_purchase_timestamp) as order_purchase_at,

        to_number(
            to_char(shipping_limit_date, 'YYYYMMDD')
        ) as shipping_limit_date_key,
        to_time(shipping_limit_date) as shipping_limit_at,

        -- natural keys
        order_id,
        product_id,
        seller_id,
        customer_unique_id,
        order_customer_id,

        -- degenerate dimensions
        order_item_id as order_item_line_number,
        order_status,

        -- measures
        price as item_price,
        freight_value as item_freight_fee,
        price + freight_value as item_revenue,
        1 as item_count

    from joined

)

select * from final