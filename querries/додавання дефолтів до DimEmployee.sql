SELECT 
    c.name AS ColumnName,
    dc.name AS DefaultConstraintName,
    dc.definition AS DefaultDefinition
FROM sys.columns c
LEFT JOIN sys.default_constraints dc 
    ON dc.parent_object_id = c.object_id
   AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('dbo.DimEmployee')
  AND c.name IN ('IsActive','IsCurrent','EffectiveFrom','EffectiveTo')
ORDER BY c.name;




ALTER TABLE dbo.DimEmployee 
ADD CONSTRAINT DF_DimEmployee_IsActive DEFAULT (1) FOR IsActive;

ALTER TABLE dbo.DimEmployee 
ADD CONSTRAINT DF_DimEmployee_IsCurrent DEFAULT (1) FOR IsCurrent;

ALTER TABLE dbo.DimEmployee 
ADD CONSTRAINT DF_DimEmployee_EffectiveFrom DEFAULT (GETDATE()) FOR EffectiveFrom;

ALTER TABLE dbo.DimEmployee 
ADD CONSTRAINT DF_DimEmployee_EffectiveTo DEFAULT (NULL) FOR EffectiveTo;





INSERT INTO dbo.DimEmployee (EmployeeBK, FullName, PositionBK, QualificationBK)
VALUES (999999, N'Test User', 1, 1);

SELECT TOP 1 *
FROM dbo.DimEmployee
WHERE EmployeeBK = 999999
ORDER BY EmployeeSK DESC;



DELETE FROM dbo.DimEmployee WHERE EmployeeBK = 999999;





SELECT 
  COUNT(*) AS cnt,
  SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS active_cnt,
  SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) AS current_cnt,
  MIN(EffectiveFrom) AS min_from,
  MAX(EffectiveFrom) AS max_from
FROM dbo.DimEmployee;



SELECT TOP (20) *
FROM dbo.DimEmployee
ORDER BY EmployeeSK DESC;





