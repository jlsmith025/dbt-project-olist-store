with order_reviews as (

    select * from {{ source('olist', 'order_reviews') }}

),

renamed as (

    select
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        cast(review_creation_date as date) as review_creation_date,
        review_answer_timestamp
    from
        order_reviews

)

select
    *
from
   renamed 