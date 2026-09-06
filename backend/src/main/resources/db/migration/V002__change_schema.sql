-- The assignment creates a NEW, empty database before these migrations.
-- Refuse to drop legacy tables if this precondition is not met.
DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.product)
 OR EXISTS (SELECT 1 FROM public.product_info)
 OR EXISTS (SELECT 1 FROM public.orders)
 OR EXISTS (SELECT 1 FROM public.orders_date)
 OR EXISTS (SELECT 1 FROM public.order_product) THEN
  RAISE EXCEPTION 'V002 requires an empty training store database; do not apply to store_default';
 END IF;
END;
$$;
ALTER TABLE public.product ADD COLUMN price double precision;
ALTER TABLE public.product ADD CONSTRAINT product_pkey PRIMARY KEY(id);
ALTER TABLE public.orders ADD COLUMN date_created date DEFAULT CURRENT_DATE;
ALTER TABLE public.orders ADD CONSTRAINT orders_pkey PRIMARY KEY(id);
ALTER TABLE public.order_product ADD CONSTRAINT order_product_order_id_fkey
 FOREIGN KEY(order_id) REFERENCES public.orders(id);
ALTER TABLE public.order_product ADD CONSTRAINT order_product_product_id_fkey
 FOREIGN KEY(product_id) REFERENCES public.product(id);
DROP TABLE public.product_info;
DROP TABLE public.orders_date;
-- double precision is retained to match the course's required schema.
-- A real financial model normally uses a deliberate exact-money representation.

