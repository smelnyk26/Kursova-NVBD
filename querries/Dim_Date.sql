DECLARE @start DATE = '2020-01-01';
DECLARE @end   DATE = '2025-12-31';

;WITH d AS (
    SELECT @start AS [Date]
    UNION ALL
    SELECT DATEADD(DAY, 1, [Date])
    FROM d
    WHERE [Date] < @end
)
INSERT INTO dbo.DimDate
(
    DateKey,
    [Date],
    [Year],
    [Quarter],
    [Month],
    MonthName,
    DayOfMonth,
    DayName,
    IsWeekend
)
SELECT
    CONVERT(INT, FORMAT([Date], 'yyyyMMdd')) AS DateKey,
    [Date],
    YEAR([Date])                              AS [Year],
    DATEPART(QUARTER, [Date])                 AS [Quarter],
    MONTH([Date])                             AS [Month],
    DATENAME(MONTH, [Date])                   AS MonthName,
    DAY([Date])                               AS DayOfMonth,
    DATENAME(WEEKDAY, [Date])                 AS DayName,
    CASE WHEN DATENAME(WEEKDAY, [Date]) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS IsWeekend
FROM d
OPTION (MAXRECURSION 0);




SELECT COUNT(*) AS DatesCount FROM dbo.DimDate;
SELECT MIN([Date]), MAX([Date]) FROM dbo.DimDate;
