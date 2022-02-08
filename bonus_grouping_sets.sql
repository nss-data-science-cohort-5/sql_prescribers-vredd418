-- #1

SELECT 
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE specialty_description = 'Interventional Pain Management' OR specialty_description = 'Pain Management'
GROUP BY specialty_description;



-- #2 ???

SELECT 
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
GROUP BY specialty_description
UNION ALL
SELECT 
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE specialty_description = 'Pain Management'
GROUP BY specialty_description;



-- #3

SELECT 
	specialty_description
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE specialty_description = 'Interventional Pain Management' OR specialty_description = 'Pain Management'
GROUP BY GROUPING SETS((specialty_description), ());



-- #4

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management' OR specialty_description = 'Pain Management'
GROUP BY GROUPING SETS((opioid_drug_flag), (specialty_description), ());



-- #5

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management' OR specialty_description = 'Pain Management'
GROUP BY ROLLUP(opioid_drug_flag, specialty_description);

/* GROUPING SETS only sum by group. ROLLUP sums be every combination of the first variable listed and the second variable, 
   plus no variable (null specialty and null flag, so total claims), and the first variable (summed by flag) */



-- #6

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management' OR specialty_description = 'Pain Management'
GROUP BY ROLLUP(specialty_description, opioid_drug_flag);

-- Same as above, but switch the variables



-- #7 

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management' OR specialty_description = 'Pain Management'
GROUP BY CUBE(specialty_description, opioid_drug_flag);

-- CUBE sums claims for all possible combinations of variables, no variables (null specialty and flag), and single variables (null specialty or null flag)



-- #8

-- SUM, CASE method
SELECT
	nppes_provider_city AS city,
	SUM(CASE WHEN generic_name LIKE '%CODEINE%' THEN total_claim_count END) AS CODEINE,
	SUM(CASE WHEN generic_name LIKE '%FENTANYL%' THEN total_claim_count END) AS FENTANYL,
	SUM(CASE WHEN generic_name LIKE '%HYDROCODONE%' THEN total_claim_count END) AS HYDROCODONE,
	SUM(CASE WHEN generic_name LIKE '%MORPHINE%' THEN total_claim_count END) AS MORPHINE,
	SUM(CASE WHEN generic_name LIKE '%OXYCODONE%' THEN total_claim_count END) AS OXYCODONE,
	SUM(CASE WHEN generic_name LIKE '%OXYMORPHONE%' THEN total_claim_count END) AS OXYMORPHONE
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE nppes_provider_city IN('CHATTANOOGA', 'KNOXVILLE', 'MEMPHIS', 'NASHVILLE')
GROUP BY nppes_provider_city;


	