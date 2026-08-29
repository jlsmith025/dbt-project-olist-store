with customers as (

    select
        customer_unique_id,
        order_customer_id
    from 
        {{ ref('stg__customers') }}

),

completed_orders as (

    select
        order_id,
        order_customer_id
    from 
        {{ ref('stg__orders') }}
    where 
        order_status in ('shipped', 'delivered')

),

order_items as (

    select
        order_id,
        price
    from 
        {{ ref('stg__order_items') }}
    
),

customer_completed_orders_items_joined as (

    select
        customers.customer_unique_id,
        count(distinct completed_orders.order_id) as total_completed_orders,
        ifnull(sum(completed_order_items.price), 0) as lifetime_completed_order_revenue

    from 
        customers
        left join completed_orders on customers.order_customer_id = completed_orders.order_customer_id
        left join order_items completed_order_items on completed_orders.order_id = completed_order_items.order_id

    group by
        customers.customer_unique_id

)

select * from customer_completed_orders_items_joined