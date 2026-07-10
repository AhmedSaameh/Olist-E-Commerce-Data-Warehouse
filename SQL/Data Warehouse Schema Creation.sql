
Create table Dim_product
(
	productID_SK int primary key identity(1,1),
	productID_BK nvarchar(50) not null,
	product_category_name nvarchar(50),
	product_category_name_english nvarchar(50)
)

GO

Create table Dim_seller 
(
	sellerID_SK int primary key identity(1,1),
	sellerID_BK nvarchar(50) not null,
	seller_zip_code_prefix int,
	seller_city nvarchar(50),
	seller_state nvarchar(50),
	seller_geolocation_lat float,
	seller_geolocation_lng float
)

GO

Create table Dim_customer
(
	customerID_SK int primary key identity(1,1),
	customerID_BK nvarchar(50) not null,
	customer_zip_code_prefix int,
	customer_city nvarchar(50),
	customer_state nvarchar(50),
	customer_geolocation_lat float,
	customer_geolocation_lng float
)

GO

create table Dim_order_payments
(
	paymentID_SK int primary key identity(1,1),
	payment_sequential tinyint,
	orderID_BK nvarchar(50),
	payment_type nvarchar(50),
	payment_installments tinyint,
)

GO

BEGIN TRY
 DROP TABLE [Dim_Date];
END TRY
BEGIN CATCH
 -- DO NOTHING
END CATCH;

CREATE TABLE [dbo].[Dim_Date] (
 [Date_SK] int NOT NULL, -- بصيغة YYYYMMDD
 [Date] date NOT NULL,
 [Day] char(2) NOT NULL,
 [DaySuffix] varchar(4) NOT NULL,
 [DayOfWeek] varchar(9) NOT NULL,
 [DOWInMonth] tinyint NOT NULL,
 [DayOfYear] int NOT NULL,
 [WeekOfYear] tinyint NOT NULL,
 [WeekOfMonth] tinyint NOT NULL,
 [Month] char(2) NOT NULL,
 [MonthName] varchar(9) NOT NULL,
 [Quarter] tinyint NOT NULL,
 [QuarterName] varchar(6) NOT NULL,
 [Year] char(4) NOT NULL,
 [StandardDate] varchar(10) NULL,
 [Holiday_name_en] varchar(50) NULL,
 CONSTRAINT [PK_Dim_Date] PRIMARY KEY CLUSTERED ([Date_SK])
);

TRUNCATE TABLE Dim_Date;

DECLARE @tmpDOW TABLE (DOW INT, Cntr INT);
INSERT INTO @tmpDOW(DOW, Cntr) VALUES (1,0),(2,0),(3,0),(4,0),(5,0),(6,0),(7,0);

DECLARE @StartDate datetime = '2015-01-01';
DECLARE @EndDate datetime = '2025-01-01'; -- non-inclusive
DECLARE @Date datetime = @StartDate;
DECLARE @WDofMonth INT;
DECLARE @CurrentMonth INT = MONTH(@StartDate);

WHILE @Date < @EndDate
BEGIN
 IF MONTH(@Date) <> @CurrentMonth
 BEGIN
  SET @CurrentMonth = MONTH(@Date);
  UPDATE @tmpDOW SET Cntr = 0;
 END

 UPDATE @tmpDOW SET Cntr = Cntr + 1 WHERE DOW = DATEPART(WEEKDAY, @Date);
 SELECT @WDofMonth = Cntr FROM @tmpDOW WHERE DOW = DATEPART(WEEKDAY, @Date);

 INSERT INTO Dim_Date (
  Date_SK, Date, Day, DaySuffix, DayOfWeek, DOWInMonth, DayOfYear,
  WeekOfYear, WeekOfMonth, Month, MonthName, Quarter, QuarterName, Year
 )
 SELECT 
  CONVERT(varchar, @Date, 112),
  @Date,
  RIGHT('0' + CAST(DAY(@Date) AS varchar), 2),
  CASE 
   WHEN DAY(@Date) IN (11,12,13) THEN CAST(DAY(@Date) AS varchar) + 'th'
   WHEN RIGHT(CAST(DAY(@Date) AS varchar),1) = '1' THEN CAST(DAY(@Date) AS varchar) + 'st'
   WHEN RIGHT(CAST(DAY(@Date) AS varchar),1) = '2' THEN CAST(DAY(@Date) AS varchar) + 'nd'
   WHEN RIGHT(CAST(DAY(@Date) AS varchar),1) = '3' THEN CAST(DAY(@Date) AS varchar) + 'rd'
   ELSE CAST(DAY(@Date) AS varchar) + 'th'
  END,
  DATENAME(WEEKDAY, @Date),
  @WDofMonth,
  DATEPART(DAYOFYEAR, @Date),
  DATEPART(WEEK, @Date),
  DATEPART(WEEK, @Date) + 1 - DATEPART(WEEK, CAST(CAST(MONTH(@Date) AS varchar) + '/1/' + CAST(YEAR(@Date) AS varchar) AS datetime)),
  RIGHT('0' + CAST(MONTH(@Date) AS varchar), 2),
  DATENAME(MONTH, @Date),
  DATEPART(QUARTER, @Date),
  CASE DATEPART(QUARTER, @Date)
   WHEN 1 THEN 'First'
   WHEN 2 THEN 'Second'
   WHEN 3 THEN 'Third'
   WHEN 4 THEN 'Fourth'
  END,
  CAST(YEAR(@Date) AS char(4));

 SET @Date = DATEADD(DAY, 1, @Date);
END;

-- Format standard date (MM/DD/YYYY)
UPDATE Dim_Date
SET StandardDate = [Month] + '/' + [Day] + '/' + [Year];

-- ✅ Optional: Add US holidays
-- Example: New Year's Day
UPDATE Dim_Date SET Holiday_name_en = 'New Year''s Day' WHERE Month = '01' AND Day = '01';
UPDATE Dim_Date SET Holiday_name_en = 'Valentine''s Day' WHERE Month = '02' AND Day = '14';
UPDATE Dim_Date SET Holiday_name_en = 'Independence Day' WHERE Month = '07' AND Day = '04';
UPDATE Dim_Date SET Holiday_name_en = 'Halloween' WHERE Month = '10' AND Day = '31';
UPDATE Dim_Date SET Holiday_name_en = 'Christmas Day' WHERE Month = '12' AND Day = '25';

-- Example: Thanksgiving (4th Thursday of November)
UPDATE Dim_Date
SET Holiday_name_en = 'Thanksgiving Day'
WHERE Month = '11' AND DayOfWeek = 'Thursday' AND DOWInMonth = 4;

-- ✅ Add any other local holidays manually if حابب تعمل dimension for مصر أو غيرها.

-- ✅ Optional indexes
CREATE INDEX IDX_Dim_Date_Year ON Dim_Date ([Year]);
CREATE INDEX IDX_Dim_Date_Month ON Dim_Date ([Month]);
CREATE INDEX IDX_Dim_Date_StandardDate ON Dim_Date ([StandardDate]);
CREATE INDEX IDX_Dim_Date_Holiday ON Dim_Date ([Holiday_name_en]);

PRINT 'Done at: ' + CONVERT(varchar, GETDATE(), 113);



GO


SET ANSI_PADDING OFF;
BEGIN TRY
 DROP TABLE [Dim_Time];
END TRY
BEGIN CATCH
 --DO NOTHING
END CATCH;

CREATE TABLE [dbo].[Dim_Time] (
 [Time_SK] int IDENTITY(1,1) NOT NULL,
 [Time] time(0) NOT NULL,
 [Hour] char(2) NOT NULL,
 [MilitaryHour] char(2) NOT NULL,
 [Minute] char(2) NOT NULL,
 [Second] char(2) NOT NULL,
 [AmPm] char(2) NOT NULL,
 [StandardTime] char(11) NULL,
 CONSTRAINT [PK_Dim_Time] PRIMARY KEY CLUSTERED (
  [Time_SK] ASC
 ) WITH (
  PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
 ) ON [PRIMARY]
) ON [PRIMARY];

GO
SET ANSI_PADDING OFF;

PRINT CONVERT(varchar, GETDATE(), 113); -- Start time

-- Load time data for every second of the day
DECLARE @Time datetime;
SET @Time = '00:00:00';

TRUNCATE TABLE [Dim_Time];

WHILE @Time <= '23:59:59'
BEGIN
 INSERT INTO [dbo].[Dim_Time] ([Time], [Hour], [MilitaryHour], [Minute], [Second], [AmPm])
 SELECT 
  CONVERT(varchar, @Time, 108),
  CASE 
   WHEN DATEPART(HOUR, @Time) = 0 THEN 12
   WHEN DATEPART(HOUR, @Time) > 12 THEN DATEPART(HOUR, @Time) - 12
   ELSE DATEPART(HOUR, @Time)
  END,
  RIGHT('0' + CAST(DATEPART(HOUR, @Time) AS varchar), 2),
  RIGHT('0' + CAST(DATEPART(MINUTE, @Time) AS varchar), 2),
  RIGHT('0' + CAST(DATEPART(SECOND, @Time) AS varchar), 2),
  CASE WHEN DATEPART(HOUR, @Time) >= 12 THEN 'PM' ELSE 'AM' END;

 SET @Time = DATEADD(SECOND, 1, @Time);
END;

-- Fix formatting
UPDATE [Dim_Time] SET [Hour] = '0' + [Hour] WHERE LEN([Hour]) = 1;
UPDATE [Dim_Time] SET [Minute] = '0' + [Minute] WHERE LEN([Minute]) = 1;
UPDATE [Dim_Time] SET [Second] = '0' + [Second] WHERE LEN([Second]) = 1;
UPDATE [Dim_Time] SET [MilitaryHour] = '0' + [MilitaryHour] WHERE LEN([MilitaryHour]) = 1;

UPDATE [Dim_Time]
SET [StandardTime] = 
  CASE WHEN [Hour] = '00' THEN '12' ELSE [Hour] END + ':' + [Minute] + ':' + [Second] + ' ' + [AmPm]
WHERE [StandardTime] IS NULL;

-- Create indexes
CREATE UNIQUE NONCLUSTERED INDEX [IDX_Dim_Time_Time] ON [dbo].[Dim_Time] ([Time]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_Hour] ON [dbo].[Dim_Time] ([Hour]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_MilitaryHour] ON [dbo].[Dim_Time] ([MilitaryHour]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_Minute] ON [dbo].[Dim_Time] ([Minute]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_Second] ON [dbo].[Dim_Time] ([Second]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_AmPm] ON [dbo].[Dim_Time] ([AmPm]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_StandardTime] ON [dbo].[Dim_Time] ([StandardTime]);

PRINT CONVERT(varchar, GETDATE(), 113); -- End time


-- We add a new row in dim date & time to can lookup rows with NULL values 

-- Dim_Date
INSERT INTO Dim_Date 
(Date_SK, Date, Day, DaySuffix, DayOfWeek, DOWInMonth, DayOfYear,
 WeekOfYear, WeekOfMonth, Month, MonthName, Quarter, QuarterName, 
 Year, StandardDate, Holiday_name_en) 
VALUES 
(-1, '1900-01-01', '01', '1st', 'N/A', 0, 0, 0, 0, 
 '01', 'N/A', 0, 'N/A', '1900', 'N/A', NULL)





Create table Fact_orders
(
	order_item_SK int primary key identity(1,1),
	orderID_BK nvarchar(50) not null,
	order_item_BK tinyint not null,

	customerID_FK int not null,
	sellerID_FK int not null,
	productID_FK int not null,
	paymentID_FK int not null,


	
	purchase_date_FK int not null,
	purchase_time_FK int not null,
	approved_date_FK int not null,
	approved_time_FK int not null,
	carrier_date_FK int not null,
	carrier_time_FK int not null,
	delivered_date_FK int not null,
	delivered_time_FK int not null,
	estimated_date_FK int not null,
	estimated_time_FK int not null,


	price float ,
	freight_value float,
	order_status nvarchar(50),

	constraint FK_customer foreign key (customerID_FK) references dim_customer(customerID_SK),
	constraint FK_seller foreign key (sellerID_FK) references dim_seller(sellerID_SK),
	constraint FK_product foreign key (productID_FK) references dim_product(productID_SK),
	constraint FK_payment foreign key (paymentID_FK) references dim_order_payments(paymentID_SK),



	constraint FK_purchase_date foreign key (purchase_date_FK) references dim_date(date_SK),
	constraint FK_purchase_time foreign key (purchase_time_FK) references dim_time(time_SK),

	constraint FK_approved_date foreign key (approved_date_FK) references dim_date(date_SK),
	constraint FK_approved_time foreign key (approved_time_FK) references dim_time(time_SK),
	
	constraint FK_carrier_date foreign key (carrier_date_FK) references dim_date(date_SK),
	constraint FK_carrier_time foreign key (carrier_time_FK) references dim_time(time_SK),

	constraint FK_delivered_date foreign key (delivered_date_FK) references dim_date(date_SK),
	constraint FK_delivered_time foreign key (delivered_time_FK) references dim_time(time_SK),
	
	constraint FK_estimated_date foreign key (estimated_date_FK) references dim_date(date_SK),
	constraint FK_estimated_time foreign key (estimated_time_FK) references dim_time(time_SK)
)


Create table Fact_reviews
(
    reviewID_SK      int primary key identity(1,1),
    reviewID_BK      nvarchar(50),
    orderID_BK       nvarchar(50),
    customerID_FK    int,
    review_date_FK   int,  
    review_time_FK   int, 
    -- Measures
    review_score     tinyint,

	constraint FK_review_customer foreign key (customerID_FK) references Dim_Customer(customerID_SK),
    constraint FK_review_date foreign key (review_date_FK) references Dim_Date(Date_SK),
    constraint FK_review_time foreign key (review_time_FK) references Dim_Time(Time_SK)
)
