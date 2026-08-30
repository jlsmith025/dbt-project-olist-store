with payments as (
    
    select * from {{ ref('stg__order_payments') }}

),

order_customer as (
    
    select 
        order_customer_id,
        order_id,
        customer_unique_id,
    from 
        {{ ref('dim_order_customer') }}

),

orders as (

    select
        order_id,
        order_status,
        order_purchase_timestamp
    from
        {{ ref('stg__orders') }}

),

final as (
    
    select
        -- primary key
        md5(payments.order_id || payments.payment_sequential) as order_payment_key,
        
        -- surrogate keys
        md5(order_customer.order_customer_id) as order_customer_key,
        md5(order_customer.customer_unique_id) as customer_unique_key,
        
        -- natural keys
        payments.order_id,
        payments.payment_sequential as payment_sequence,
        
       -- degenerate dimensions
        initcap(replace(payments.payment_type, '_', ' ')) as payment_type,
        payments.payment_installments,
        to_date(orders.order_purchase_timestamp) as order_purchase_date,
        to_time(orders.order_purchase_timestamp) as order_purchase_at,
        initcap(orders.order_status) as order_status,

        -- flag for split-payment analysis
        case when count(*) over (partition by payments.order_id) > 1
            then true else false
        end as is_split_payment,
        -- flag for payments with multiple installments
        case when payments.payment_installments > 1
            then true else false
        end as has_multiple_installments,

        -- measures
        payments.payment_amount,

    from 
        payments
        left join order_customer on payments.order_id = order_customer.order_id
        left join orders on payments.order_id = orders.order_id

)

select * from final