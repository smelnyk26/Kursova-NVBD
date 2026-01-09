IF OBJECT_ID('tempdb..#picked') IS NOT NULL DROP TABLE #picked;
IF OBJECT_ID('tempdb..#one_pay') IS NOT NULL DROP TABLE #one_pay;
IF OBJECT_ID('tempdb..#two_pay') IS NOT NULL DROP TABLE #two_pay;

SELECT invoice_id, total_amount
INTO #picked
FROM (
    SELECT TOP (60) PERCENT invoice_id, total_amount
    FROM dbo.Invoice
    WHERE status <> 'PAID'
    ORDER BY NEWID()
) s;

SELECT invoice_id, total_amount
INTO #one_pay
FROM (
    SELECT TOP (70) PERCENT *
    FROM #picked
    ORDER BY NEWID()
) s;

SELECT p.invoice_id, p.total_amount
INTO #two_pay
FROM #picked p
WHERE NOT EXISTS (SELECT 1 FROM #one_pay o WHERE o.invoice_id = p.invoice_id);



-- 1 платіж = вся сума
INSERT INTO dbo.Payment (invoice_id, amount, payment_date)
SELECT
    invoice_id,
    CAST(total_amount AS DECIMAL(14,2)),
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 25, SYSDATETIME())
FROM #one_pay;

-- 2 платежі: 40% і 60%
INSERT INTO dbo.Payment (invoice_id, amount, payment_date)
SELECT
    invoice_id,
    CAST(total_amount * 0.40 AS DECIMAL(14,2)),
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 10, SYSDATETIME())
FROM #two_pay;

INSERT INTO dbo.Payment (invoice_id, amount, payment_date)
SELECT
    invoice_id,
    CAST(total_amount - CAST(total_amount * 0.40 AS DECIMAL(14,2)) AS DECIMAL(14,2)),
    DATEADD(DAY, 10 + ABS(CHECKSUM(NEWID())) % 15, SYSDATETIME())
FROM #two_pay;



UPDATE i
SET status = 'PAID'
FROM dbo.Invoice i
JOIN (
    SELECT invoice_id, SUM(amount) AS paid_sum
    FROM dbo.Payment
    GROUP BY invoice_id
) p ON p.invoice_id = i.invoice_id
WHERE p.paid_sum >= i.total_amount;





SELECT COUNT(*) AS PaymentCount FROM dbo.Payment;

SELECT status, COUNT(*) cnt
FROM dbo.Invoice
GROUP BY status;

