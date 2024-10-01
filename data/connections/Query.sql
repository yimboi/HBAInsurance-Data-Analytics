/*EDA*/

SELECT *
FROM dbo.Account

-- Check for duplicated columns, especially for designated Unique Key
SELECT POLICY_NUMBER, COUNT(*) AS Duplicated_Records
FROM dbo.Account
GROUP BY POLICY_NUMBER
HAVING COUNT(*) > 1
-- No null is detected, nor duplicated columns
-- Potentially can be a PRIMARY KEY

SELECT PLAN_CODE, COUNT(*) AS Duplicated_Records
FROM dbo.Account
GROUP BY PLAN_CODE
HAVING COUNT(*) > 1
-- Some clients may have similar policy plans
-- Although, some plan_code are ambiguous where '0'

SELECT CLIENT_CODE, COUNT(*) AS Duplicated_Records
FROM dbo.Account
GROUP BY CLIENT_CODE
HAVING COUNT(*) > 1
-- There are 104 Client Codes whose records were duplicated
-- It could mean that clients can have multiple policies
-- Potentially can be a FOREIGN KEY

-- Check for duplicated column at other columns
SELECT SURRENDER_DATE, COUNT(*) AS Duplicated_Records
FROM dbo.Account
GROUP BY SURRENDER_Date
HAVING COUNT(*) > 1
-- Duplicated Records found at certain dates
-- Null are expected (since most clients have their current policies intact/ enforced)

/* dbo.Account */
-- Total, Mean
-- SUM_ASSURED, MODAL_PREMIUM, PAYMENT_MODE
SELECT SUM(SUM_ASSURED) AS 'sum assured', AVG(SUM_ASSURED) As 'avg assured', SUM(MODAL_PREMIUM) As 'sum premiums', AVG(MODAL_PREMIUM) As 'avg premiums', AVG(PAYMENT_MODE) AS 'avg payment mode', (MODAL_PREMIUM*PAYMENT_MODE) AS 'total premiums'
FROM dbo.Account
-- As calculated in Python, the numbers checks out

-- Total Premiums Charged
SELECT SUM((MODAL_PREMIUM*PAYMENT_MODE)) AS 'total_premium'
FROM dbo.Account


-- Median for SUM_ASSURED, MODAL_PREMIUM and PAYMENT_MODE
WITH summary_statistics AS(
	SELECT
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED ASC) OVER () AS median_assured,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY MODAL_PREMIUM ASC) OVER () AS median_premiums,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY PAYMENT_MODE ASC) OVER() AS median_payment_mode
	FROM dbo.Account
)
SELECT DISTINCT *
FROM summary_statistics
-- As calculated in Python, the numbers checks out

-- Policy Status by Count and Percentages
SELECT 
	POLICY_STATUS,
	COUNT(*),
	CAST (COUNT(*) * 100.00 / (
				SELECT COUNT(*)
				FROM dbo.Account
				) AS decimal(10,2)) AS 'policy_percent'
FROM dbo.Account
GROUP BY POLICY_STATUS
ORDER BY policy_percent DESC;
-- As calculated in Python, the numbers and % checks out too

-- Determine each type of products'  the avg of premiums paid and the median sum assured
WITH summary_clients_and_types AS (
    SELECT
		CLIENT_CODE,
        TYPE,
        FORMAT(
            PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE),
            'N'
        ) AS median_sum_assured,
        FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N') AS avg_premiums
    FROM dbo.Account
)
SELECT DISTINCT
    s1.TYPE AS types_of_products,
	t1.count_types,
    median_sum_assured,
    avg_premiums
FROM summary_clients_and_types AS s1
LEFT JOIN (
	SELECT TYPE, COUNT(TYPE) AS count_types
	FROM dbo.Account
	GROUP BY TYPE) AS t1
ON s1.TYPE = t1.TYPE
ORDER BY t1.count_types DESC;
-- Each type of products have varying degree of median sum insured and avg premiums
-- Besided, the avg premiums for Policy type E, A and D are almotst similar (RM 1.5k)
-- Policy C have one of the highest insured amount compared to the rest of the products

-- Assign columns for each clients whose premiums and sum assured are higher than the average and the median respectively for each product types
WITH summary_clients_and_types AS (
    SELECT
		POLICY_NUMBER,
		CLIENT_CODE,
        TYPE,
		FORMAT(SUM_ASSURED, 'N') AS sum_assured,
        FORMAT(
            PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE),
            'N'
        ) AS median_sum_assured,
		FORMAT(MODAL_PREMIUM, 'N') AS premiums_paid,
        FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N') AS avg_premiums
    FROM dbo.Account
)
SELECT
	POLICY_NUMBER,
	CLIENT_CODE,
	s1.TYPE,
	sum_assured,
    median_sum_assured,
	CASE WHEN sum_assured >= median_sum_assured THEN 'Y'
	ELSE 'N' END  AS sum_assured_outcome,
	premiums_paid,
    avg_premiums,
	CASE WHEN premiums_paid >= avg_premiums THEN 'Y'
	ELSE 'N' END  AS premiums_outcome
FROM summary_clients_and_types AS s1
LEFT JOIN (
	SELECT TYPE, COUNT(TYPE) AS count_types
	FROM dbo.Account
	GROUP BY TYPE) AS t1
ON s1.TYPE = t1.TYPE
ORDER BY POLICY_NUMBER ASC;

-- Counting the distribution of packages with respect to the premiums and sum assured
-- Count number of clients when the sum assured and premiums are lower than the median and average respectively

WITH s1 AS (
    SELECT
		CLIENT_CODE,
        TYPE,
		FORMAT(SUM_ASSURED, 'N') AS sum_assured,
        FORMAT(
            PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE),
            'N'
        ) AS median_sum_assured,
		FORMAT(MODAL_PREMIUM, 'N') AS premiums_paid,
        FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N') AS avg_premiums
    FROM dbo.Account
)
SELECT
	s2.sum_assured_outcome,
	COUNT(s2.sum_assured_outcome) AS no_of_clients,
	s2.premiums_outcome,
	COUNT(s2.premiums_outcome) AS no_of_clients
FROM (
	SELECT CASE 
				WHEN s1.sum_assured >= s1.median_sum_assured THEN 'Y'
				ELSE 'N' END AS sum_assured_outcome,
			CASE 
				WHEN s1.premiums_paid >= s1.avg_premiums THEN 'Y'
				ELSE 'N' END AS premiums_outcome
	FROM s1
	) AS s2
WHERE s2.sum_assured_outcome = 'N'
AND s2.premiums_outcome = 'N'
GROUP BY s2.sum_assured_outcome, s2.premiums_outcome

-- In total, there are 440 clients (10.95% out of 4,017 records) whose insured packages are lower than the median and their premiums are lower than the average
-- The clients are paid equivalent to the coverage their received


-- Counting the distribution of packages with respect to the premiums and sum assured
-- Count number of clients when the sum assured and premiums are higher than the median and average respectively
WITH s1 AS (
    SELECT
		CLIENT_CODE,
        TYPE,
		FORMAT(SUM_ASSURED, 'N') AS sum_assured,
        FORMAT(
            PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE),
            'N'
        ) AS median_sum_assured,
		FORMAT(MODAL_PREMIUM, 'N') AS premiums_paid,
        FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N') AS avg_premiums
    FROM dbo.Account
)
SELECT
	s2.sum_assured_outcome,
	COUNT(s2.sum_assured_outcome) AS no_of_clients,
	s2.premiums_outcome,
	COUNT(s2.premiums_outcome) AS no_of_clients
FROM (
	SELECT CASE 
				WHEN s1.sum_assured >= s1.median_sum_assured THEN 'Y'
				ELSE 'N' END AS sum_assured_outcome,
			CASE 
				WHEN s1.premiums_paid >= s1.avg_premiums THEN 'Y'
				ELSE 'N' END AS premiums_outcome
	FROM s1
	) AS s2
WHERE s2.sum_assured_outcome = 'Y'
AND s2.premiums_outcome = 'Y'
GROUP BY s2.sum_assured_outcome, s2.premiums_outcome

-- In total, there are 1,460 clients (36.35% out of 4,017 records) whose insured packages are higher than the median and their premiums are higher than the average
-- This is the standard usual model, assuming this clients are paid equivalent to the coverage their received

-- Count number of clients when the sum assured are higher than the median and premiums are lower than the average
WITH s1 AS (
    SELECT
		CLIENT_CODE,
        TYPE,
		FORMAT(SUM_ASSURED, 'N') AS sum_assured,
        FORMAT(
            PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE),
            'N'
        ) AS median_sum_assured,
		FORMAT(MODAL_PREMIUM, 'N') AS premiums_paid,
        FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N') AS avg_premiums
    FROM dbo.Account
)
SELECT
	s2.sum_assured_outcome,
	COUNT(s2.sum_assured_outcome) AS no_of_clients,
	s2.premiums_outcome,
	COUNT(s2.premiums_outcome) AS no_of_clients
FROM (
	SELECT CASE 
				WHEN s1.sum_assured >= s1.median_sum_assured THEN 'Y'
				ELSE 'N' END AS sum_assured_outcome,
			CASE 
				WHEN s1.premiums_paid >= s1.avg_premiums THEN 'Y'
				ELSE 'N' END AS premiums_outcome
	FROM s1
	) AS s2
WHERE s2.sum_assured_outcome = 'Y'
AND s2.premiums_outcome = 'N'
GROUP BY s2.sum_assured_outcome, s2.premiums_outcome
-- In total, there are 380 clients (9.45% out of 4,017 records) whose insured packages are higher than the median and their premiums are lower than the average
-- Quite significantly low number (disproportionate)
-- This means this set of customers could have been underpriced relative to their coverage
-- Pose a risk to the company should the clients make claims


-- Count number of clients when the sum assured are lower than the median and premiums are higher than the average
WITH s1 AS (
    SELECT
		CLIENT_CODE,
        TYPE,
		FORMAT(SUM_ASSURED, 'N') AS sum_assured,
        FORMAT(
            PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE),
            'N'
        ) AS median_sum_assured,
		FORMAT(MODAL_PREMIUM, 'N') AS premiums_paid,
        FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N') AS avg_premiums
    FROM dbo.Account
)
SELECT
	s2.sum_assured_outcome,
	COUNT(s2.sum_assured_outcome) AS no_of_clients,
	s2.premiums_outcome,
	COUNT(s2.premiums_outcome) AS no_of_clients
FROM (
	SELECT CASE 
				WHEN s1.sum_assured > s1.median_sum_assured THEN 'Y'
				ELSE 'N' END AS sum_assured_outcome,
			CASE 
				WHEN s1.premiums_paid > s1.avg_premiums THEN 'Y'
				ELSE 'N' END AS premiums_outcome
	FROM s1
	) AS s2
WHERE s2.sum_assured_outcome = 'N'
AND s2.premiums_outcome = 'Y'
GROUP BY s2.sum_assured_outcome, s2.premiums_outcome
-- In total, there are 1,736 clients (43.22% out of 4,017 records) whose insured packages are lower than the median and their premiums are higher than the average
-- Quite significantly high number (disproportionate) 
-- This means this set of customers could have been underpaid for less amount of coverage

-- Overall, it seems that the company does not charge the premiums proportionally for much larger coverage
-- Other potential risk from this could be underpricing for high-value policies
-- Discounting other factors in the clients profile (high-net worth, limited financial capacities, etc.)
-- Therefore, this presents a case study or strategy to optimize product design for the company 
-- But, further analysis is needed on the clients profiles (claim histories, clients demographics, frequency of payment and other risk factors)

-- Potential financial revenues from charging premiums, extrapolating with the mode of payment (frequency)
-- Considering only eligible policy status and when policies are enforced (MODE > 0)
WITH s2 AS (
    SELECT
		CLIENT_CODE,
        TYPE,
		POLICY_STATUS,
		PAYMENT_MODE,
		SUM_ASSURED AS sum_assured,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE) AS median_sum_assured,
		MODAL_PREMIUM AS premiums_paid,
		AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE)AS avg_premiums,
		MODAL_PREMIUM * PAYMENT_MODE AS cum_premiums_paid,
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY MODAL_PREMIUM * PAYMENT_MODE) OVER (PARTITION BY TYPE) AS median_cum_premiums_paid
    FROM dbo.Account
)
SELECT 
	TYPE,
	FORMAT(SUM(premiums_paid), 'N') AS premiums_paid,
	FORMAT(SUM(cum_premiums_paid), 'N') AS cum_premiums_paid
FROM s2
WHERE POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') -- Determined no premiums nor cash value will be returning to the clients when certain conditions are met
AND PAYMENT_MODE > 0
GROUP BY CUBE (TYPE);
-- Accounting the mode of payments, the total potential premiums to be paid by clients amounts to RM 39.65 mil


-- Potential premiums as cash surrender value back to clients
-- Finding out which type of policies that incurred surrendering cash value to the clients that requested
WITH s2 AS (
    SELECT
		CLIENT_CODE,
        TYPE,
		POLICY_STATUS,
		PAYMENT_MODE,
		SUM_ASSURED AS sum_assured,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE) AS median_sum_assured,
		MODAL_PREMIUM AS premiums_paid,
		AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE)AS avg_premiums,
		MODAL_PREMIUM * PAYMENT_MODE AS cum_premiums_paid,
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY MODAL_PREMIUM * PAYMENT_MODE) OVER (PARTITION BY TYPE) AS median_cum_premiums_paid
    FROM dbo.Account
)
SELECT 
	TYPE,
	COUNT(*),
	FORMAT(SUM(premiums_paid), 'N') AS premiums_paid,
	FORMAT(SUM(cum_premiums_paid), 'N') AS cum_premiums_paid
FROM s2
WHERE POLICY_STATUS LIKE '%SURRENDER%' -- Matches string with the character SURRENDER 
GROUP BY CUBE (TYPE);
-- In this case, 34 clients who had surrendered their policies, which in turn the company is obliged to return cash surrender value of potentially RM 382k back to the clients
-- Interestingly, the type of policies in this result belongs to TYPE E

-- Finding out the account details for duplicated records (or clients with multiple records)
SELECT
	CLIENT_CODE,
	COUNT(*) AS 'No_of_Plans_Subscribed',
	FORMAT(MAX(SUM_ASSURED), 'N') AS 'Latest_Sum_Assured',
	FORMAT(MAX(MODAL_PREMIUM), 'N') AS ' Latest_Premiums_Paid',
	MAX(ISSUE_DATE) AS 'Latest_Date_of_Issuance'-- don't forget to include the latest, enfored date
FROM dbo.Account
GROUP BY CLIENT_CODE
HAVING COUNT(*) > 1
-- About 104 unique clients whose had multiple policies

/* dbo.Customer */
-- For this exercise, a JOIN table is needed, using CLIENT_CODE as FK to connect the two tables
-- Check the cardinality of these two table, to determine that the Customer Table can be regarded as DIM table
SELECT 
	CLIENT_CODE,
	COUNT(*)
FROM dbo.Customer
GROUP BY CLIENT_CODE
HAVING COUNT(*) > 1
-- Seems there are multiple records detected here with duplication

-- Age Groups by Count and Percentages
SELECT 
	AGE,
	COUNT(*) AS age_count,
	CAST (COUNT(*) * 100.00 / (
				SELECT COUNT(*)
				FROM dbo.Account
				) AS decimal(10,2)) AS age_percent
FROM dbo.Customer
GROUP BY AGE
ORDER BY age_percent DESC;
-- As calculated in Python, the numbers and % checks out too

-- Genders by Count and Percentages
SELECT 
	GENDER,
	COUNT(*) AS gender_count,
	CAST (COUNT(*) * 100.00 / (
				SELECT COUNT(*)
				FROM dbo.Account
				) AS decimal(10,2)) AS gender_percent
FROM dbo.Customer
GROUP BY GENDER
ORDER BY gender_percent DESC;
-- As calculated in Python, the numbers and % checks out too

-- Marital Stastus by Count and Percentages
SELECT 
	MARITAL_STATUS,
	COUNT(*) AS status_count,
	CAST (COUNT(*) * 100.00 / (
				SELECT COUNT(*)
				FROM dbo.Account
				) AS decimal(10,2)) AS status_percent
FROM dbo.Customer
GROUP BY MARITAL_STATUS
ORDER BY status_percent DESC;
-- As calculated in Python, the numbers and % checks out too

-- Filter records for when no customer
SELECT *
FROM dbo.Customer AS c
FULL OUTER JOIN dbo.Account AS a
ON c.CLIENT_CODE = a.CLIENT_CODE
WHERE c.CLIENT_CODE IS NULL
OR a.CLIENT_CODE IS NULL
-- CLIENT_CODE 2 does not have any records stored in the dbo.Account


-- Calculate the statistics for Income
WITH summary_statistcs AS (
	SELECT
		INCOME,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY INCOME) OVER () AS median_income
	FROM dbo.Customer
	)
SELECT 
	AVG(INCOME),
	median_income
FROM summary_statistcs
GROUP BY median_income


-- Average and median Income by Age, Gender and Marital Status
-- We know that income is not normally distributed (highly skewed)...
WITH c1 AS (
	SELECT
		CLIENT_CODE,
		AGE,
		GENDER,
		MARITAL_STATUS,
		INCOME,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY INCOME) OVER(PARTITION BY AGE, GENDER, MARITAL_STATUS) AS median_income_group
	FROM dbo.Customer
	GROUP BY CLIENT_CODE, AGE, GENDER, MARITAL_STATUS, INCOME
	)
SELECT 
	AGE,
	GENDER,
	MARITAL_STATUS,
	COUNT(*) AS no_of_clients,
	CAST(ROUND(AVG(INCOME),0) AS INT) AS avg_income,
	CAST(median_income_group AS INT) AS median_income
FROM c1
GROUP BY AGE, GENDER, MARITAL_STATUS, median_income_group
ORDER BY median_income_group DESC, COUNT(*) DESC
-- Age Segment B, Gender M and Marital Status as S is the most common group
-- Age Group C, Gender F and with R as Marital status have highest average income and median income but that's due having 1 personal
-- With only so few clients under the R Marital Status, their median income is significantly higher than overall population (median = RM 60k)

-- Find out the policies that these clients have subscribed to or used to...
-- Since this table has clients reported their updates on incomes, index the record and filter by index = 1
SELECT 
	c.CLIENT_CODE, 
	POLICY_NUMBER, 
	PLAN_CODE, 
	c.AGE, 
	c.MARITAL_STATUS,
	c.INCOME, 
	SUM_ASSURED, 
	MODAL_PREMIUM, 
	ISSUE_DATE, 
	TYPE, 
	POLICY_STATUS, 
	SURRENDER_DATE, 
	PAYMENT_MODE
FROM (
	SELECT
		CLIENT_CODE,
		AGE,
		MARITAL_STATUS,
		GENDER,
		POSTCODE,
		LASTUPDATE,
		INCOME,
		ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
	FROM dbo.Customer
	) AS c
LEFT JOIN dbo.Account as a
ON c.CLIENT_CODE = a.CLIENT_CODE
WHERE c.rn = 1

-- Find out which sets of clients that have their current policies of which secures permanent premiums (or currently) by their Age
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	COUNT(*) AS no_of_clients,
	TYPE,
	AGE, 
	FORMAT(SUM(MODAL_PREMIUM), 'N') AS premiums,
	FORMAT(SUM(TOTAL_PREMIUM), 'N') AS total_premiums,
	CAST(COUNT(*) *100 / (SELECT COUNT (*) FROM complete WHERE complete.POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') ) AS DECIMAL(10,2)) AS 'percent'
FROM complete
WHERE complete.POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') 
GROUP BY ROLLUP (TYPE, AGE)
ORDER BY TYPE
-- Based on previous analysis, Type E (premiums worht of RM 3.7 mil ~ 65% of the total group) secured the highest total_premiums to date, considering their policy status does not require surrendering the cash value
--- Age Group B have the highest premium in this Type E category (RM 1.2 mil) 
-- Second would be Type A (RM 1.74 mil ~ 30% of the total group)
--- Age Group B have the highest premium in this Type A category (RM 618k)

-- Find out which sets of clients that have their current policies of which secures permanent premiums (or currently) by their MARITAL_STATUS
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	COUNT(*) AS no_of_clients,
	TYPE,
	MARITAL_STATUS, 
	FORMAT(SUM(MODAL_PREMIUM), 'N') AS premiums,
	FORMAT(SUM(TOTAL_PREMIUM), 'N') AS total_premiums,
	CAST(COUNT(*) *100 / (SELECT COUNT (*) FROM complete WHERE complete.POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') ) AS DECIMAL(10,2)) AS 'percent'
FROM complete
WHERE complete.POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') 
GROUP BY ROLLUP (TYPE, MARITAL_STATUS)
ORDER BY TYPE
-- As per usual, Type E contributes the highest premium 
--- Within that segment, 'M' status (RM 2.21 mil) is the highest contributor
-- Type A came second
--- Within that segment, 'M' status (RM 869 k) is the highest contributor

-- Find out which sets of clients that have their current policies of which secures permanent premiums (or currently) by their MARITAL_STATUS
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.GENDER, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	COUNT(*) AS no_of_clients,
	TYPE,
	GENDER, 
	FORMAT(SUM(MODAL_PREMIUM), 'N') AS premiums,
	FORMAT(SUM(TOTAL_PREMIUM), 'N') AS total_premiums,
	CAST(COUNT(*) *100 / (SELECT COUNT (*) FROM complete WHERE complete.POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') ) AS DECIMAL(10,2)) AS 'percent'
FROM complete
WHERE complete.POLICY_STATUS IN ('IN-FORCE','EXPIRED','TERMINATED(PR)') 
GROUP BY ROLLUP (TYPE, GENDER)
ORDER BY TYPE
-- Gender 'M' in type A  have the highest count and premiums to be paid in general
-- Gender 'F' contributes highest premium in the type E, C and D 

-- Onto the total coverage analysis
-- Find out which sets of clients that have surrender surrender their policies by Age
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	COUNT(*) AS no_of_clients,
	TYPE,
	AGE, 
	FORMAT(SUM(MODAL_PREMIUM), 'N') AS premiums,
	FORMAT(SUM(TOTAL_PREMIUM), 'N') AS total_premiums,
	CAST(COUNT(*) *100 / (SELECT COUNT (*) FROM complete WHERE complete.POLICY_STATUS LIKE '%SURRENDER%' ) AS DECIMAL(10,2)) AS 'percent'
FROM complete
WHERE complete.POLICY_STATUS LIKE '%SURRENDER%'
GROUP BY ROLLUP (TYPE, AGE)
ORDER BY TYPE
-- Age Group B and C are the most common age groups to surrender their policies

-- Find out which sets of clients that have surrender surrender their policies by Gender
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.GENDER, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	COUNT(*) AS no_of_clients,
	TYPE,
	GENDER, 
	FORMAT(SUM(MODAL_PREMIUM), 'N') AS premiums,
	FORMAT(SUM(TOTAL_PREMIUM), 'N') AS total_premiums,
	CAST(COUNT(*) *100 / (SELECT COUNT (*) FROM complete WHERE complete.POLICY_STATUS LIKE '%SURRENDER%' ) AS DECIMAL(10,2)) AS 'percent'
FROM complete
WHERE complete.POLICY_STATUS LIKE '%SURRENDER%'
GROUP BY ROLLUP (TYPE, GENDER)
ORDER BY TYPE
-- Gender 'M' in type A  have the highest count and premiums to be paid in general
-- Gender 'F' contributes highest premium in the type E, C and D 

-- Find out which sets of clients that have surrender surrender their policies by Martial Status
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	COUNT(*) AS no_of_clients,
	TYPE,
	MARITAL_STATUS, 
	FORMAT(SUM(MODAL_PREMIUM), 'N') AS premiums,
	FORMAT(SUM(TOTAL_PREMIUM), 'N') AS total_premiums,
	CAST(COUNT(*) *100 / (SELECT COUNT (*) FROM complete WHERE complete.POLICY_STATUS LIKE '%SURRENDER%' ) AS DECIMAL(10,2)) AS 'percent'
FROM complete
WHERE complete.POLICY_STATUS LIKE '%SURRENDER%'
GROUP BY ROLLUP (TYPE, MARITAL_STATUS)
ORDER BY TYPE
-- Type E is the most popular type of policy of which the 'M' marital status contributes 64% of the premiums surrendered

-- Income and the correlation with the Types of Policies
-- Income Distribution
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
    COUNT(CASE WHEN INCOME >= 0 AND INCOME < 50000 THEN 1 END) AS [0 - 49999],
    COUNT(CASE WHEN INCOME >= 50000 AND INCOME < 100000 THEN 1 END) AS [50000 - 99999],
    COUNT(CASE WHEN INCOME >= 100000 AND INCOME < 150000 THEN 1 END) AS [100000 - 149999],
    COUNT(CASE WHEN INCOME >= 150000 AND INCOME < 200000 THEN 1 END) AS [150000 - 199999],
    COUNT(CASE WHEN INCOME >= 200000 AND INCOME < 250000 THEN 1 END) AS [200000 - 249999],
    COUNT(CASE WHEN INCOME >= 250000 AND INCOME < 300000 THEN 1 END) AS [250000 - 299999],
    COUNT(CASE WHEN INCOME >= 300000 AND INCOME < 350000 THEN 1 END) AS [300000 - 349999],
    COUNT(CASE WHEN INCOME >= 350000 AND INCOME < 400000 THEN 1 END) AS [350000 - 399999],
    COUNT(CASE WHEN INCOME >= 400000 AND INCOME < 450000 THEN 1 END) AS [400000 - 449999],
    COUNT(CASE WHEN INCOME >= 450000 AND INCOME < 500000 THEN 1 END) AS [450000 - 499999],
    COUNT(CASE WHEN INCOME >= 500000 THEN 1 END) AS [500000 and above]
FROM complete
-- As confirmed in Python and previous analysis, some of the clients are earning on the median income of RM 60,000 (annual)

-- Does level of Income influences the type of policies subscribed to (Type of Policy, Sum of Insured, etc.)
WITH complete AS (
	SELECT 
		c.CLIENT_CODE, POLICY_NUMBER, PLAN_CODE, c.AGE, c.MARITAL_STATUS,c.INCOME, SUM_ASSURED, MODAL_PREMIUM, ISSUE_DATE, TYPE, POLICY_STATUS, SURRENDER_DATE, PAYMENT_MODE,
		(MODAL_PREMIUM * PAYMENT_MODE) AS TOTAL_PREMIUM
	FROM (
		SELECT
			CLIENT_CODE,
			AGE,
			MARITAL_STATUS,
			GENDER,
			POSTCODE,
			LASTUPDATE,
			INCOME,
			ROW_NUMBER() OVER (PARTITION BY CLIENT_CODE ORDER BY LASTUPDATE DESC) AS rn
		FROM dbo.Customer
		) AS c
	LEFT JOIN dbo.Account as a
	ON c.CLIENT_CODE = a.CLIENT_CODE
	WHERE c.rn = 1
)
SELECT
	DISTINCT TYPE,
	mean_income = FORMAT(AVG(INCOME) OVER (PARTITION BY TYPE), 'N'),
	median_income = FORMAT(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY INCOME) OVER (PARTITION BY TYPE), 'N'),
	mean_premium = FORMAT(AVG(MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N'),
	median_premium = FORMAT(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY MODAL_PREMIUM) OVER (PARTITION BY TYPE), 'N'),
	mean_coverage = FORMAT(AVG(SUM_ASSURED) OVER (PARTITION BY TYPE), 'N'),
	median_coverage = FORMAT(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY SUM_ASSURED) OVER (PARTITION BY TYPE), 'N')
FROM complete 
ORDER BY mean_income DESC, median_income DESC;
-- Clients whose subscribed for Type C and Type D still have their premiums paid out even though most, if not all, of them do not have an income
-- Policy Type C includes to those do not have an income, possibly children/parents, Key Persons or Third Parties whose premiums are paid by someone else
-- Policy Type D also includes those that have been described above, with few of them actual earning some Income
-- To date, Type C has the highest coverage compared to the rest
-- While Type E and A, which possibly contains clients in the working class group, do not have high insurance coverage compared to Type C or Type D
