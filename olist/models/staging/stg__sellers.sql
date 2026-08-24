with sellers as (

    select * from {{ source('olist', 'sellers') }}

),

renamed as (

    select 
        seller_id,
        seller_zip_code_prefix as seller_zip_code,
        seller_city,
        seller_state,
        seller_name
    from 
        sellers

)

select 
    * 
from 
    renamed