with customers as (

    select * from {{ source('olist', 'customers') }}

),

renamed as (

    select 
        customer_id as order_customer_id,
        customer_unique_id customer_id,
        customer_zip_code_prefix as customer_zip_code,
        customer_city,
        customer_state
    from 
        customers

)

select 
    * 
from 
    renamed