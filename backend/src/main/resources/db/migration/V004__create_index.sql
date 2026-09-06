-- First key narrows the calendar week; id covers the subsequent join.
CREATE INDEX orders_date_created_id_idx ON public.orders(date_created,id);
-- Foreign keys do not automatically create indexes on referencing columns.
CREATE INDEX order_product_order_id_idx ON public.order_product(order_id) INCLUDE(quantity);
CREATE INDEX order_product_product_id_idx ON public.order_product(product_id);
ANALYZE public.orders;
ANALYZE public.order_product;

