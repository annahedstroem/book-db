
(: Fråga 1 :)
(: # List all countries that does not have any islands :)

for $x in //country
where not(//island[$x/@car_code = ./@country])
return <NoIslandCountries>{($x/name)}</NoIslandCountries>

(: Fråga 2:)
(: Generate the ratio between inland provinces (provinces not bordering any sea) to total number of provinces.:)

XQUERY
let $total := count(//province)
let $input :=
  for $provinces in //province
  for $seas in //sea/located
  let $output :=
    $provinces/@id
    where contains($seas/@province, $provinces/@id)
    group by $output
    return <province>{$output}</province>
return
  for $value in distinct-values($input)
  let $count := count($input[. eq $value])
  count $c
  let $ratio := ($c div $total)
  (: let $ratio2 := $ratio[data() = data($ratio)] :)
  (: let $ratio3 := $ratio[data() = max(data($ratio))] :)
  order by $ratio
  return <ratio>{concat($ratio[last()])}</ratio>

(: Fråga 3:)
(: # Generate a table of all the continents and the sum of the areas of all those lakes that containat least one #island for each continent. If a lake is in a country that is situated on several continents, the appropriate #share of the lake area should be counted for each of those continents. :)
let $lake_area := (
  
  for $country in //mondial/country
  for $island in //mondial/island
  for $lake in //mondial/lake
  
  where $country/@car_code = $island/@country and $island/@lake = $	lake/@id
  
  let $continents := $country/encompassed/@continent
  let $percentage := $country/encompassed/@percentage
  
  (: i är en counter :)
  for $continent at $i in $continents
  (: gör uträkningen för varje kontinent :) 
  return <area>{$continent, ($percentage[$i] div 100)*$lake/area}</area>
)

for $area in $lake_area
  let $continent := $area/@continent
  group by $continent
return <continent><name>{$continent}</name><lake_area>{sum($area)}</lake_area></continent>

(: Fråga 4 :)
(: Generate a table with the two continents that will have the largest and the smallest population increase fifty years from now given current population and growth rates, and the future population to current population ratios for these two continents. :)


xquery

for $cont in distinct-values(//continent/@id)
for $pop_total_country in //country/population
for $pop_growth_country in //country/population_growth

let $countries := //country[encompassed/@continent = $cont]

let $avg_total := avg(//country[encompassed/@continent = $cont]/population_growth)
let $avg_growth := avg(//country[encompassed/@continent = $cont]/population)

let $avg_total_data := $avg_total[data() = max(data($avg_total))]
let $avg_growth_data := $avg_growth[data() = max(data($avg_growth))]

let $x := $avg_growth_data div 100
let $y := math:pow($x, 50)
let $future_population := $avg_total_data * $y
let $ratio := $future_population div $avg_total_data
let $population_increase := $future_population - $avg_total_data

group by $cont, $ratio

return <output>{concat($cont, " ", $ratio, " ")}</output>

(: Fråga 4 version 2 :) 

let $ratios := (

for $continent in doc("mondial.xml")/mondial/continent
let $countries := doc("mondial")/mondial/country[encompassed/@continent = $continent/@id]

let $current_population := 
  sum(
    for $country in $countries
    return $country/population[last()] 
  )

let $future_population :=
  sum(
    for $country in $countries 
    
    let $growth_rate := $country/population_growth/data() div 100 + 1
    
    (: let $encompasses := ($country/encompassed[@continent = $continent/@id]/@percentage) div 100 :)
    
    return $country/population[last()]*math:pow($growth_rate, 50) (:*encompasses:)
  )
  return <continent name = "{$continent/name}"><ratio>{$future_population div $current_population}</ratio></continent>
)

return <result>{$ratios[data() = max(data($ratios)) or data() = min(data($ratios))]}</result>

(: Fråga 5 :)
(: Generate the name of the organisation that is headquartered in Europe, has International #inits name and has the largest number of European member countries. :)

let $EUcountries := //country[encompassed/@continent = 'europe' ]
let $IntOrg := //organization[matches(name/string(), 'International')]

let $inEu := for $hq in $IntOrg return $hq[$hq/@headq/data() = $EUcountries//city/@id/data()]
let $Output := for $organization in $inEu return <organization name="{$organization/name/string()}">{count( for $x in $EUcountries return $organization[contains(members[1]/@country/string(), $x/@car_code/string())] )} </organization>

return $Output[data() = max($Output/data())]

(: Fråga 6 :)
(: Generate a table of city names and related airport names for all the cities that have at least 100,000 inhabitants, are situated in America and where the airport is elevated above 500 m. :)

for $countrieslist in //country 
for $citieslist in //city 
for $airportlist in //airport 
where $countrieslist/encompassed[@continent = ("america")] 
where $citieslist[population >= 100000] 
where $countrieslist/@car_code=$citieslist/@country 
where $airportlist/elevation >= 500 
where $airportlist/@city =$citieslist/@id 
return <city> {$citieslist/name} <airports> {$airportlist/name} </airports> </city>

(: Fråga 7:)
for $country in //country
let $ratio := round-half-to-even($country/population[last()] div $country/population[1], 1)
where $ratio > 10
return <country><name>{$country/name}</name><ratio>{$ratio}</ratio></country>

(: Fråga 8 :)
(: Generate a table with the three (3) cities above 5,000,000 inhabitants that form the largest triangle between them, measured as the total length of all three triangle legs, and that total length. Your solution should be on the output form.. :)
(:
  compute distance between two lat/long pairs
  6371*2.0*2*math:asin(math:sqrt((math:pow(math:sin((3.14 div 180)*
  (($city1/latitude/data()-$city2/latitude/data()) div 2.0)),2))+
  (math:cos((3.14 div 180)*($city1/latitude/data()))*
  math:cos((3.14 div 180)*($city2/latitude/data()))*
  math:pow(math:sin((3.14 div 180)
  *(($city1/longitude/data()-$city2/longitude/data()) div 2.0)),2))))
:)
xquery let $citieslist1 := for $cities1 in //city where $cities1[population >= 5000000] return <city1> {$cities1/(name|latitude|longitude)} </city1> let $citieslist2 := for $cities2 in //city where $cities2[population >= 5000000] return <city2> {$cities2/(name|latitude|longitude)} </city2> let $citieslist3 := for $cities3 in //city where $cities3[population >= 5000000] return <city3> {$cities3/(name|latitude|longitude)} </city3> for $cityone in ($citieslist1) for $citytwo in ($citieslist2) for $citythree in ($citieslist3) let $calc1 := (6371 * 2) let $sin := math:sin($cityone/latitude - abs($citytwo/latitude)) let $calc2 := (math:pi() div 180) let $calc25 := $calc2 div 2 let $calc3 := $calc1 * $sin * $calc25 let $calc4 := math:pow($calc3, 2) let $calc5 := math:sqrt($calc3) let $cos := math:cos($cityone/latitude * calc2) let $cos2 := math:cos(abs($citytwo/latitude)) let $cos3 := $cos2 * $cos let $calc6 := $cos3 * $calc2 let $sin2 := math:sin($cityone/longitude - abs($citytwo/longitude)) let $calc7 := $sin2 * $calc25 let $calc9 := math:pow($calc7, 2) let $finalcalc := $calc5 + $calc9 count $s for $i in distinct-values($finalcalc) let $j := max(data($i)) group by $i return <city1> {$cityone/name} <city2> {$citytwo/name} <calc> {$j} </calc> </city2> </city1>




let $db := doc("mondial.xml"),
    (: filter out cities that are less than 5 million cities :)
    $cities := $db//city[data(population[@year = "2011"]) >= 5000000 ],

    (: generate all combinations of lengths between chosen cities :)
    $trilegs :=
      for $city1 in $cities
      return (
        for $city2 in $cities
        where data($city1/name) < data($city2/name)
        return
          <trileg city1="{$city1/name}" city2="{$city2/name}">
            {
              6371*2.0*2*math:asin(math:sqrt((math:pow(math:sin((3.14 div 180)*
              (($city1/latitude/data()-$city2/latitude/data()) div 2.0)),2))+
              (math:cos((3.14 div 180)*($city1/latitude/data()))*
              math:cos((3.14 div 180)*($city2/latitude/data()))*
              math:pow(math:sin((3.14 div 180)
              *(($city1/longitude/data()-$city2/longitude/data()) div 2.0)),2))))
            }
          </trileg>
      ),

    (: generate alla combinations of triangles with our triangle legs :)
    $triangles :=
      for $l1 in $trilegs
      return (
        for $l2 in $trilegs
        return (
          for $l3 in $trilegs
          (: remove duplicates :)
          where $l1/@city1 < $l1/@city2 and $l1/@city1 < $l2/@city2 and $l1/@city2 < $l2/@city2
          and $l1/@city1 = $l2/@city1 and $l2/@city2 = $l3/@city1
          return
            <triangle city1="{$l1/@city1}" city2="{$l1/@city2}" city3="{$l3/@city1}">
                {
                  data($l1) + data($l2) + data($l3)
                }
            </triangle>
        )

      )

return $triangles[data() = max(data($triangles))]



(: Fråga 9 :)

declare function local:tributary($current as element(river), $base as xs:string, $length as xs:double)
{
  (: to är en node :)
        let $db := doc("mondial.xml")
        let $tributary := $db//river[to[@watertype="river"] and contains(to/@water, $current/@id)]

return(
      (: BASFALL :)
      if(empty($tributary)) then ( <river name="{$base}"> {$length} </river> )
        
      else ( 
      for $first in $tributary
      let $nextPart := $first/length/data()
      return local:tributary($first, $base, ($length + $nextPart) )
      )
    )
};

let $db := doc("mondial.xml")
let $nile := local:tributary($db//river[name/string() = 'Nile'], 'Nile', $db//river[name/string() = 'Nile']/length/data())
let $amazonas := local:tributary($db//river[name/string() = 'Amazonas'], 'Amazonas', $db//river[name/string() = 'Amazonas']/length/data())
let $rhein := local:tributary($db//river[name/string() = 'Rhein'], 'Rhein', $db//river[name/string() = 'Rhein']/length/data())

return <result>{$nile[data() = max($nile/data())], $rhein[data() = max($rhein/data())], $amazonas[data() = max($amazonas/data())]}</result>

(: Fråga B :)


declare function local:inEurope($headq as xs:IDREF?) 
as xs:boolean? {
  
  for $country in doc("mondial.xml")/mondial/country
  where contains($headq, $country/name)
  return
     if($country/encompassed/@continent = 'europe') then true()
     else false()
     
};

let $orgs := 
  for $intOrg in doc("mondial.xml")/mondial/organization
  where starts-with($intOrg/name, 'International')
      and local:inEurope($intOrg/@headq) 
  order by $intOrg/name
  return concat('org-', $intOrg/abbrev)
for $country in doc("mondial.xml")/mondial/country
where every $org in $orgs
  satisfies contains($country/@memberships, $org)
return $country/name
 
(:fråga C1 :) 
(: Function to get all non-visited neighbours of a given country :)
declare function local:get-neighbour-countries($id as xs:string, $not-visited as xs:string*){
  let $the-country := doc("mondial.xml")//country[@car_code = $id]
  for $neighbour in $the-country/border/@country
  where $neighbour = $not-visited
  return $neighbour
};

(: Function to get all the non-visited reachdable countries given the countries just been to :)
declare function local:reach($just-visited as xs:string*, $not-visited as xs:string*){
  for $country in $just-visited
  return local:get-neighbour-countries($country, $not-visited[not(.=$just-visited)])
};

(: Function to process all reachable countries of all possible depths :)
declare function local:go-further($just-visited as xs:string*, $depth as xs:integer, $not-visited as xs:string*){
  
  let $reachdable := distinct-values(local:reach($just-visited, $not-visited))
  let $not-visited-update := distinct-values($not-visited[not(.=$just-visited)])
  
  return 
  
      (: If we cannot go futher :)
      if (empty($reachdable))then () 
      
      (: If it is still possible to go further :)
      else  <cross depth = '{$depth}' reached = '{$reachdable}'>
                  {local:go-further($reachdable, $depth + 1, $not-visited-update)}
            </cross>
  
};

declare function local:get-max-depth($crossings as node()){
  let $cross := $crossings/cross
  return
    if (exists($cross)) then 
        local:get-max-depth($cross)
    else $crossings
};

let $not-visited := doc("mondial.xml")//country[@car_code != "S"]/@car_code 
return local:go-further('S', 1, $not-visited)
 
(: Fråga C2 :)

(: Function to get all non-visited neighbours of a given country :)
declare function local:get-neighbour-countries($id as xs:string, $not-visited as xs:string*){
  let $the-country := doc("mondial.xml")//country[@car_code = $id]
  for $neighbour in $the-country/border/@country
  where $neighbour = $not-visited
  return $neighbour
};

(: Function to get all the non-visited reachdable countries given the countries just been to :)
declare function local:reach($just-visited as xs:string*, $not-visited as xs:string*){
  for $country in $just-visited
  return local:get-neighbour-countries($country, $not-visited[not(.=$just-visited)])
};

(: Function to process all reachable countries of all possible depths :)
declare function local:go-further($just-visited as xs:string*, $depth as xs:integer, $not-visited as xs:string*){
  
  let $reachdable := distinct-values(local:reach($just-visited, $not-visited))
  let $not-visited-update := distinct-values($not-visited[not(.=$just-visited)])
  
  return 
  
      (: If we cannot go futher :)
      if (empty($reachdable))then () 
      
      (: If it is still possible to go further :)
      else  <cross depth = '{$depth}' reached = '{$reachdable}'>
                  {local:go-further($reachdable, $depth + 1, $not-visited-update)}
            </cross>
  
};

declare function local:get-max-depth($crossings as node()*){
  let $cross := $crossings/cross
  return
    if (exists($cross)) then 
        local:get-max-depth($cross)
    else $crossings
};

let $list-of-crossings := 
    for $country in doc("mondial.xml")//country
    let $id := $country/@car_code
    let $not-visited := doc("mondial.xml")//country[@car_code != $id]/@car_code 
    let $crossings := local:go-further($id, 1, $not-visited)
    where exists($crossings)
    return <result country = '{$id}'>{local:get-max-depth($crossings)}</result>
    
let $maxes := 
    for $result in $list-of-crossings
    return data($result/cross/@depth)

let $max-depth := max($maxes)    
    
for $result in $list-of-crossings
where $result/cross/@depth = $max-depth
return $result    


(: Fråga D :)

(: Function to invert a single node:)
declare function local:invert($elem as node()) as node(){
  let $item := $elem
  return element 
    {name($item)} 
    {
     (: Add attributes, if a sub-element lacks sub elements of their own, 
     their data content becomes an attribute with the name “value” :)
      if (exists($item/*)) then(
        for $subelem in $item/*
        return attribute {name($subelem)} {data($subelem)}
      )
      else attribute {'value'} {data($item)}      
      ,
        
     (: Add sub-elememtns:)   
      for $attribute in $item/@*
      return element {name($attribute)} {data($attribute)}
    }
};

(: Replace every sub-element in music with its inversed version :)  
copy $music := doc("songs.xml")/music
modify (
  for $item in $music/*
  return replace node $item with local:invert($item)
)
return $music
