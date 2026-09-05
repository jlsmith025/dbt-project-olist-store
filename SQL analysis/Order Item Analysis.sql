select
    customer.total_completed_orders,
    customer.lifetime_completed_order_revenue,
    purchase_date.date_day as purchase_date,
    order_item.order_purchase_at,
    shipping_limit_date.date_day as shipping_limit_date,
    order_item.shipping_limit_at,
    order_item.customer_unique_id,
    order_item.order_customer_id,
    order_item.order_item_line_number,
    order_item.order_status,
    order_item.item_price,
    order_item.item_freight_fee,
    order_item.item_revenue,
    order_item.item_count,
    seller.seller_name as item_seller_name,
    seller.seller_city as item_seller_city,
    seller.seller_state as item_seller_state,
    product.product_category_name as item_product_category,
    product.product_weight_g as item_product_weight_grams
from
    analytics.olist_mart.fact_order_item order_item
    inner join analytics.olist_mart.dim_date purchase_date
        on order_item.order_purchase_date_key = purchase_date.date_key
    inner join analytics.olist_mart.dim_date shipping_limit_date
        on order_item.shipping_limit_date_key = shipping_limit_date.date_key
    inner join analytics.olist_mart.dim_customer customer
        on order_item.customer_unique_key = customer.customer_unique_key
    inner join analytics.olist_mart.dim_seller seller
        on order_item.seller_key = seller.seller_key
    inner join analytics.olist_mart.dim_product product
        on order_item.product_key = product.product_key
;