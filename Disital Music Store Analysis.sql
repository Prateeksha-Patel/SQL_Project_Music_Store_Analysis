
#Q1: Who is the senior most employee based on job title?

select * from employee 
order by levels desc
limit 1

#Q2: Which countries have the most Invoices?

select count(*) as c, billing_country
from invoice
group by billing_country
order by c desc 

#Q3: What are top 3 values of total invoice?

select total from invoice
order by total desc
limit 3

#Q4: Which city has the best customers? We would like to throw a promotional
Music Festival in the city we made the most money. Write a query that returns
one city that has the highest sum of invoice tables. Return both the city name & 
sum of all invoice table.

select sum(total) as invoice_table, billing_city
from invoice
group by billing_city
order by invoice_table desc

#Q5: Who is the best customer? The customer who has the spent more money will be 
declared the best customer. Write a query that returns yhe person who has 
spent the most money.

select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total
from customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total DESC 
limit 1

#Q6: Write query to return the email, first name, last name, $ Genre of all Rock Music 
listners. Return your list ordered alphabatically by email starting with A.

select DISTINCT email, first_name, last_name
from customer
JOIN invoice ON customer.customer_id= invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
  SELECT track_id from track
  JOIN genre ON track.genre_id = genre.genre_id
  WHERE genre.name LIKE 'Rock'
)
ORDER BY email

#Q7: Lets invite the artist who has written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10
rock bands.

select artist.artist_id, artist.name, COUNT(artist.artist_id) as number_of_songs
from track
JOIN album On album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10

#Q8: Return all the track names that have a song length longer than
the average song length. Return the name asnd milliseconds for each 
track. Order by the song length with the longest songs listed first.

select name, milliseconds
from track
where milliseconds > (
  select AVG(milliseconds) as avg_track_length
  from track
)
ORDER BY milliseconds DESC

#Q9: Find how much amout spent by each customer on artists? Write 
a query to return customer name< artist name and total spent.

WITH best_selling_artist AS(
  select artist.artist_id AS artist_id, artist.name as artist_name,
  sum(invoice_line.unit_price*invoice_line.quantity) AS total_sales
  from invoice_line
  JOIN track ON track.track_id = invoice_line.track_id
  JOIN album ON album.album_id = track.album_id
  JOIN artist ON artist.artist_id = album.artist_id
  GROUP BY 1 
  ORDER BY 3 DESC
  LIMIT 1
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
sum(il.unit_price*il.quantity) AS amount_spent
from invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC


#Q10: We want to find out te most popular music Genre for each country.
We determine the most popular genre as the genre with the highest amount of purchases.
Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all genre.

with popular_genre AS(
  select count(invoice_line.quantity) as purchases, customer.country,genre.name, genre.genre_id,
  ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity)DESC) AS RowNo
  from invoice_line
  JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
  JOIN customer ON customer.customer_id = invoice.customer_id
  JOIN track ON track.track_id = invoice_line.track_id
  JOIN genre ON genre.genre_id = track.genre_id
  GROUP BY 2,3,4
  ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

#Q11: Write a query that determines the customer that has spent the most on music for 
each country. Write a query that returns the country alog with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all customers
who spent the amount. 

with recursive
  customer_with_country AS (
     select customer.customer_id, first_name, last_name, billing_country,
	 SUM(total) AS total_spending
	 from invoice
	 JOIN customer ON customer.customer_id = invoice.customer_id
	 GROUP BY 1,2,3,4
	 order by 2,3 desc
  ),
  country_max_spending AS(
     select billing_country, MAX(total_spending) AS max_spending
	 from customer_with_country
	 GROUP BY billing_country
  )
select cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
from customer_with_country cc
JOIN country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
ORDER BY 1