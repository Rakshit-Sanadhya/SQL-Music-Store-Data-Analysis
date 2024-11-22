--Basic queries

/* Q1: who is the senior most employee based on the job title */
select * from employee
order by levels desc


/* Q2: Which countries have the most Invoices? */

select billing_city, sum(total) as total_sum from invoice
group by billing_city
order by total_sum desc


/* Q3: What are top 3 values of total invoice? */

SELECT total 
FROM invoice
ORDER BY total DESC


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals. */

SELECT billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;


/* Q5: Who is the best customer? The customer who has spent the most money will be
declared the best customer. Write a query that returns the person who has spent the
most money. */

select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total from customer
left join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total desc
limit 1


--Moderate queies

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Musc
listeners. Return your list ordered alphabetically by email starting with A. */

from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id IN(
	select track_id from track
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
)
order by email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. Write a
query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT artist.artist_id, artist.name, COUNT(track.track_id) AS count
FROM track
LEFT JOIN album ON track.album_id = album.album_id
LEFT JOIN artist ON album.artist_id = artist.artist_id
LEFT JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name = 'Rock'
GROUP BY artist.artist_id, artist.name
order by count desc
limit 10


/* Q3: Return all the track names that have a song length longer than the average song length.
Return the Name and Milliseconds for each track. Order by the song length with the
longest songs listed first. */

select name, milliseconds, AVG(milliseconds) as avg from track
where milliseconds = avg
order by milliseconds desc

SELECT name, milliseconds, avg_milliseconds
FROM track,
     (SELECT AVG(milliseconds) AS avg_milliseconds FROM track) AS avg_table
WHERE milliseconds > avg_milliseconds
ORDER BY milliseconds DESC;


--Complex queries

/* Q1: Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent. */

WITH best_selling_artist as (
	SELECT artist.artist_id as artist_id, artist.name as artist_name,
		SUM(invoice_line.unit_price * invoice_line.quantity) as total_sales
	from invoice_line 
	join track on invoice_line.track_id = track.track_id
	join album on track.album_id = album.album_id
	join artist on album.artist_id = artist.artist_id
	group by 1
	order by 3 desc
	limit 2
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
	SUM(il.unit_price*il.quantity) as amount_spent
from invoice i
join customer c on i.customer_id = c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on  t.track_id = il.track_id
join album al on al.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = al.artist_id
group by 1, 2, 3, 4
order by 5 desc;


/* Q2: We want to find out the most popular music Genre for each country. We determine the
most popular genre as the genre with the highest amount of purchases. Write a query
that returns each country along with the top Genre. For countries where the maximum
number of purchases is shared return all Genres with. */

with popular_genre as(
	select 
		c.country as country, 
		g.name as genre_name, 
		count(il.quantity) as amount_sales,
		ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY count(il.quantity) DESC) AS Row_no 
	from invoice i
	join customer c on i.customer_id = c.customer_id
	join invoice_line il on il.invoice_id = i.invoice_id
	join track t on  t.track_id = il.track_id
	join genre g on g.genre_id = t.genre_id
	group by 1, 2
	order by country
)
select country, genre_name, amount_sales from popular_genre
where Row_no = 1;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

with customer_with_country as (
	select c.first_name, c.last_name, c.country, sum(i.total) as total,
		ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY sum(i.total) DESC) AS Row_no 
	from invoice i 
	join customer c on i.customer_id = c.customer_id
	group by 1, 2, 3
	order by 3 asc, 4 desc
)
select first_name, last_name, country, total from customer_with_country cc
where Row_no = 1;
