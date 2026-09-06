-- Full training dataset: 6 products, 10 thousand orders and order lines.
-- Flyway executes this migration in one transaction. Temporarily remove FKs
-- to avoid a large pending-trigger queue on the 2 GiB training VM.
-- Recreating validated constraints below checks every loaded row before commit.
ALTER TABLE public.order_product DROP CONSTRAINT order_product_order_id_fkey;
ALTER TABLE public.order_product DROP CONSTRAINT order_product_product_id_fkey;
INSERT INTO public.product(id,name,picture_url,price) VALUES
(1,'Сливочная','https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/6.jpg',320.00),
(2,'Особая','https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/5.jpg',179.00),
(3,'Молочная','https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/4.jpg',225.00),
(4,'Нюренбергская','https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/3.jpg',315.00),
(5,'Мюнхенская','https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/2.jpg',330.00),
(6,'Русская','https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/1.jpg',189.00);
INSERT INTO public.orders(id,status,date_created)
SELECT i, (ARRAY['pending','shipped','cancelled'])[1+floor(random()*3)::int],
 CURRENT_DATE - floor(random()*90)::int
FROM generate_series(1,10000) AS s(i);
INSERT INTO public.order_product(quantity,order_id,product_id)
SELECT 1+floor(random()*50)::int, i, 1+floor(random()*6)::int
FROM generate_series(1,10000) AS s(i);
ALTER TABLE public.order_product ADD CONSTRAINT order_product_order_id_fkey
 FOREIGN KEY(order_id) REFERENCES public.orders(id);
ALTER TABLE public.order_product ADD CONSTRAINT order_product_product_id_fkey
 FOREIGN KEY(product_id) REFERENCES public.product(id);
SELECT setval(pg_get_serial_sequence('public.product','id'),(SELECT max(id) FROM public.product),true);
SELECT setval(pg_get_serial_sequence('public.orders','id'),(SELECT max(id) FROM public.orders),true);
ANALYZE public.product;
ANALYZE public.orders;
ANALYZE public.order_product;

