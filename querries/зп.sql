-- Місячна зарплата виконавців
DECLARE @MonthStart DATE = '2026-01-01';
DECLARE @MonthEnd   DATE = DATEADD(MONTH, 1, @MonthStart);

SELECT
    e.employee_id,
    e.full_name,
    SUM(wr.hours) AS total_hours,
    CAST(
        SUM(wr.hours * q.hourly_rate * pos.bonus_coeff)
        AS DECIMAL(14,2)
    ) AS salary_amount
FROM dbo.WorkReport wr
JOIN dbo.Employee e      ON e.employee_id = wr.employee_id
JOIN dbo.Qualification q ON q.qualification_id = e.qualification_id
JOIN dbo.Position pos    ON pos.position_id = e.position_id
WHERE wr.work_date >= @MonthStart
  AND wr.work_date <  @MonthEnd
GROUP BY e.employee_id, e.full_name
ORDER BY salary_amount DESC;




