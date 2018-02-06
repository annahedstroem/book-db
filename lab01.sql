
/* LAB 1 */

/*  1. List all countries that do not have any islands. */

/* INPUT: */

SELECT Name 
FROM Country 
WHERE Country.code 
NOT IN (SELECT geo_Island.Country FROM geo_Island);

/* ANSWER:

           name           
--------------------------
 Albania
 Macedon
 ...
 Mozambique
 Swaziland
(120 rows)
*/

/* 2. Generate the ratio between inland provinces (provinces not bordering any sea) to total
number of provinces. */

/* INPUT: */

SELECT (1.0 *
(SELECT COUNT(Province) 
FROM (SELECT DISTINCT Province FROM geo_Sea) 
AS temp) / 
(SELECT COUNT (Country) 
FROM Province))
AS temp2;

/* OUTPUT:

         temp2          
------------------------
0.44375388440024860162
(1 row)
*/
 

/* 3. Generate a table of all the continents and the sum of the areas of all those lakes that contain
at least one island for each continent. If a lake is in a country that is situated on several
continents, the appropriate share of the lake area should be counted for each of those
continents. */

/* INPUT: */

SELECT list.cont, SUM(list.a*(list.per/100)) 
FROM (SELECT DISTINCT ON (islandIn.Lake, cont) islandIn.Lake, 
encompasses.continent AS cont,
encompasses.percentage AS per, 
Lake.Area AS a
FROM islandIn 
INNER JOIN geo_Lake on islandIn.Lake = geo_Lake.Lake
INNER JOIN encompasses on encompasses.country = geo_Lake.country
INNER JOIN Lake on islandIn.Lake =Lake.Name) 
AS list GROUP BY list.cont;
        



/* OUTPUT:

       cont        |             sum             
-------------------+-----------------------------
 Europe            |   7875.50000000000000000000
 Australia/Oceania |    242.66000000000000000000
 Africa            |  68870.00000000000000000000
 America           | 78907.700000000000000000000
 Asia              | 24721.340000000000000000000
(5 rows)

*/


/*  4. Generate a table with the two continents that will have the largest and the smallest
population increase fifty years from now given current population and growth rates, and the
future population to current population ratios for these two continents. */

/* 5. Generate the name of the organisation that is headquartered in Europe, has International in
its name and has the largest number of European member countries. */

/* 6. Generate a table of city names and related airport names for all the cities that have at least
100,000 inhabitants, are situated in America and where the airport is elevated above 500 m. */

/* 7. Generate a table of countries and the ratio between their latest reported and earliest
reported population figures, rounded to one decimal point, for those countries where this ratio
is above 10, that is to say those that have grown at least 10-fold between earliest and latest
population count. */

/* 8. Generate a table with the three (3) cities above 5,000,000 inhabitants that form the largest
triangle between them, measured as the total length of all three triangle legs, and that total
length. Your solution should be on the output form:
 Name 1 | Name 2 | Name 3 | TotDist
------------------------------------------------------
 Bagginsville | Mordor City | Minas Tirith | 1234567.2
You are allowed to treat the world as a Mercator projection for purposes of calculating
distances, that is, to use the distance formulas for a plane, but you must consider that the
north/south edges and the east/west edges, respectively, meet and handle that. Any solution
that counts two cities just on each side of the date line as a world apart, for instance, is wrong
and will not be admitted. Your solution is allowed to contain duplicate rows of the same
cities. Hint 1: Filter out the cities matching the condition first! Hint 2: Solve the simpler
problem of calculating the two cities furthest apart under the above conditions first. */

/* 9. Generate a table that contains the rivers Rhein, Nile and Amazonas, and the longest total
length that the river systems feeding into each of them contain (including their own
respective length). You must calculate the respective river systems of tributary rivers
recursively. 
*/
