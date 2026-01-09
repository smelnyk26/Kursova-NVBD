CREATE OR ALTER TRIGGER dbo.trg_Project_BlockDebtors
ON dbo.Project
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- межа: перший день м≥с€ц€, що був 3 м≥с€ц≥ тому
    DECLARE @limitMonth DATE = DATEFROMPARTS(
        YEAR(DATEADD(MONTH, -3, GETDATE())),
        MONTH(DATEADD(MONTH, -3, GETDATE())),
        1
    );

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Project pOld
          ON pOld.customer_id = i.customer_id
        JOIN dbo.Invoice inv
          ON inv.project_id = pOld.project_id
        WHERE inv.status <> 'PAID'
          AND inv.billing_month <= @limitMonth
    )
    BEGIN
        RAISERROR (N'«амовник маЇ неоплачен≥ рахунки б≥льше 3 м≥с€ц≥в. Ќовий проект створити не можна.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
