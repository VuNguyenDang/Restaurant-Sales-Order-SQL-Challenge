---- Question 1: What is the total amount each customer spent at the restaurant?

select
	s.customer_id
    , sum(m.price) as total_amount
from
	dannys_diner.sales as s
    join dannys_diner.menu as m
    on s.product_id = m.product_id
group by
	s.customer_id

---- Question 2: How many days has each customer visited the restaurant?

select
	customer_id
    , count(distinct order_date) as num_of_days_visited
from
	dannys_diner.sales 
group by
	customer_id

---- Question 3: What was the first item from the menu purchased by each customer?

with X as
(select
 	customer_id
 	, min(order_date) as first_date
 from
 	dannys_diner.sales
 group by
 	customer_id
 )
select
	X.customer_id
    , m.product_name
from X
	join dannys_diner.sales as s
    on s.customer_id = X.customer_id
    and s.order_date = X.first_date
    join dannys_diner.menu as m
	on m.product_id = s.product_id

---- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

with X as
(select
	m.product_name
	, count(s.product_id) as counts
from
	dannys_diner.sales as s
    join dannys_diner.menu as m
    on s.product_id = m.product_id
group by
	m.product_name)
select
	*
from X
order by
	counts desc
limit 1

---- Question 5: Which item was the most popular for each customer?

with X as
(select
 	s.customer_id
 	, count(m.product_name) as num_of_order
 	, m.product_name
 from
 	dannys_diner.sales as s
 	join dannys_diner.menu as m
 	on s.product_id = m.product_id
 group by
 	s.customer_id
 	, m.product_name),
 Y as
 (select
 	X.*
    , rank () over (partition by customer_id order by num_of_order desc) as ranks
from X)
select
	customer_id
    , product_name
    , num_of_order
from Y
where 
	ranks = 1
 
---- Question 6: Which item was purchased first by the customer after they became a member?

with X as
(select
	s.customer_id
    , min(s.order_date) as member_day
from 
	dannys_diner.sales as s
    join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
    and ( s.order_date - mem.join_date) >= 0
group by
    s.customer_id)
select
	X.*
    , m.product_name
from X
	join dannys_diner.sales as s
    on X.customer_id = s.customer_id
    and X.member_day = s.order_date
    join dannys_diner.menu as m
	on s.product_id = m.product_id
	
---- Question 7: Which item was purchased just before the customer became a member?

with X as
(select
	s.customer_id
    , max(s.order_date) as member_day
from 
	dannys_diner.sales as s
    join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
    and ( s.order_date - mem.join_date) < 0
group by
    s.customer_id
union all
select 
	s.customer_id
    , max(s.order_date)
from 
	dannys_diner.sales as s
    left join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
 where
 	mem.customer_id is null
 group by
 	s.customer_id)
select
	X.*
    , m.product_name
from X
	join dannys_diner.sales as s
    on X.customer_id = s.customer_id
    and X.member_day = s.order_date
    join dannys_diner.menu as m
	on s.product_id = m.product_id

---- Question 8: What is the total items and amount spent for each member before they became a member?

with X as
(select
	s.customer_id
    , s.product_id 
from 
	dannys_diner.sales as s
    join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
    and ( s.order_date - mem.join_date) < 0
union all
select 
	s.customer_id
    , s.product_id
from 
	dannys_diner.sales as s
    left join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
 where
 	mem.customer_id is null)
select
 	X.customer_id
    , count(X.product_id) as total_items
    , sum(m.price) as total_amount
from X
 	join dannys_diner.menu as m
    on m.product_id = X.product_id
group by
	X.customer_id
    

| customer_id | total_items | total_amount |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |
| C           | 3           | 36           |


---- Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with X as
(select
	s.customer_id
	, case
    	when m.product_name = 'sushi' then 20*m.price
        else 10*m.price
      end as point
from
	dannys_diner.sales as s
    join dannys_diner.menu as m
    on s.product_id = m.product_id)
select
	customer_id
    , sum(point) as total_point
from X
group by
	customer_id

---- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
----not just sushi - how many points do customer A and B have at the end of January?

with X as
(select
 	s.customer_id
 	, case
    	when m.product_name = 'sushi' then 20*m.price
        else 10*m.price
      end as point
from 
	dannys_diner.sales as s
    join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
    and ( s.order_date - mem.join_date) < 0
 	join dannys_diner.menu as m
 	on m.product_id = s.product_id
where 
 	(s.order_date - '2021-01-31') <= 0
union all
select
 	s.customer_id
 	, 20*m.price as point
from 
	dannys_diner.sales as s
    join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
    and ( s.order_date - mem.join_date) > 0
 	join dannys_diner.menu as m
 	on m.product_id = s.product_id
where 
 	(s.order_date - '2021-01-31') > 0
)
select
	customer_id
    , sum(point) as total_point
from X
group by
	customer_id

---- Bonus question: 

select
	s.customer_id
    , s.order_date
    , m.product_name
    , m.price
    , case
    	when mem.join_date is null then 'N'
    	when s.order_date - mem.join_date < 0 then 'N'
        else 'Y'
      end as member
from 
	dannys_diner.sales as s
    left join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
 	join dannys_diner.menu as m
 	on m.product_id = s.product_id
order by 
	customer_id
    , order_date 



---- Bonus question:


with X as
(select
	s.customer_id
    , s.order_date
    , m.product_name
    , m.price
    , 'Y' as member
	, rank() over (partition by s.customer_id order by s.order_date asc) as ranking
from 
	dannys_diner.sales as s
    join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
 	and s.order_date - mem.join_date >= 0
 	join dannys_diner.menu as m
 	on m.product_id = s.product_id
union all
select
	s.customer_id
    , s.order_date
    , m.product_name
    , m.price
    , 'N' as member
	, null as ranking
from 
	dannys_diner.sales as s
    left join dannys_diner.members as mem
    on s.customer_id = mem.customer_id
 	join dannys_diner.menu as m
 	on m.product_id = s.product_id
where 
	mem.join_date is null
	or s.order_date - mem.join_date < 0
)
select
	*
from X
order by
	customer_id
    , order_date