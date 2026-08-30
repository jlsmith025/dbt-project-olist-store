with order_items as (

    select * from {{ source('olist', 'order_items') }}

),

renamed as (

    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    from
        order_items

)

select
    *
from
    renamed