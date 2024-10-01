/*CREATE DATABASE "Hong Leong"
GO*/

/* Create Table for Account */
/*CREATE TABLE dbo.Account (
	POLICY_NUMBER INT PRIMARY KEY NOT NULL,
	PLAN_CODE INT NOT NULL,
	CLIENT_CODE INT NOT NULL,
	SUM_ASSURED DECIMAL NULL,
	MODAL_PREMIUM DECIMAL NULL,
	ISSUE_DATE DATE NOT NULL,
	TYPE CHAR NOT NULL,
	POLICY_STATUS VARCHAR(MAX) NOT NULL,
	SURRENDER_DATE DATE NULL,
	PAYMENT_MODE INT
	)


/* Create Table for Customer */
CREATE TABLE dbo.Customer (
	CLIENT_CODE INT NOT NULL,
	AGE CHAR NOT NULL,
	MARITAL_STATUS CHAR NULL,
	GENDER CHAR NULL,
	INCOME DECIMAL NULL,
	POSTCODE INT NOT NULL,
	LASTUPDATE DATE NOT NULL
	)
*/


/* Use Bulk Insert to populate the table */
TRUNCATE TABLE dbo.Account -- For Safety Measure 
GO

BULK INSERT dbo.Account
FROM 'Insert File\Path Name\Account_cleaned.csv' -- Specify the location of the csv file
WITH
(
	FORMAT = 'CSV',
	FIRSTROW = 2
)
GO

TRUNCATE TABLE dbo.Customer -- For Safety Measure 
GO

BULK INSERT dbo.Customer
FROM 'Insert File\Path Name\Customer_cleaned.csv' -- Specify the location of the csv file
WITH
(
	FORMAT = 'CSV',
	FIRSTROW = 2
)
GO
*/

