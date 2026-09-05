select
    order_customer.customer_city,
    order_customer.customer_state,
    order_customer.customer_zip_code,
    order_payment.order_id,
    order_payment.payment_sequence,
    order_payment.payment_type,
    order_payment.payment_installments,
    order_payment.order_purchase_date,
    order_payment.order_purchase_at,
    order_payment.order_status,
    order_payment.is_split_payment,
    order_payment.has_multiple_installments,
    order_payment.payment_amount
from
    analytics.olist_mart.fact_order_payment order_payment
    inner join analytics.olist_mart.dim_order_customer order_customer
        on order_payment.order_customer_key = order_customer.order_customer_key
;