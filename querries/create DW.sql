/* =========================================================
   0) CREATE DW DATABASE
   ========================================================= */
IF DB_ID(N'ProjectManagment_DW') IS NULL
BEGIN
    CREATE DATABASE ProjectManagment_DW;
END
GO

USE ProjectManagment_DW;
GO

/* =========================================================
   1) DIMENSIONS
   ========================================================= */

-- 1.1 DimDate
IF OBJECT_ID(N'dbo.DimDate', N'U') IS NOT NULL DROP TABLE dbo.DimDate;
GO
CREATE TABLE dbo.DimDate (
    DateKey     INT        NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY,  -- yyyymmdd
    [Date]      DATE       NOT NULL,
    [Year]      SMALLINT   NOT NULL,
    [Quarter]   TINYINT    NOT NULL,
    [Month]     TINYINT    NOT NULL,
    MonthName   NVARCHAR(20) NOT NULL,
    DayOfMonth  TINYINT    NOT NULL,
    DayName     NVARCHAR(20) NOT NULL,
    IsWeekend   BIT        NOT NULL
);
GO

-- 1.2 DimCustomer (SCD Type 2)
IF OBJECT_ID(N'dbo.DimCustomer', N'U') IS NOT NULL DROP TABLE dbo.DimCustomer;
GO
CREATE TABLE dbo.DimCustomer (
    CustomerSK     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCustomer PRIMARY KEY,
    CustomerBK     INT NOT NULL,                 -- OLTP: Customer.customer_id
    [Name]         NVARCHAR(200) NOT NULL,
    ContactInfo    NVARCHAR(400) NULL,

    EffectiveFrom  DATETIME2(0) NOT NULL,
    EffectiveTo    DATETIME2(0) NULL,
    IsCurrent      BIT NOT NULL,

    CONSTRAINT CK_DimCustomer_Effective
        CHECK (EffectiveTo IS NULL OR EffectiveTo > EffectiveFrom)
);
GO
-- один "current" на CustomerBK
CREATE UNIQUE INDEX UX_DimCustomer_Current
ON dbo.DimCustomer(CustomerBK)
WHERE IsCurrent = 1;
GO
CREATE INDEX IX_DimCustomer_BK ON dbo.DimCustomer(CustomerBK);
GO

-- 1.3 DimPosition (Type 1)
IF OBJECT_ID(N'dbo.DimPosition', N'U') IS NOT NULL DROP TABLE dbo.DimPosition;
GO
CREATE TABLE dbo.DimPosition (
    PositionSK   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimPosition PRIMARY KEY,
    PositionBK   INT NOT NULL,            -- OLTP: Position.position_id
    [Name]       NVARCHAR(100) NOT NULL,
    BonusCoeff   DECIMAL(6,3) NOT NULL,
    CONSTRAINT UQ_DimPosition_BK UNIQUE (PositionBK)
);
GO

-- 1.4 DimQualification (Type 1)
IF OBJECT_ID(N'dbo.DimQualification', N'U') IS NOT NULL DROP TABLE dbo.DimQualification;
GO
CREATE TABLE dbo.DimQualification (
    QualificationSK INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimQualification PRIMARY KEY,
    QualificationBK INT NOT NULL,         -- OLTP: Qualification.qualification_id
    [Name]          NVARCHAR(100) NOT NULL,
    HourlyRate      DECIMAL(12,2) NOT NULL,
    CONSTRAINT UQ_DimQualification_BK UNIQUE (QualificationBK)
);
GO

-- 1.5 DimContractCategory (Type 1)
IF OBJECT_ID(N'dbo.DimContractCategory', N'U') IS NOT NULL DROP TABLE dbo.DimContractCategory;
GO
CREATE TABLE dbo.DimContractCategory (
    CategorySK     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimContractCategory PRIMARY KEY,
    CategoryBK     INT NOT NULL,          -- OLTP: ContractCategory.category_id
    [Name]         NVARCHAR(100) NOT NULL,
    PaymentCoeff   DECIMAL(6,3) NOT NULL,
    CONSTRAINT UQ_DimContractCategory_BK UNIQUE (CategoryBK)
);
GO

-- 1.6 DimEmployee (SCD Type 2)
IF OBJECT_ID(N'dbo.DimEmployee', N'U') IS NOT NULL DROP TABLE dbo.DimEmployee;
GO
CREATE TABLE dbo.DimEmployee (
    EmployeeSK       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimEmployee PRIMARY KEY,
    EmployeeBK       INT NOT NULL,        -- OLTP: Employee.employee_id
    FullName         NVARCHAR(200) NOT NULL,

    PositionBK       INT NOT NULL,        -- дл€ lookup на DimPosition
    QualificationBK  INT NOT NULL,        -- дл€ lookup на DimQualification
    IsActive         BIT NOT NULL,

    EffectiveFrom    DATETIME2(0) NOT NULL,
    EffectiveTo      DATETIME2(0) NULL,
    IsCurrent        BIT NOT NULL,

    CONSTRAINT CK_DimEmployee_Effective
        CHECK (EffectiveTo IS NULL OR EffectiveTo > EffectiveFrom)
);
GO
CREATE UNIQUE INDEX UX_DimEmployee_Current
ON dbo.DimEmployee(EmployeeBK)
WHERE IsCurrent = 1;
GO
CREATE INDEX IX_DimEmployee_BK ON dbo.DimEmployee(EmployeeBK);
GO

-- 1.7 DimProject (Type 1)  -- тримаЇмо BK-и дл€ лукап≥в/зв'€зк≥в
IF OBJECT_ID(N'dbo.DimProject', N'U') IS NOT NULL DROP TABLE dbo.DimProject;
GO
CREATE TABLE dbo.DimProject (
    ProjectSK        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimProject PRIMARY KEY,
    ProjectBK        INT NOT NULL,     -- OLTP: Project.project_id
    [Name]           NVARCHAR(200) NOT NULL,
    StartDate        DATE NOT NULL,
    PlannedDuration  INT NOT NULL,
    [Status]         NVARCHAR(20) NOT NULL,

    CustomerBK       INT NOT NULL,
    ManagerBK        INT NOT NULL,
    CategoryBK       INT NOT NULL,

    CONSTRAINT UQ_DimProject_BK UNIQUE (ProjectBK)
);
GO
CREATE INDEX IX_DimProject_CustomerBK ON dbo.DimProject(CustomerBK);
GO

/* =========================================================
   2) FACT TABLES
   ========================================================= */

-- 2.1 FactWork: зерно (Date, Employee, Project)
IF OBJECT_ID(N'dbo.FactWork', N'U') IS NOT NULL DROP TABLE dbo.FactWork;
GO
CREATE TABLE dbo.FactWork (
    DateKey     INT NOT NULL,
    EmployeeSK  INT NOT NULL,
    ProjectSK   INT NOT NULL,

    Hours       DECIMAL(5,2)  NOT NULL,
    WorkCost    DECIMAL(14,2) NOT NULL,
    RowsCount   INT NOT NULL CONSTRAINT DF_FactWork_RowsCount DEFAULT(1),

    CONSTRAINT PK_FactWork PRIMARY KEY (DateKey, EmployeeSK, ProjectSK),

    CONSTRAINT FK_FactWork_Date
        FOREIGN KEY (DateKey) REFERENCES dbo.DimDate(DateKey),

    CONSTRAINT FK_FactWork_Employee
        FOREIGN KEY (EmployeeSK) REFERENCES dbo.DimEmployee(EmployeeSK),

    CONSTRAINT FK_FactWork_Project
        FOREIGN KEY (ProjectSK) REFERENCES dbo.DimProject(ProjectSK)
);
GO
CREATE INDEX IX_FactWork_Project ON dbo.FactWork(ProjectSK, DateKey);
GO

-- 2.2 FactBilling: зерно (BillingMonthKey, Project, Invoice)
IF OBJECT_ID(N'dbo.FactBilling', N'U') IS NOT NULL DROP TABLE dbo.FactBilling;
GO
CREATE TABLE dbo.FactBilling (
    BillingMonthKey INT NOT NULL,       -- yyyymm01 (перший день м≥с€ц€)
    ProjectSK       INT NOT NULL,
    InvoiceBK       BIGINT NOT NULL,    -- OLTP: Invoice.invoice_id

    SubtotalAmount  DECIMAL(14,2) NOT NULL,
    OverheadAmount  DECIMAL(14,2) NOT NULL,
    TotalAmount     DECIMAL(14,2) NOT NULL,

    PaidAmount      DECIMAL(14,2) NOT NULL,
    PaymentsCount   INT NOT NULL,
    IsPaid          BIT NOT NULL,

    CONSTRAINT PK_FactBilling PRIMARY KEY (BillingMonthKey, ProjectSK, InvoiceBK),

    CONSTRAINT FK_FactBilling_Date
        FOREIGN KEY (BillingMonthKey) REFERENCES dbo.DimDate(DateKey),

    CONSTRAINT FK_FactBilling_Project
        FOREIGN KEY (ProjectSK) REFERENCES dbo.DimProject(ProjectSK),

    CONSTRAINT UQ_FactBilling_Invoice UNIQUE (InvoiceBK)
);
GO
CREATE INDEX IX_FactBilling_ProjectMonth ON dbo.FactBilling(ProjectSK, BillingMonthKey);
GO

/* =========================================================
   3) ETL AUDIT TABLES (дл€ 3.5)
   ========================================================= */

IF OBJECT_ID(N'dbo.ETL_Run', N'U') IS NOT NULL DROP TABLE dbo.ETL_Run;
GO
CREATE TABLE dbo.ETL_Run (
    RunID        BIGINT IDENTITY(1,1) CONSTRAINT PK_ETL_Run PRIMARY KEY,
    PackageName  NVARCHAR(200) NOT NULL,
    StartTime    DATETIME2(0) NOT NULL CONSTRAINT DF_ETL_Run_Start DEFAULT SYSDATETIME(),
    EndTime      DATETIME2(0) NULL,
    Status       NVARCHAR(20) NOT NULL CONSTRAINT DF_ETL_Run_Status DEFAULT 'STARTED'
);
GO

IF OBJECT_ID(N'dbo.ETL_Log', N'U') IS NOT NULL DROP TABLE dbo.ETL_Log;
GO
CREATE TABLE dbo.ETL_Log (
    LogID     BIGINT IDENTITY(1,1) CONSTRAINT PK_ETL_Log PRIMARY KEY,
    RunID     BIGINT NOT NULL,
    LogTime   DATETIME2(0) NOT NULL CONSTRAINT DF_ETL_Log_Time DEFAULT SYSDATETIME(),
    [Level]   NVARCHAR(10) NOT NULL, -- INFO/ERROR
    [Message] NVARCHAR(2000) NOT NULL,
    CONSTRAINT FK_ETL_Log_Run FOREIGN KEY (RunID) REFERENCES dbo.ETL_Run(RunID)
);
GO



SELECT name FROM sys.tables;
