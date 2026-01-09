SELECT
  c.name,
  t.name AS DataType,
  c.max_length,
  c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.DimContractCategory')
ORDER BY c.column_id;



SELECT c.name, t.name AS type_name, c.precision, c.scale
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.DimContractCategory');
