select
    order_customer.customer_unique_id,
    order_customer.customer_city,
    order_customer.customer_state,
    order_customer.customer_latitude,
    order_customer.customer_longitude,
    order_customer.is_customers_first_order,
    order_customer.is_customers_latest_order,
    order_customer.customer_order_sequence_number,
    order_lifecycle.order_id,
    order_lifecycle.order_status,
    purchase_date.date_day as purchase_date,
    order_lifecycle.order_purchase_at,
    approved_date.date_day as approved_date,
    order_lifecycle.order_approved_at,
    carrier_handoff_date.date_day as order_carrier_handoff_date,
    order_lifecycle.order_carrier_handoff_at,
    order_delivered_date.date_day as order_delivered_date,
    order_lifecycle.order_delivered_at,
    order_estimated_delivery_date.date_day as order_estimated_delivery_date,
    order_lifecycle.approval_duration_minutes,
    order_lifecycle.purchase_to_carrier_handoff_duration_hours,
    order_lifecycle.purchase_to_delivery_duration_days,
    order_lifecycle.carrier_handoff_to_delivery_duration_days,
    order_lifecycle.delivery_variance_to_estimate_days,
    order_lifecycle.days_delivered_early,
    order_lifecycle.days_delivered_late,
    order_lifecycle.delivery_performance_status,
    order_lifecycle.was_delivered_early,
    order_lifecycle.was_delivered_on_time,
    order_lifecycle.was_delivered_late,
    order_lifecycle.was_approved,
    order_lifecycle.was_handed_to_carrier,
    order_lifecycle.was_delivered,
    order_lifecycle.was_canceled,
    order_customer.*
from    
    analytics.olist_mart.fact_order_lifecycle order_lifecycle
    inner join analytics.olist_mart.dim_order_customer order_customer 
        on order_lifecycle.order_customer_key = order_customer.order_customer_key
    inner join analytics.olist_mart.dim_date purchase_date
        on order_lifecycle.order_purchase_date_key = purchase_date.date_key
    inner join analytics.olist_mart.dim_date approved_date
        on order_lifecycle.order_approved_date_key = approved_date.date_key
    inner join analytics.olist_mart.dim_date carrier_handoff_date
        on order_lifecycle.order_carrier_handoff_date_key = carrier_handoff_date.date_key
    inner join analytics.olist_mart.dim_date order_delivered_date
        on order_lifecycle.order_delivered_date_key = order_delivered_date.date_key
    inner join analytics.olist_mart.dim_date order_estimated_delivery_date
        on order_lifecycle.order_estimated_delivery_date_key = order_estimated_delivery_date.date_key
;