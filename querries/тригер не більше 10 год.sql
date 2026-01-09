CREATE OR ALTER TRIGGER dbo.trg_WorkReport_Limit10HoursPerDay
ON dbo.WorkReport
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hasViolation BIT = 0;

    ;WITH touched AS (
        SELECT employee_id, work_date FROM inserted
        UNION
        SELECT employee_id, work_date FROM deleted
    ),
    totals AS (
        SELECT
            wr.employee_id,
            wr.work_date,
            SUM(wr.hours) AS total_hours
        FROM dbo.WorkReport wr
        INNER JOIN touched t
            ON t.employee_id = wr.employee_id
           AND t.work_date   = wr.work_date
        GROUP BY wr.employee_id, wr.work_date
    )
    SELECT @hasViolation =
        CASE WHEN EXISTS (SELECT 1 FROM totals WHERE total_hours > 10.0)
             THEN 1 ELSE 0 END;

    IF (@hasViolation = 1)
    BEGIN
        RAISERROR (N'Ќе можна зв≥тувати б≥льше 10 годин на день дл€ одного виконавц€.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
