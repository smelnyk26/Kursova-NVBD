SELECT c.name, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.DimCustomer')
ORDER BY c.column_id;



SELECT COUNT(*) FROM dbo.DimCustomer;



SELECT CustomerBK, COUNT(*) c
FROM dbo.DimCustomer
GROUP BY CustomerBK
HAVING COUNT(*) > 1;




SELECT
    CustomerBK,
    Name,
    IsCurrent,
    EffectiveFrom,
    EffectiveTo
FROM dbo.DimCustomer;

SELECT c.name, c.is_nullable, t.name AS type_name
FROM sys.columns c
JOIN sys.types t ON c.user_type_id=t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.DimCustomer')
ORDER BY c.column_id;




SELECT
  c.name,
  t.name AS type_name,
  c.max_length,
  c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.DimCustomer')
ORDER BY c.column_id;
