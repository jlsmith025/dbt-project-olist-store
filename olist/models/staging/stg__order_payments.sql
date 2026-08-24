with order_payments as (

    select * from {{ source('olist', 'order_payments') }}

),

renamed as (

    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value as payment_amount
    from
        order_payments
)

select
    *
from
    renamed