with geolocation as (

    select * from {{ ref('int__geolocation_flattened') }}

),

sellers as (

    select 
        seller_id,
        seller_name,
        array_to_string(
                transform(
                    split(
                        lower(
                            replace(seller_city, '_', ' ')
                        ), ' '
                    ),
                    word ->
                        iff(
                            /* Leave appropriate Portuguese words lowercase */
                            word in ('de', 'dos', 'da', 'do', 'e'),
                            word,
                            initcap(word)
                        )
                ),
                ' '
        ) as seller_city,
        seller_state,
        seller_zip_code
    from {{ ref('stg__sellers') }}

),

sellers_joined as (

    select
        md5(sellers.seller_id) as seller_key,
        
        sellers.seller_id,
        sellers.seller_name,
        sellers.seller_city,
        sellers.seller_state,
        sellers.seller_zip_code,
        
        geolocation.geolocation_latitude as seller_latitude,
        geolocation.geolocation_longitude as seller_longitude
    from
        sellers
        left outer join geolocation on sellers.seller_zip_code = geolocation.geolocation_zip_code

)

select * from sellers_joined