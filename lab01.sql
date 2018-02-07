
/* LAB 1 */

# FRÅGA 1
# List all countries that does not have any islands
SELECT Name FROM country 
        WHERE country.Code 
        NOT IN (SELECT geo_Island.Country FROM geo_Island);
        
        
# FRÅGA 2
# Generate the ratio between inland provinces (provinces not bordering any sea) to total number of provinces.

        

# Result:  0.54......
SELECT 1.0*inland.count/alls.count as ratio 
FROM (
  SELECT COUNT(*) AS count FROM
  province WHERE province.name NOT IN (Select geo_sea.province from geo_sea)) inland,
  (SELECT COUNT(*) AS count FROM province) alls;
        
        
#FRÅGA 3        
# Generate a table of all the continents and the sum of the areas of all those lakes that containat least one 
#island for each continent. If a lake is in a country that is situated on several continents, the appropriate 
#share of the lake area should be counted for each of those continents.       
        
        
# HÄr är svaret och koden med percentage som känns väldigt rimligt.         
#       cont        |             sum             
#-------------------+-----------------------------
# Europe            |   7875.50000000000000000000
# Australia/Oceania |    242.66000000000000000000
# Africa            |  68870.00000000000000000000
# America           | 78907.700000000000000000000
# Asia              | 24721.340000000000000000000
        
SELECT list.cont, SUM(list.a*(list.per/100)) FROM (
  SELECT DISTINCT ON (islandIn.Lake, cont) islandIn.Lake, encompasses.continent AS cont,
  encompasses.percentage AS per, Lake.Area AS a
  FROM islandIn INNER JOIN geo_Lake on islandIn.Lake = geo_Lake.Lake
                INNER JOIN encompasses on encompasses.country = geo_Lake.country
                INNER JOIN Lake on islandIn.Lake =Lake.Name) 
                AS list GROUP BY list.cont;      
        
 
#FRÅGA 4        
#Generate a table with the two continents that will have the largest and the smallest population increase fifty years from now 
#given current population and growth rates, and the future population to current population ratios for these two continents.        
# CORRECT  
        
WITH join1 AS (
  SELECT encompasses.Country, encompasses.Continent, country.Population * (encompasses.percentage * 0.01) AS Population 
  FROM Country INNER JOIN encompasses ON country.Code = encompasses.Country
),
join2 AS (
  SELECT join1.*, population.population_growth
  FROM population INNER JOIN join1 ON population.country = join1.country
),
PopCalc AS (
  SELECT continent,
    sum(population) AS current_population, 
    sum(population*(POWER(1.00+population_growth/100,50))) AS future_population
  FROM join2
  GROUP BY continent  
),
RatioCalc AS (
  SELECT *, 
    future_population - current_population AS population_increase,
    future_population / current_population AS ratio
  FROM PopCalc
),
MaxMin AS (
  SELECT continent, ratio
  FROM RatioCalc
  WHERE 
    population_increase = (SELECT MAX(population_increase) FROM RatioCalc) OR
    population_increase = (SELECT MIN(population_increase) FROM RatioCalc)
)
SELECT * FROM MaxMin;

#FRÅGA 5
#Generate the name of the organisation that is headquartered in Europe, has International 
#inits name and has the largest number of European member countries. 
#                    name                    
#--------------------------------------------
# International Criminal Police Organization

WITH eu_countries AS(
  SELECT encompasses.country FROM encompasses
  WHERE encompasses.continent = 'Europe'
),
EuOrg AS (
  SELECT eu_countries.Country , Organization.Name, Organization.abbreviation FROM Organization
  INNER JOIN eu_countries ON Organization.Country = eu_countries.Country
  WHERE Organization.Name LIKE '%International%'
),
Member_countries AS (
  SELECT EuOrg.Name FROM isMember
  INNER JOIN EuOrg ON isMember.Organization = EuOrg.abbreviation
  WHERE isMember.Country IN (SELECT Country FROM eu_countries)
),
member_count AS (
  SELECT DISTINCT Member_countries.Name, count(Member_countries) AS medlemmar
  FROM Member_countries
  GROUP BY Member_countries.Name
)
SELECT Name FROM Member_count
WHERE medlemmar = (select max(medlemmar) FROM member_count);
        
#FRÅGA 6
#Generate a table of city names and related airport names for all the cities that have at least 100,000 inhabitants,
#are situated in America and where the airport is elevated above 500 m.
        
WITH AllcitiesAmerica AS(
  SELECT City.Name as Cityname, City.Population FROM City 
  INNER JOIN encompasses ON City.Country = encompasses.country
  WHERE encompasses.continent = 'America' AND City.population >= 100000
),
All_airports AS (
  SELECT AllcitiesAmerica.cityname , Airport.Name, Airport.Elevation FROM Airport 
    INNER JOIN AllcitiesAmerica ON Airport.City = AllcitiesAmerica.Cityname
    INNER JOIN encompasses ON encompasses.Country = Airport.Country
    WHERE encompasses.Continent = 'America' AND Airport.Elevation > 500
)
SELECT * FROM All_airports ORDER BY All_airports.Cityname;       

        
#FRÅGA 7
#Generate a table of countries and the ratio between their latest reported and earliest reported population figures,
#rounded to one decimal point, for those countries where this ratiois above 10, that is to say those that have grown
#at least 10-fold between earliest and latest population count.
#         name         | ratio 
#----------------------+-------
# Andorra              |  12.6
# Gibraltar            |  17.9
# Bahrain              |  13.7
# Hong Kong            |  25.0
# Jordan               |  13.9
# Kuwait               |  19.6
# United Arab Emirates | 121.3
# Philippines          |  61.5
# Qatar                |  68.0
# Cayman Islands       |  59.7
# Costa Rica           |  39.6
# Panama               |  10.1
# El Salvador          |  42.9
# Sint Maarten         |  25.0
# Australia            |  10.3
# Uruguay              |  24.9
# Botswana             |  16.9
# South Africa         |  10.0
# Djibouti             |  13.5
        
        
WITH OldestReport AS(
SELECT DISTINCT ON (CountryPops) CountryPops.Country, CountryPops.Population, t.mx
FROM (
    SELECT Country, MIN(Year) AS mx
    FROM CountryPops
    GROUP BY Country
  ) t INNER JOIN CountryPops ON CountryPops.Country = t.Country AND t.mx = CountryPops.Year
),
join1 AS (
  SELECT Country.Name, Country.Population, OldestReport.Population AS Olddata FROM Country
  INNER JOIN OldestReport ON OldestReport.Country = Country.Code
),
Calc AS (
  SELECT join1.Name, Join1.Population / join1.Olddata AS Ratio1 FROM join1
),
Structure AS (
  SELECT Calc.Name, ROUND(Ratio1,1) AS Rounded_Ratio FROM CALC
),
Final AS (
SELECT Structure.Name, Structure.Rounded_Ratio AS Ratio FROM Structure
WHERE Structure.Rounded_Ratio >= 10
)
SELECT * FROM Final;        

#Fråga 8
 WITH Citys5M AS(
   SELECT a.Name AS Name1, a.Population AS Pop1, a.Latitude AS Lat1, a.Longitude AS Long1,
          b.Name AS Name2, b.Population AS Pop2, b.Latitude AS Lat2, b.Longitude AS Long2,
          c.Name AS Name3, c.Population AS Pop3, c.Latitude AS Lat3, c.Longitude AS Long3
   FROM City a, City b, City c
   WHERE  a.Population > 5000000 AND b.Population > 5000000 AND c.Population > 5000000
 ),
 Distancecalc AS(
   SELECT Name1, Name2, Name3,Lat1,Lat2,Lat3,Long1,Long2, Long3, (6371 * 2 * ASIN(SQRT(
               POWER(SIN((Lat1 - abs(Lat2)) * pi()/180 / 2),
               2) + COS(Lat1 * Pi()/180 ) * COS(ABS(Lat2) *
               PI()/180) * POWER(SIN((Long1 - Long2) *
               PI()/180 / 2), 2) ))) AS Calc1 FROM Citys5M
 ),
 Distancecalc2 AS (
SELECT Calc1, Name1, Name2, Name3,Lat1,Lat2,Lat3,Long1,Long2, Long3,
            (6371 * 2 * ASIN(SQRT(
            POWER(SIN((Lat1 - abs(Lat3)) * pi()/180 / 2),
            2) + COS(Lat1 * Pi()/180 ) * COS(ABS(Lat3) *
            PI()/180) * POWER(SIN((Long1 - Long3) *
            PI()/180 / 2), 2) ))) AS calc2 FROM Distancecalc
),
DistanceCalc3 AS (
  SELECT Calc1, Calc2, Name1, Name2, Name3,
  (6371 * 2 * ASIN(SQRT(
              POWER(SIN((Lat2 - abs(Lat3)) * pi()/180 / 2),
              2) + COS(Lat2 * Pi()/180 ) * COS(ABS(Lat3) *
              PI()/180) * POWER(SIN((Long2 - Long3) *
              PI()/180 / 2), 2) ))) AS calc3 FROM Distancecalc2
),
maxx AS(
SELECT Name1, Name2, Name3, (calc1+calc2+calc3) as total FROM DistanceCalc3
WHERE Name1 != Name2 AND Name1 != Name3 AND Name2 != Name3
)
SELECT Name1, Name2, Name3, total FROM Maxx
WHERE total = (SELECT max(total) FROM Maxx);


/* Fråga 8 - ANNA */

WITH Citys5M AS(
  SELECT a.Name AS Name1, a.Population AS Pop1, a.Latitude AS Lat1, a.Longitude AS Long1,
         b.Name AS Name2, b.Population AS Pop2, b.Latitude AS Lat2, b.Longitude AS Long2
  FROM City a, City b
  WHERE  a.Population > 5000000 AND b.Population > 5000000
),
Mercator1 AS (
  SELECT radians(Lat1) AS Latitude1, radians(Lat2) AS Latitude2, ((Lat2)-(Lat1)) AS DeltaLat, radians(Citys5M.Long2-Citys5M.Long1) AS DeltaLong
  FROM Citys5M
),
Mercator2 AS (
  SELECT LOG(ABS(TAN(PI()/4.0) + (Latitude2/2.0)) / ABS(TAN((PI()/4.0) + (Latitude1/2.0)))) AS X
  FROM Citys5M, Mercator1
),
Mercator3 AS (
  SELECT (DeltaLat/X) AS q
  FROM Mercator1, Mercator2, Citys5M
)
SELECT q FROM Mercator3;
Mercator4 AS (
  SELECT Name1.Citys5M AS FirstCity, Name2.Citys5M AS SecondCity, (SQRT((POWER(DeltaLat.Mercator2, 2)) + (POWER(q.Mercator3, 2)) + (POWER((DeltaLong.Mercator2, 2))) * 6371) AS d
  FROM Meracator3
)
SELECT d FROM Mercator4;

        
#fråga 9
WITH RECURSIVE funktion AS (
  SELECT River.Name as base, river.Name, River.Length FROM river
  WHERE River.Name = 'Amazonas' OR River.Name = 'Nile' OR River.Name = 'Rhein'
  UNION ALL
  SELECT upstream.base, River.Name, River.Length + upstream.length FROM river
  INNER JOIN funktion AS upstream ON upstream.Name = River.River
)
SELECT funktion.base, MAX(funktion.length) FROM funktion GROUP BY funktion.base;
           
           
           /*/ WITH COMMENTS */
           
           
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

SELECT 1.0*Inland.NumberofProvinces/All.NumberofProvinces as ratio 
FROM (
SELECT COUNT(*) AS NumberofProvinces FROM Province 
WHERE Province.Name NOT IN (SELECT geo_sea.Province from geo_sea)) Inland,
(SELECT COUNT(*) AS NumberofProvinces FROM Provice) All;


/* OUTPUT:

         ratio          
------------------------
 0.54630205096333126165
(1 row)

*/


/* 3. Generate a table of all the continents and the sum of the areas of all those lakes that contain
at least one island for each continent. If a lake is in a country that is situated on several
continents, the appropriate share of the lake area should be counted for each of those
continents. */

/* INPUT: */

SELECT list.cont, SUM(list.a*(list.per/100)) 
FROM (SELECT DISTINCT ON (islandIn.Lake, cont) islandIn.Lake, 
Encompasses.Continent AS cont,
Encompasses.Percentage AS per, 
Lake.Area AS a
FROM islandIn 
INNER JOIN geo_Lake on islandIn.Lake = geo_Lake.Lake
INNER JOIN Encompasses on Encompasses.Country = geo_Lake.Country
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


/* INPUT: */

WITH join1 AS (
  SELECT encompasses.Country, encompasses.Continent, country.Population * (encompasses.percentage * 0.01) AS Population 
  FROM Country INNER JOIN encompasses ON country.Code = encompasses.Country
),

/*
 country |     continent     |  population   
---------+-------------------+---------------
 AL      | Europe            |    2800138.00
 GR      | Europe            |   10816286.00
 MK      | Europe            |    2059794.00
 SRB     | Europe            |    7120666.00
 */
 
join2 AS (
  SELECT join1.*, population.population_growth
  FROM population INNER JOIN join1 ON population.country = join1.country
),

/* 
 country |     continent     |  population   | population_growth 
---------+-------------------+---------------+-------------------
 AL      | Europe            |    2800138.00 |               0.3
 GR      | Europe            |   10816286.00 |              0.01
 MK      | Europe            |    2059794.00 |              0.21
 SRB     | Europe            |    7120666.00 |             -0.46
 
 */
PopCalc AS (
  SELECT continent,
    sum(population) AS current_population, 
    sum(population*(POWER(1.00+population_growth/100,50))) AS future_population
  FROM join2
  GROUP BY continent  
),

/*
     continent     | current_population |           future_population           
-------------------+--------------------+---------------------------------------
 Australia/Oceania |        93151310.76 |  158711474.27225660741511658172521100
 Africa            |     1044073424.569 |    3492745461.72707148338986156295590
 Asia              |     4243769599.495 |    7365013882.31065589997475895615902
 America           |       955818870.00 | 1525487952.57949566247800638219411400
 Europe            |      634961821.176 |  695907043.69196035745450384914671000
(5 rows)
*/

RatioCalc AS (
  SELECT *, 
    future_population - current_population AS population_increase,
    future_population / current_population AS ratio
  FROM PopCalc
),
/*
     continent     | current_population |           future_population           |         population_increase          |            ratio             
-------------------+--------------------+---------------------------------------+--------------------------------------+------------------------------
 Australia/Oceania |        93151310.76 |  158711474.27225660741511658172521100 |  65560163.51225660741511658172521100 | 1.70380290923838211608560495
 Africa            |     1044073424.569 |    3492745461.72707148338986156295590 |   2448672037.15807148338986156295590 |    3.34530635445385320688482
 Asia              |     4243769599.495 |    7365013882.31065589997475895615902 |   3121244282.81565589997475895615902 |    1.73548862859733894540750
 America           |       955818870.00 | 1525487952.57949566247800638219411400 | 569669082.57949566247800638219411400 | 1.59600108394961449388209545
 Europe            |      634961821.176 |  695907043.69196035745450384914671000 |  60945222.51596035745450384914671000 | 1.09598249923607208123613335
(5 rows)
*/

MaxMin AS (
  SELECT continent, ratio
  FROM RatioCalc
  WHERE 
    population_increase = (SELECT MAX(population_increase) FROM RatioCalc) OR
    population_increase = (SELECT MIN(population_increase) FROM RatioCalc)
)
SELECT * FROM MaxMin;

/* OUTPUT:

 continent |            ratio             
-----------+------------------------------
 Asia      |    1.73548862859733894540750
 Europe    | 1.09598249923607208123613335
(2 rows)


*/

/* 5. Generate the name of the organisation that is headquartered in Europe, has International in
its name and has the largest number of European member countries. */

/* INPUT: */

WITH eu_countries AS(
  SELECT encompasses.country FROM encompasses
  WHERE encompasses.continent = 'Europe'
),

/*
country 
---------
 AL
 GR
 MK
 SRB
 MNE
*/

EuOrg AS (
  SELECT eu_countries.Country , Organization.Name, Organization.abbreviation FROM Organization
  INNER JOIN eu_countries ON Organization.Country = eu_countries.Country
  WHERE Organization.Name LIKE '%International%'
),

/*
 country |                               name                               | abbreviation 
---------+------------------------------------------------------------------+--------------
 CH      | Bank for International Settlements                               | BIS
 A       | International Atomic Energy Agency                               | IAEA
 F       | International Chamber of Commerce                                | ICC
 NL      | International Court of Justice                                   | ICJ
 NL      | International Criminal Court                                     | ICCt
 F       | International Criminal Police Organization                       | Interpol
 F       | International Energy Agency                                      | IEA
 CH      | International Federation of Red Cross and Red Crescent Societies | IFRCS
 I       | International Fund for Agricultural Development                  | IFAD
 CH      | International Labor Organization                                 | ILO
 GB      | International Maritime Organization                              | IMO
 GB      | International Mobile Satellite Organization                      | IMSO
 CH      | International Olympic Committee                                  | IOC
 CH      | International Organization for Migration                         | IOM
 CH      | International Organization for Standardization                   | ISO
 F       | International Organization of the French-speaking World          | OIF
 CH      | International Telecommunication Union                            | ITU
 B       | International Trade Union Confederation                          | ITUC
(18 rows)

*/
Member_countries AS (
  SELECT EuOrg.Name FROM isMember
  INNER JOIN EuOrg ON isMember.Organization = EuOrg.abbreviation
  WHERE isMember.Country IN (SELECT Country FROM eu_countries)
),

/*
                              name                               
------------------------------------------------------------------
 Bank for International Settlements
 Bank for International Settlements
 Bank for International Settlements
 Bank for Inte...
 ..International Trade Union Confederation
 International Trade Union Confederation
(662 rows)
 */
 
Member_count AS (
  SELECT DISTINCT Member_countries.Name, count(Member_countries) AS medlemmar
  FROM Member_countries
  GROUP BY Member_countries.Name
)
SELECT Name FROM Member_count
WHERE medlemmar = (SELECT max(medlemmar) FROM member_count);

/* OUTPUT:
                    name                    
--------------------------------------------
 International Criminal Police Organization
(1 row)
*/

/* 6. Generate a table of city names and related airport names for all the cities that have at least
100,000 inhabitants, are situated in America and where the airport is elevated above 500 m. */

/* INPUT: */

WITH AllcitiesAmerica AS(
  SELECT City.Name, City.Population FROM City 
  INNER JOIN encompasses ON City.Country = encompasses.country
  WHERE encompasses.continent = 'America' AND City.population >= 1000000
),
All_airports AS (
  SELECT AllcitiesAmerica.Name , Airport.Name FROM Airport 
    INNER JOIN AllcitiesAmerica ON Airport.City = AllcitiesAmerica.Name 
    WHERE Airport.Elevation >= 500
)
SELECT * FROM All_airports;       

/* OUTPUT
 

*/

/* 7. Generate a table of countries and the ratio between their latest reported and earliest
reported population figures, rounded to one decimal point, for those countries where this ratio
is above 10, that is to say those that have grown at least 10-fold between earliest and latest
population count. */

/* INPUT: */

WITH OldestReport AS(
SELECT DISTINCT ON (CountryPops) CountryPops.Country, CountryPops.Population, t.mx
FROM (
    SELECT Country, MIN(Year) AS mx
    FROM CountryPops
    GROUP BY Country
  ) t INNER JOIN CountryPops ON CountryPops.Country = t.Country AND t.mx = CountryPops.Year
),
join1 AS (
  SELECT Country.Name, Country.Population, OldestReport.Population AS Olddata FROM Country
  INNER JOIN OldestReport ON OldestReport.Country = Country.Code
),
Calc AS (
  SELECT join1.Name, Join1.Population / join1.Olddata AS Ratio1 FROM join1
),
Structure AS (
  SELECT Calc.Name, ROUND(Ratio1,1) AS Rounded_Ratio FROM CALC
),
Final AS (
SELECT Structure.Name, Structure.Rounded_Ratio AS Ratio FROM Structure
WHERE Structure.Rounded_Ratio >= 10
)
SELECT * FROM Final;        


/* OUTPUT
         name         | ratio 
----------------------+-------
 Andorra              |  12.6
 Gibraltar            |  17.9
 Bahrain              |  13.7
 Hong Kong            |  25.0
 Jordan               |  13.9
 Kuwait               |  19.6
 United Arab Emirates | 121.3
 Philippines          |  61.5
 Qatar                |  68.0
 Cayman Islands       |  59.7
 Costa Rica           |  39.6
 Panama               |  10.1
 El Salvador          |  42.9
 Sint Maarten         |  25.0
 Australia            |  10.3
 Uruguay              |  24.9
 Botswana             |  16.9
 South Africa         |  10.0
 Djibouti             |  13.5
(19 rows)


*/

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

/* INPUT: */


WITH Citys5M AS(
  SELECT a.Name AS Name1, a.Population AS Pop1, a.Latitude AS Lat1, a.Longitude AS Long1,
         b.Name AS Name2, b.Population AS Pop2, b.Latitude AS Lat2, b.Longitude AS Long2
  FROM City a, City b
  WHERE  a.Population > 5000000 AND b.Population > 5000000
),
Mercator1 AS (
  SELECT radians(Lat1) AS Latitude1, radians(Lat2) AS Latitude2, ((Lat2)-(Lat1)) AS DeltaLat, radians(Citys5M.Long2-Citys5M.Long1) AS DeltaLong
  FROM Citys5M
),
Mercator2 AS (
  SELECT LOG(ABS(TAN(PI()/4.0) + (Latitude2/2.0)) / ABS(TAN((PI()/4.0) + (Latitude1/2.0)))) AS X
  FROM Citys5M, Mercator1
),
Mercator3 AS (
  SELECT (DeltaLat/X) AS q
  FROM Mercator1, Mercator2, Citys5M
)
SELECT q FROM Mercator3;
Mercator4 AS (
  SELECT Name1.Citys5M AS FirstCity, Name2.Citys5M AS SecondCity, (SQRT((POWER(DeltaLat.Mercator2, 2)) + (POWER(q.Mercator3, 2)) + (POWER((DeltaLong.Mercator2, 2))) * 6371) AS d
  FROM Meracator3
)
SELECT d FROM Mercator4;
      
     

/* OUTPUT
 

*/

/* 9. Generate a table that contains the rivers Rhein, Nile and Amazonas, and the longest total
length that the river systems feeding into each of them contain (including their own
respective length). You must calculate the respective river systems of tributary rivers
recursively. 
*/

/* INPUT: */

KLAR:
           
           WITH RECURSIVE funktion AS (
  SELECT River.Name as base, river.Name, River.Length FROM river
  WHERE River.Name = 'Amazonas' OR River.Name = 'Nile' OR River.Name = 'Rhein'
  UNION ALL
  SELECT upstream.base, River.Name, River.Length + upstream.length FROM river
  INNER JOIN funktion AS upstream ON upstream.Name = River.River
)
SELECT funktion.base, MAX(funktion.length) FROM funktion GROUP BY funktion.base;
           
           INTE KLAR:
           
           
WITH Rivers1 AS (
SELECT River.Name AS Name1, River.River AS River1, a.Length AS Length1 FROM River
INNER JOIN River a ON River.Name = a.River
WHERE River.Name LIKE '%Rhein%' OR River.Name LIKE'%Nile%' OR River.Name LIKE '%Amazonas%'
OR River.River LIKE '%Rhein%' OR River.River LIKE'%Nile%' OR River.River LIKE '%Amazonas%'
),
Rhein AS (
SELECT SUM(Rivers1.Length1) AS RheinLength FROM Rivers1
WHERE Rivers1.Name1 LIKE '%Rhein%' OR Rivers1.River1 LIKE'%Rhein%'
),
Nile AS (
SELECT SUM(Rivers1.Length1) AS NileLength FROM Rivers1
WHERE Rivers1.Name1 LIKE '%Nile%' OR Rivers1.River1 LIKE'%Nile%'
),
Amazonas AS (

SELECT SUM(Rivers1.Length1) AS AmazonasLength FROM Rivers1
WHERE Rivers1.Name1 LIKE '%Amazonas%' OR Rivers1.River1 LIKE'%Amazonas%'
),
RheinMax AS (
SELECT MAX(Rivers1.Length1) AS RheinMaxLength FROM Rivers1
WHERE Rivers1.River1 LIKE '%Rhein%'
),
NileMax AS (
SELECT MAX(Rivers1.Length1) AS NileMaxLength FROM Rivers1
WHERE Rivers1.River1 LIKE '%Nile%'
),
AmazonasMax AS (
SELECT MAX(Rivers1.Length1) AS AmazonasMaxLength FROM Rivers1
WHERE Rivers1.River1 LIKE '%Amazonas%'
)
SELECT Rhein.RheinLength, RheinMax.RheinMaxLength, Nile.NileLength,
NileMax.NileMaxLength, Amazonas.AmazonasLength, AmazonasMax.AmazonasMaxLength
FROM Rhein, RheinMax, Nile, NileMax, Amazonas, AmazonasMax;


           
/* OUTPUT
           
      name      |   river    | length 
---------------+------------+--------
 Rhein         |            |   1324
 Lippe         | Rhein      |    220
 Ruhr          | Rhein      |    219
 Lahn          | Rhein      |    246
 Main          | Rhein      |    524
 Mosel         | Rhein      |    544
 Neckar        | Rhein      |    367
 Ill           | Rhein      |    217
 Aare          | Rhein      |    288
 Hinterrhein   | Rhein      |     72
 Maas          | Rhein      |    925
 Amazonas      |            |   3778
 Rio Negro     | Amazonas   |   2866
 Japura        | Amazonas   |   2816
 Rio Putumayo  | Amazonas   |   1813
 Maranon       | Amazonas   |   1905
 Ucayali       | Amazonas   |   1600
 Jurua         | Amazonas   |   3283
 Purus         | Amazonas   |   3210
 Rio Madeira   | Amazonas   |   1450
 Xingu         | Amazonas   |   1980
 Nile          |            |   3090
 Atbara        | Nile       |   1120
 Blue Nile     | Nile       |   1783
 White Nile    | Nile       |    950
 Sobat         | White Nile |    740
 Victoria Nile |            |    480
(27 rows)

 rheinlength | rheinmaxlength | nilelength | nilemaxlength | amazonaslength | amazonasmaxlength 
-------------+----------------+------------+---------------+----------------+-------------------
      4049.3 |            227 |       5219 |           740 |          27502 |              1931
(1 row)


           
*/

