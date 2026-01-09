SELECT c.name, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.DimProject')
ORDER BY c.column_id;



SELECT ProjectBK, COUNT(*) c
FROM dbo.DimProject
GROUP BY ProjectBK
HAVING COUNT(*) > 1;


SELECT COUNT(*) FROM dbo.DimProject;



SELECT TOP 10 p.ManagerBK
FROM dbo.DimProject p
LEFT JOIN dbo.DimEmployee e ON e.EmployeeBK = p.ManagerBK
WHERE e.EmployeeBK IS NULL;
--якщо повертаЇ р€дки Ч значить Ї ManagerBK €ких нема в DimEmployee (тод≥ вони мали б п≥ти в No Match / Error лог≥ку залежно в≥д твоЇњ схеми).
