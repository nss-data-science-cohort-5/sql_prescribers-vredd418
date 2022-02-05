/* 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
      b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims. */

SELECT SUM(total_claim_count), npi, nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS name, specialty_description -- Concat two columns into one with space separator
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1; 

-- BRUCE PENDLEY, Family Practice, npi: 1881634483, 99707 claims

/* 2. a. Which specialty had the most total number of claims (totaled over all drugs)? -- Family Practice, 9752347 claims

    b. Which specialty had the most total number of claims for opioids? -- Nurse Practitioner, 900845 claims

    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table? 

    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids? */
	
SELECT specialty_description, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

SELECT specialty_description, TO_CHAR(SUM(total_claim_count), 'FM9,999,999') -- Adds commas to numbers, but converts to text
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

SELECT speciality_description opioid_drug_flag
(SELECT  specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
LEFT JOIN drug
USING(drug_name)
GROUP BY specialty_description, opioid_drug_flag) AS sub

-- James, 2c
SELECT DISTINCT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
FULL JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY specialty_description
HAVING (SUM(total_claim_count) IS NULL)
ORDER BY total_claims;

-- Jacob, 2c
SELECT DISTINCT specialty_description
FROM prescriber
WHERE specialty_description NOT IN 
	(SELECT specialty_description
	FROM prescription
	INNER JOIN prescriber
	USING (npi));

-- Chris M., 2c
SELECT p1.specialty_description AS specialty, COALESCE(SUM(p2.total_claim_count), 0) AS total_claims
FROM prescriber p1
LEFT JOIN prescription p2 ON p1.npi = p2.npi
GROUP BY 1
ORDER BY 2;

-- Ross, 2c
SELECT DISTINCT pr.specialty_description, COUNT(pn.total_claim_count) AS claim_cnt
FROM prescriber pr
LEFT JOIN prescription pn
ON pr.npi = pn.npi
-- WHERE SUM(pn.total_claim_count) IS NULL
GROUP BY pr.specialty_description
HAVING COUNT(pn.total_claim_count) = 0
ORDER BY claim_cnt DESC;

WITH 
	cte_1 AS (
		SELECT 
			specialty_description, 
			SUM(total_claim_count) AS total_opioid_claims
		FROM prescriber
		JOIN prescription
		USING(npi)
		JOIN drug
		USING(drug_name)
		WHERE opioid_drug_flag = 'Y'
		GROUP BY specialty_description, opioid_drug_flag
),
	cte_2 AS (
		SELECT 
			specialty_description,
			SUM(total_claim_count) AS total_claims
		FROM prescriber
		JOIN prescription
		USING(npi)
		GROUP BY specialty_description	
)
SELECT 
	specialty_description,
	ROUND(total_opioid_claims / total_claims * 100.0, 2) AS opioid_pct
FROM cte_1
JOIN cte_2
USING(specialty_description)
ORDER BY opioid_pct DESC

-- Jacob
SELECT 
	specialty_description, 
	ROUND(SUM(opioid_claims)/SUM(total_claim_count) * 100.0 , 2) AS percent_opioid
FROM
(SELECT specialty_description, total_claim_count, drug_name, opioid_drug_flag,
	CASE WHEN opioid_drug_flag = 'N' THEN 0
	ELSE total_claim_count END AS opioid_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)) AS opioid_claims_table
GROUP BY specialty_description
ORDER BY percent_opioid DESC;


/* 3. a. Which drug (generic_name) had the highest total drug cost? -- INSULIN GLARGINE,HUM.REC.ANLOG, $104264066.35 

    b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works. -- IMMUN GLOB G(IGG)/GLY/IGA OV50, $ 7141.11 per day */
	
SELECT generic_name, total_drug_cost
FROM prescription
LEFT JOIN drug
USING(drug_name)
ORDER BY 2 DESC
LIMIT 1;

-- Alex's answer. Probably the correct one.
SELECT generic_name, SUM(total_drug_cost)
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC;

SELECT generic_name, ROUND(total_drug_cost/total_day_supply, 2)
FROM prescription
LEFT JOIN drug
USING(drug_name)
ORDER BY 2 DESC
LIMIT 1;

-- Alex's answer again.
SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2)::MONEY -- Cast as money
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 1;


/* 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision. -- More spent on opioids. */

SELECT sub.drug_type, CAST(SUM(total_drug_cost) AS money) -- Some drugs listed as opioid and not opioid, so answer slightly different depending on query
FROM prescription
JOIN
	(SELECT drug_name,
	 CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 ELSE 'neither' END AS drug_type
	 FROM drug) AS sub
USING(drug_name)
GROUP BY sub.drug_type
ORDER BY SUM(total_drug_cost) DESC;


/* 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee. -- 10 CBSAs

    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population. -- Smallest was Morristown with 116352, Largest, Nashville-Davidson--Murfreesboro--Franklin, TN with 1830410.

    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population. */ -- SEVIER County, 95523
	
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

SELECT cbsaname, SUM(population) AS sum_pop
FROM cbsa
JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY sum_pop;

-- Bryan for 5b, returns only smallest and largest
select * 
from (select cbsa.cbsaname, sum(population) total_population
      from cbsa
               inner join population p on cbsa.fipscounty = p.fipscounty
      group by cbsa.cbsaname
      order by total_population desc
      limit 1) sq1
union
select *
from (select cbsa.cbsaname, sum(population) total_population
      from cbsa
               inner join population p on cbsa.fipscounty = p.fipscounty
      group by cbsa.cbsaname
      order by total_population asc
      limit 1) sql;

SELECT sub.county, sub.population
FROM 
	(SELECT population, county, cbsa
	 FROM fips_county
	 JOIN population
	 USING(fipscounty)
	 LEFT JOIN cbsa
	 USING(fipscounty)) AS sub
WHERE cbsa IS NULL
ORDER BY sub.population DESC
LIMIT 1;


/* 6. 
    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count. 

    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row. */
	
SELECT nppes_provider_first_name,
	   nppes_provider_last_org_name,
	   drug_name,
	   total_claim_count,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
		 	ELSE 'Not opioid' END AS opioid
FROM prescription
LEFT JOIN drug
USING(drug_name)
LEFT JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000

/* 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.

    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function. */
	

SELECT prescriber.npi, drug.drug_name
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription


-- Jacob
SELECT p1.npi, d.drug_name, COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber AS p1
CROSS JOIN drug AS d
FULL JOIN prescription AS p2
USING (drug_name, npi)
WHERE specialty_description = 'Pain Management' 
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
ORDER BY total_claims DESC;

-- Alex
SELECT npi, prescription.drug_name, COALESCE(total_claim_count, 0) AS total_claim_count
FROM (
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
) as npi_drug
LEFT JOIN prescription
USING(npi, drug_name);



