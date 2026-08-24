with order_items as (

    select * from {{ source('olist', 'order_items') }}

),

renamed as (

    select
        order_id,
        order_item_id as order_item_sequence,
        product_id,
        seller_id,
        shipping_limit_date as shipping_limit_timestamp,
        price,
        freight_value as freight_cost
    from
        order_items

)

select
    *
from
    renamed