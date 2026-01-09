DECLARE @d DATE = '2020-01-01';

WHILE @d <= '2025-12-01'
BEGIN
    EXEC dbo.sp_GenerateInvoices @BillingMonth = @d;
    SET @d = DATEADD(MONTH, 1, @d);
END


SELECT COUNT(*) AS InvoiceCount FROM dbo.Invoice;
