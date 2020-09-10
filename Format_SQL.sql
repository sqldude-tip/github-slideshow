--WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!
/*
template for creating TSQL script to user with SQLCMD tool
*/
GO

SET ANSI_NULLS
	,ANSI_PADDING
	,ANSI_WARNINGS
	,ARITHABORT
	,CONCAT_NULL_YIELDS_NULL
	,QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

:setvar SQLServerName "<SQLServerName, sysname, SQLServerName>" :setvar DatabaseName "<DatabaseName, sysname, DatabaseName>" :setvar ScriptPath "<ScriptPath, sysname, ScriptPath>" :setvar OutputPath "<OutputPath, sysname, OutputPath>" :setvar LogPath "<LogPath, sysname, LogPath>"
GO

:on error EXIT
GO

/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO

IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
BEGIN
	PRINT N'SQLCMD mode must be enabled to successfully execute this script.';

	SET NOEXEC ON;
END
GO

:connect $( SQLServerName )
GO

USE $( DatabaseName )
GO

SET NOCOUNT ON;

PRINT '-- [' + convert(VARCHAR(19), current_timestamp, 120) + '] Executed against: ' + convert(VARCHAR(25), @@ServerName)

-- Add your scripts below
-- Billing
BEGIN TRANSACTION

--cleanse the data in Billing first
UPDATE [SLV_Load_Staging].[dbo].[BILLING]
SET [DATE_OF_DEPOSIT] = '19000101'
WHERE [DATE_OF_DEPOSIT] = '000000'
	OR [DATE_OF_DEPOSIT] = '0000'
	OR [DATE_OF_DEPOSIT] = '00'
	OR [DATE_OF_DEPOSIT] IS NULL

-- Insert the table
TRUNCATE TABLE [dbo].[billing];

INSERT INTO [dbo].[billing] (
	[symbol]
	,[policy_number]
	,[module]
	,[due_date]
	,[account_transaction]
	,[receipt_transaction]
	,[amount_due]
	,[amount_received]
	,[date_of_last_notice]
	,[deposit_date]
	,[bill_id]
	,[base_bill_date_yymmdd]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[DUE_DATE]
	,[ACCOUNT_TRANSACTION]
	,[RECEIPT_TRANSACTION]
	,[AMOUNT_DUE]
	,[AMOUNT_RECEIVED]
	,convert(DATETIME, [DATE_OF_LAST_NOTICE], 111) AS [DATE_OF_LAST_NOTICE]
	,convert(DATETIME, [DATE_OF_DEPOSIT], 111) AS [DATE_OF_DEPOSIT]
	,[ID]
	,[BASE_BILL_DATE]
FROM [SLV_Load_Staging].[dbo].[BILLING];

--SELECT TOP 100 * FROM [dbo].[BILLING];
IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

--  BIMPITH
BEGIN TRANSACTION

TRUNCATE TABLE [dbo].[billingsummary];

INSERT INTO [dbo].[billingsummary] (
	[symbol]
	,[policy_number]
	,[module]
	,[total_premium]
	,[total_paid]
	,[total_refunded]
	,[non_cash_adjusted]
	,[to_pay_in_full]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[TOTAL_PREMIUM]
	,[TOTAL_PAID]
	,[TOTAL_REFUNDED]
	,[TO_PAY_IN_FULL]
	,[NON_CASH_ADJUSTED]
FROM [SLV_Load_Staging].[dbo].[BIMPITH]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- Comments
BEGIN TRANSACTION

INSERT INTO [dbo].[comments] (
	[symbol]
	,[policy_number]
	,[module]
	,[reason_suspended]
	,[suspense_date]
	,[requested_by]
	,[comment]
	,[segment_part_code]
	,[type_request]
	,[dest_branch]
	,[dest]
	,[seq]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[REASON_SUSPENDED]
	,[SUSPENSE_DATE]
	,[REQUESTED_BY]
	,[AREA]
	,[SEGMENT_PART_CD]
	,[TYPE_REQUEST]
	,[DEST_BRANCH]
	,[DEST]
	,[SEQ]
FROM [SLV_Load_Staging].[dbo].[COMMENT]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- [dwellingpropertyinterests]
BEGIN TRANSACTION

TRUNCATE TABLE [dbo].[dwellingpropertyinterests];

INSERT INTO [dbo].[dwellingpropertyinterests] (
	[symbol]
	,[policy_number]
	,[module]
	,[unit_number]
	,[use_code]
	,[seq]
	,[zip_code]
	,[description_1]
	,[description_2]
	,[description_3]
	,[description_4]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[UNIT_NUMBER]
	,[USE_CODE]
	,[SEQUENCE]
	,LEFT([DESC_ZIP_CODE], 5)
	,[DESC_LINE_1]
	,[DESC_LINE_2]
	,[DESC_LINE_3]
	,[DESC_LINE_4]
FROM [SLV_Load_Staging].[dbo].[FIRE_MORTGAGEE]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- [dwellingproperty]
BEGIN TRANSACTION

UPDATE [SLV_Load_Staging].[dbo].[FIRE_RATING]
SET [inspection_year] = REPLACE([inspection_year], '^', '');

TRUNCATE TABLE [dbo].[dwellingproperty];

INSERT INTO [dbo].[dwellingproperty] (
	[symbol]
	,[policy_number]
	,[module]
	,[state_code]
	,[address_1]
	,[address_2]
	,[address_3]
	,[address_4]
	,[form_type]
	,[occupancy]
	,[construction]
	,[number_of_families]
	,[construction_year]
	,[fire_station]
	,[hydrant]
	,[protection_class]
	,[inspection_year]
	,[unit_number]
	,[zip_code]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[LOCATION_STATE]
	,[ADDR_LINE1]
	,[ADDR_LINE2]
	,[ADDR_LINE3]
	,[ADDR_LINE4]
	,[FORM]
	,[OCCUPANCY]
	,[CONSTRUCTION]
	,[NUMBER_OF_FAMILIES]
	,[YEAR_OF_CONSTRUCTION]
	,[FILE_STATION]
	,[HYDRANT]
	,[PROTECTION_CLASS]
	,[INSPECTION_YEAR]
	,[UNIT_NUMBER]
	,[ZIP_CODE]
FROM [SLV_Load_Staging].[dbo].[FIRE_RATING]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- [dbo].[coverage]
BEGIN TRANSACTION

TRUNCATE TABLE [dbo].[coverage];

INSERT INTO [dbo].[coverage] (
	[symbol]
	,[policy_number]
	,[module]
	,[unit_number]
	,[coverage_type]
	,[ded]
	,[limit]
	,[premium]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[UNIT_NUMBER]
	,[COVERAGE_TYPE]
	,[COVERAGE_DED]
	,[COVER_LIMIT]
	,[COVERAGE_PREM]
FROM [SLV_Load_Staging].[dbo].[MARINER_COVERAGE]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- [dbo].[coverage];
BEGIN TRANSACTION

TRUNCATE TABLE [dbo].[discountsandcharges];

INSERT INTO [dbo].[discountsandcharges] (
	[symbol]
	,[policy_number]
	,[module]
	,[unit_number]
	,[description]
	,[disc_or_charge]
	,[amount]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[UNIT_NUMBER]
	,[DISC_SURC_DESC]
	,[DISC_SURC]
	,[DISC_SURC_PREM]
FROM [SLV_Load_Staging].[dbo].[MARINER_DISCOUNT]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- [dbo].[mariner]
BEGIN TRANSACTION

TRUNCATE TABLE [dbo].[mariner];

INSERT INTO [dbo].[mariner] (
	[symbol]
	,[policy_number]
	,[module]
	,[unit_number]
	,[unit_group]
	,[unit_type]
	,[horsepower]
	,[outboard_type]
	,[hull_length]
	,[mariner_use]
	,[serial_number]
	,[survey_information]
	,[survey_year]
	,[operatornames]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[UNIT_NUMBER]
	,[UNIT_GROUP]
	,[UNIT_TYPE]
	,[HOURSEPOWER]
	,[OUTBOARD_TYPE]
	,[LENGTH]
	,[USE_CODE]
	,[SERIAL_NUMBER]
	,[SURVEY_REPT]
	,[SURVEY_YR]
	,[OPERATOR_NAMES]
FROM [SLV_Load_Staging].[dbo].[MARINER_RATING]

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

-- [dbo].[policy]
BEGIN TRANSACTION

TRUNCATE TABLE [dbo].[policy];

INSERT INTO [dbo].[policy] (
	[symbol]
	,[policy_number]
	,[module]
	,[effective_date]
	,[expiration_date]
	,[full_agency_number]
	,[producer_code]
	,[phone_num]
	,[pay_service_code]
	,[mode_code]
	,[address_line_1]
	,[address_line_2]
	,[address_line_3]
	,[address_line_4]
	,[zip_code]
	,[eft_date]
	)
SELECT [SYMBOL]
	,[POLICY_NUMBER]
	,[MODULE]
	,[EFFECTIVE_DATE]
	,[EXPIRATION_DATE]
	,[FULL_AGENCY_NUMBER]
	,[PRODUCER_CODE]
	,[PHONE_NUMBER]
	,[PAY_SERVICE_CODE]
	,[MODE_CODE]
	,[ADDRESS_LINE_1]
	,[ADDRESS_LINE_2]
	,[ADDRESS_LINE_3]
	,[ADDRESS_LINE_4]
	,LEFT([ZIP_POSTAL_CODE], 5)
	,[EFTDY]
FROM [SLV_Load_Staging].[dbo].[POLICY]
GO

IF @@ERROR > 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION;

PRINT '-- [' + convert(VARCHAR(19), current_timestamp, 120) + '] Executed against: ' + convert(VARCHAR(25), @@ServerName)
