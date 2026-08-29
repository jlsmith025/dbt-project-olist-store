with product as (

    select * from {{ ref('stg__products') }}

),

product_name_translation as (

    select 
        product_category_name as base_product_category_name,
        array_to_string(
                transform(
                    split(
                        lower(
                            replace(product_category_name, '_', ' ')
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
        ) as product_category_name,
        array_to_string(
                transform(
                    split(
                        lower(
                            replace(product_category_name_english, '_', ' ')
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
        ) as product_category_name_english
    from {{ ref('stg__product_category_name_translation') }}

),

product_joined as (

    select
        md5(product.product_id) as product_key,
        
        product.product_id,
        product_name_translation.product_category_name,
        product_name_translation.product_category_name_english,
        
        product.product_photos_qty as product_photo_count,
        product.product_weight_g,
        product.product_length_cm,
        product.product_height_cm,
        product.product_width_cm
    from
        product
        inner join product_name_translation on product.product_category_name = product_name_translation.base_product_category_name

)

select * from product_joined