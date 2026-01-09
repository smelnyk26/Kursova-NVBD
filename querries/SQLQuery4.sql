SELECT * FROM dbo.DimPosition WHERE PositionBK = 0;
SELECT * FROM dbo.DimQualification WHERE QualificationBK = 0;




-- DimPosition
IF NOT EXISTS (SELECT 1 FROM dbo.DimPosition WHERE PositionBK = 0)
INSERT INTO dbo.DimPosition(PositionBK, Name, BonusCoeff)
VALUES (0, N'Unknown', 1.000);

-- DimQualification
IF NOT EXISTS (SELECT 1 FROM dbo.DimQualification WHERE QualificationBK = 0)
INSERT INTO dbo.DimQualification(QualificationBK, Name, HourlyRate)
VALUES (0, N'Unknown', 0);
