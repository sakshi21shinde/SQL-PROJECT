-- swiggy food delivery Analysis - sql 

-- topics: ddl, dml, dql, joins, window functions, subqueries, views.

-- ================= setup: tables + data  =================


create database swiggy_db;
use swiggy_db;

create table customers (
    customer_id int primary key,
    name        varchar(50),
    city        varchar(30),
    signup_date date,
    membership  varchar(10)
);

create table restaurants (
    restaurant_id int primary key,
    name          varchar(50),
    cuisine       varchar(30),
    city          varchar(30),
    rating        numeric(2,1)
);

create table delivery_partners (
    partner_id  int primary key,
    name        varchar(50),
    city        varchar(30),
    vehicle     varchar(20),
    joined_date date
);

create table orders (
    order_id          int primary key,
    customer_id       int,
    restaurant_id     int,
    partner_id        int,
    order_date        date,
    order_amount      numeric(8,2),
    delivery_time_min int,
    status            varchar(15),
    rating            int
);

create table payments (
    payment_id int primary key,
    order_id   int,
    method     varchar(10),
    pay_status varchar(10)
);

insert into customers values
(1,'rahul sharma','pune','2024-01-10','one'),
(2,'priya patil','mumbai','2024-02-15','none'),
(3,'amit verma','pune','2024-03-20','one'),
(4,'sneha kulkarni','bengaluru','2024-04-05','none'),
(5,'rohan mehta','mumbai','2024-05-12','one'),
(6,'neha singh','pune','2024-06-18','none');

select * from customers;

insert into restaurants values
(101,'biryani house','hyderabadi','pune',4.5),
(102,'pizza palace','italian','mumbai',4.1),
(103,'dosa corner','south indian','pune',4.3),
(104,'burger hub','fast food','bengaluru',3.9),
(105,'sweet tooth','desserts','mumbai',4.6);

select * from restaurants;

insert into delivery_partners values
(201,'ramesh','pune','bike','2023-05-01'),
(202,'suresh','mumbai','bike','2023-07-15'),
(203,'anil','pune','scooter','2023-09-10'),
(204,'vijay','bengaluru','bike','2024-01-20'),
(205,'manoj','mumbai','ev','2024-02-25');

select * from delivery_partners;

insert into orders values
(1001,1,101,201,'2024-07-01',450,30,'delivered',5),
(1002,1,103,203,'2024-07-05',220,25,'delivered',4),
(1003,2,102,202,'2024-07-06',680,45,'delivered',3),
(1004,3,101,201,'2024-07-10',900,35,'delivered',5),
(1005,4,104,204,'2024-07-12',310,50,'delivered',2),
(1006,5,102,205,'2024-07-15',520,null,'cancelled',null),
(1007,1,101,203,'2024-07-20',380,28,'delivered',4);

select * from orders;

insert into payments values
(1,1001,'upi','paid'),
(2,1002,'card','paid'),
(3,1003,'cash','paid'),
(4,1004,'upi','paid'),
(5,1005,'card','paid'),
(6,1007,'upi','paid');

select * from payments;
use swiggy_db;

alter table orders add constraint fk_orders_customer
    foreign key (customer_id) references customers(customer_id);

alter table orders add constraint fk_orders_restaurant
    foreign key (restaurant_id) references restaurants(restaurant_id);

alter table orders add constraint fk_orders_partner
    foreign key (partner_id) references delivery_partners(partner_id);

alter table payments add constraint fk_payments_order
    foreign key (order_id) references orders(order_id);
    


-- ======================= section 1 : ddl =======================

-- q1. create a table delivery_feedback with feedback_id (primary key),
--     order_id (foreign key to orders), food_rating (only 1 to 5) and comments.
create table delivery_feedback (
    feedback_id int primary key,
    order_id    int ,
    food_rating int check (food_rating between 1 and 5),
    comments    varchar(100)
);

select * from delivery_feedback;
alter table delivery_feedback add constraint fk_feedback_order
foreign key (order_id) references orders(order_id);

-- q2. add a column tip_amount (default 0) to the orders table.
alter table orders add column tip_amount numeric(6,2) default 0;

-- q3. the swiggy team wants to make sure no order can be saved with a zero or negative
--     amount. add a rule on the orders table so that order_amount is always more than 0.
--     name the rule chk_order_amount.

alter table orders add constraint chk_order_amount check (order_amount > 0);

insert into orders values (1008,1,101,201,'2024-07-25',-100,30,'delivered',5);
-- error: new row violates check constraint "chk_order_amount"



-- ======================= section 2 : dml =======================


-- q4. insert a new customer: 7, kiran rao, mumbai, 2024-07-01, none.
begin;
insert into customers values (7,'kiran rao','mumbai','2024-07-01','none');
rollback;

-- q5. change the membership of neha singh to 'one'.
begin;
update customers set membership = 'one' where name = 'neha singh';
rollback;

-- q6. delete all cancelled orders.
begin;
delete from orders where status = 'cancelled';
rollback;


-- ======================= section 3 : dql =======================

-- q7. show delivered orders with amount more than 400, highest amount first.
select order_id, order_amount from orders
where status = 'delivered' and order_amount > 400
order by order_amount desc;
-- 1004 900 | 1003 680 | 1001 450

-- q8. find number of orders and total amount for each status.
select status, count(*) as total_orders, sum(order_amount) as total_amount from orders
group by status;
-- delivered 6 2940 | cancelled 1 520

-- q9. list pune restaurants having rating 4.3 or more.
select name, rating from restaurants
where city = 'pune' and rating >= 4.3;
-- biryani house 4.5 | dosa corner 4.3


-- ======================= section 4 : joins =======================

-- q10. show order_id, customer name and restaurant name for all delivered orders.
select o.order_id, c.name as customer_name, r.name as restaurant_name
from orders o
inner join customers c on c.customer_id = o.customer_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
where o.status = 'delivered';
-- 1001 rahul sharma biryani house | 1002 rahul sharma dosa corner
-- 1003 priya patil pizza palace   | 1004 amit verma biryani house
-- 1005 sneha kulkarni burger hub  | 1007 rahul sharma biryani house

-- q11. find customers who have never placed an order.
select c.name
from customers c
left join orders o on o.customer_id = c.customer_id
where o.order_id is null;
-- neha singh

-- q12. List all restaurants with the number of orders they got, including restaurants with no orders.
select r.name, count(o.order_id) as total_orders
from orders o
right join restaurants r on r.restaurant_id = o.restaurant_id
group by r.restaurant_id, r.name;
-- biryani house 3 | pizza palace 2 | dosa corner 1 | burger hub 1 | sweet tooth 0




-- ================== section 5 : window functions ==================

-- q13. Number all orders from the highest amount to the lowest.

select order_id, order_amount,
row_number() over (order by order_amount desc) as row_no
from orders;


-- q14. Rank restaurants by rating (highest = rank 1).

select name, rating,
rank() over (order by rating desc) as rating_rank
from restaurants;

-- q15 Show rank and dense_rank for delivered orders by customer rating.

select order_id, rating,
rank()       over (order by rating desc) as rnk,
dense_rank() over (order by rating desc) as dense_rnk
from orders
where status = 'delivered';


-- ===================== section 6 : subqueries =====================

-- q16. find delivered orders whose amount is more than the average delivered order amount.
select order_id, order_amount from orders
where status = 'delivered'
and order_amount > (select avg(order_amount) from orders where status = 'delivered');
-- average = 490 -> 1003 680 | 1004 900

-- q17 Find the restaurants whose rating is higher than the average rating of all restaurants.


select name, rating from restaurants
where rating > (select avg(rating) from restaurants);


-- ======================== section 7 : views ========================

-- q19. create a view delivered_orders_view (order_id, customer_name, restaurant_name,
--      order_amount) for delivered orders, then show rows with amount more than 400.
create or replace view delivered_orders_view as
select o.order_id, c.name as customer_name, r.name as restaurant_name, o.order_amount
from orders o
join customers c on c.customer_id = o.customer_id
join restaurants r on r.restaurant_id = o.restaurant_id
where o.status = 'delivered';
select * from delivered_orders_view where order_amount > 400;

-- 1001 rahul sharma biryani house 450 | 1003 priya patil pizza palace 680
-- 1004 amit verma biryani house 900

-- q20. create a view restaurant_revenue (restaurant name, delivered orders, total revenue),
--      show the top 2 restaurants by revenue, then drop the view.
create or replace view restaurant_revenue as
select r.name, count(o.order_id) as delivered_orders, sum(o.order_amount) as total_revenue
from restaurants r
join orders o on o.restaurant_id = r.restaurant_id
where o.status = 'delivered'
group by r.restaurant_id, r.name;

select * from restaurant_revenue order by total_revenue desc limit 2;
-- biryani house 3 1730 | pizza palace 1 680

drop view restaurant_revenue;
