SELECT TOP (1000) [DateKey]
      ,[Date]
      ,[Year]
      ,[Quarter]
      ,[Month]
      ,[MonthName]
      ,[DayOfMonth]
      ,[DayName]
      ,[IsWeekend]
  FROM [ProjectManagment_DW].[dbo].[DimDate]




SELECT COUNT(*) AS cnt
FROM dbo.DimDate;


SELECT 
    MIN([Date]) AS MinDate,
    MAX([Date]) AS MaxDate
FROM dbo.DimDate;


--чи ун≥кальн≥ дан≥
SELECT COUNT(*) - COUNT(DISTINCT [Date]) AS Duplicates
FROM dbo.DimDate;


--чи DateKey в≥дпов≥даЇ дат≥
SELECT TOP 5 DateKey, [Date]
FROM dbo.DimDate
ORDER BY DateKey;


--„и коректно IsWeekend
SELECT DayName, IsWeekend, COUNT(*) cnt
FROM dbo.DimDate
GROUP BY DayName, IsWeekend
ORDER BY DayName;
