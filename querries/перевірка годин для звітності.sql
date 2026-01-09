DISABLE TRIGGER dbo.trg_WorkReport_Limit10HoursPerDay ON dbo.WorkReport;

ENABLE TRIGGER dbo.trg_WorkReport_Limit10HoursPerDay ON dbo.WorkReport;

SELECT COUNT(*) AS WorkReportCount FROM dbo.WorkReport;

SELECT TOP 10 employee_id, work_date, SUM(hours) AS total_hours
FROM dbo.WorkReport
GROUP BY employee_id, work_date
HAVING SUM(hours) > 10;





-- 0) Вимкнути тригер на час масових правок
DISABLE TRIGGER dbo.trg_WorkReport_Limit10HoursPerDay ON dbo.WorkReport;

BEGIN TRAN;

-- 1) Тимчасові таблиці для змін
IF OBJECT_ID('tempdb..#to_delete') IS NOT NULL DROP TABLE #to_delete;
IF OBJECT_ID('tempdb..#to_update') IS NOT NULL DROP TABLE #to_update;

CREATE TABLE #to_delete (
    report_id BIGINT PRIMARY KEY
);

CREATE TABLE #to_update (
    report_id BIGINT PRIMARY KEY,
    new_hours DECIMAL(5,2) NOT NULL
);

-- 2) Порахувати "накопичення" годин і визначити що видалити/обрізати
;WITH x AS (
    SELECT
        report_id,
        employee_id,
        work_date,
        hours,
        SUM(hours) OVER (
            PARTITION BY employee_id, work_date
            ORDER BY report_id
            ROWS UNBOUNDED PRECEDING
        ) AS running_sum
    FROM dbo.WorkReport
),
calc AS (
    SELECT
        report_id,
        hours,
        (running_sum - hours) AS before_sum,
        running_sum
    FROM x
)
INSERT INTO #to_delete(report_id)
SELECT report_id
FROM calc
WHERE before_sum >= 10;

;WITH x AS (
    SELECT
        report_id,
        employee_id,
        work_date,
        hours,
        SUM(hours) OVER (
            PARTITION BY employee_id, work_date
            ORDER BY report_id
            ROWS UNBOUNDED PRECEDING
        ) AS running_sum
    FROM dbo.WorkReport
),
calc AS (
    SELECT
        report_id,
        hours,
        (running_sum - hours) AS before_sum,
        running_sum
    FROM x
)
INSERT INTO #to_update(report_id, new_hours)
SELECT
    report_id,
    CAST(10 - before_sum AS DECIMAL(5,2)) AS new_hours
FROM calc
WHERE before_sum < 10
  AND running_sum > 10
  AND (10 - before_sum) > 0; -- щоб не записати 0

-- 3) Спочатку видаляємо повністю зайві рядки
DELETE wr
FROM dbo.WorkReport wr
JOIN #to_delete d ON d.report_id = wr.report_id;

-- 4) Потім обрізаємо "перехідні" рядки
UPDATE wr
SET hours = u.new_hours
FROM dbo.WorkReport wr
JOIN #to_update u ON u.report_id = wr.report_id;

COMMIT TRAN;

-- 5) Увімкнути тригер назад
ENABLE TRIGGER dbo.trg_WorkReport_Limit10HoursPerDay ON dbo.WorkReport;





DECLARE @need INT = 500000 - (SELECT COUNT(*) FROM dbo.WorkReport);

IF (@need <= 0)
BEGIN
    SELECT 'OK - already >= 500000' AS status, (SELECT COUNT(*) FROM dbo.WorkReport) AS WorkReportCount;
    RETURN;
END

;WITH daily AS (
    SELECT
        employee_id,
        work_date,
        SUM(hours) AS total_hours
    FROM dbo.WorkReport
    GROUP BY employee_id, work_date
),
candidates AS (
    SELECT TOP (100000)  -- великий пул, щоб вистачило
        d.employee_id,
        d.work_date,
        CAST(10.0 - d.total_hours AS DECIMAL(5,2)) AS remaining
    FROM daily d
    WHERE d.total_hours < 9.5            -- залишимо запас
    ORDER BY NEWID()
),
pick AS (
    SELECT TOP (@need)
        employee_id,
        work_date,
        CAST(
            CASE 
                WHEN remaining >= 1.0 THEN 1.0
                WHEN remaining >= 0.5 THEN 0.5
                ELSE remaining
            END
        AS DECIMAL(5,2)) AS add_hours
    FROM candidates
)
INSERT INTO dbo.WorkReport (work_date, hours, work_description, employee_id, project_id)
SELECT
    p.work_date,
    p.add_hours,
    N'Additional generated work',
    p.employee_id,
    -- випадковий проект
    (SELECT TOP 1 project_id FROM dbo.Project ORDER BY NEWID())
FROM pick p;






-- має бути >= 500000
SELECT COUNT(*) AS WorkReportCount FROM dbo.WorkReport;

-- має бути 0 рядків
SELECT TOP 10 employee_id, work_date, SUM(hours) AS total_hours
FROM dbo.WorkReport
GROUP BY employee_id, work_date
HAVING SUM(hours) > 10;
