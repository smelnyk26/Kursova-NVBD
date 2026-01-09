CREATE OR ALTER PROCEDURE dbo.sp_GenerateInvoices
    @BillingMonth DATE  -- передавай 'YYYY-MM-01'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@BillingMonth), MONTH(@BillingMonth), 1);
    DECLARE @MonthEnd   DATE = DATEADD(MONTH, 1, @MonthStart);

    ;WITH calc AS (
        SELECT
            p.project_id,
            @MonthStart AS billing_month,
            SUM(wr.hours * q.hourly_rate * pos.bonus_coeff * cc.payment_coefficient) AS subtotal
        FROM dbo.WorkReport wr
        JOIN dbo.Project p ON p.project_id = wr.project_id
        JOIN dbo.Employee e ON e.employee_id = wr.employee_id
        JOIN dbo.Qualification q ON q.qualification_id = e.qualification_id
        JOIN dbo.Position pos ON pos.position_id = e.position_id
        JOIN dbo.ContractCategory cc ON cc.category_id = p.category_id
        WHERE wr.work_date >= @MonthStart
          AND wr.work_date <  @MonthEnd
        GROUP BY p.project_id
    )
    INSERT INTO dbo.Invoice (project_id, billing_month, subtotal_amount, overhead_amount, status)
    SELECT
        c.project_id,
        c.billing_month,
        CAST(c.subtotal AS DECIMAL(14,2)),
        CAST(c.subtotal * 0.40 AS DECIMAL(14,2)),
        'SENT'
    FROM calc c
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Invoice inv
        WHERE inv.project_id = c.project_id
          AND inv.billing_month = c.billing_month
    );
END;
GO
