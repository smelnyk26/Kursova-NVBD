-- ====== D I C T I O N A R I E S ======

CREATE TABLE dbo.Customer (
    customer_id   INT IDENTITY(1,1) CONSTRAINT PK_Customer PRIMARY KEY,
    name          NVARCHAR(200) NOT NULL,
    contact_info  NVARCHAR(400) NULL
);

CREATE TABLE dbo.Position (
    position_id   INT IDENTITY(1,1) CONSTRAINT PK_Position PRIMARY KEY,
    name          NVARCHAR(100) NOT NULL,
    bonus_coeff   DECIMAL(6,3)  NOT NULL,
    CONSTRAINT UQ_Position_name UNIQUE (name),
    CONSTRAINT CK_Position_bonus CHECK (bonus_coeff > 0)
);

CREATE TABLE dbo.Qualification (
    qualification_id INT IDENTITY(1,1) CONSTRAINT PK_Qualification PRIMARY KEY,
    name             NVARCHAR(100) NOT NULL,
    hourly_rate      DECIMAL(12,2) NOT NULL,
    CONSTRAINT UQ_Qualification_name UNIQUE (name),
    CONSTRAINT CK_Qualification_rate CHECK (hourly_rate >= 0)
);

CREATE TABLE dbo.ContractCategory (
    category_id          INT IDENTITY(1,1) CONSTRAINT PK_ContractCategory PRIMARY KEY,
    name                 NVARCHAR(100) NOT NULL,
    payment_coefficient  DECIMAL(6,3)  NOT NULL,
    CONSTRAINT UQ_ContractCategory_name UNIQUE (name),
    CONSTRAINT CK_ContractCategory_coeff CHECK (payment_coefficient > 0)
);

-- ====== C O R E ======

CREATE TABLE dbo.Employee (
    employee_id      INT IDENTITY(1,1) CONSTRAINT PK_Employee PRIMARY KEY,
    full_name        NVARCHAR(200) NOT NULL,
    position_id      INT NOT NULL,
    qualification_id INT NOT NULL,
    is_active        BIT NOT NULL CONSTRAINT DF_Employee_is_active DEFAULT(1),

    CONSTRAINT FK_Employee_Position
        FOREIGN KEY (position_id) REFERENCES dbo.Position(position_id),

    CONSTRAINT FK_Employee_Qualification
        FOREIGN KEY (qualification_id) REFERENCES dbo.Qualification(qualification_id)
);

CREATE TABLE dbo.Project (
    project_id        INT IDENTITY(1,1) CONSTRAINT PK_Project PRIMARY KEY,
    name              NVARCHAR(200) NOT NULL,
    customer_id       INT NOT NULL,
    manager_id        INT NOT NULL,
    category_id       INT NOT NULL,
    start_date        DATE NOT NULL,
    planned_duration  INT NOT NULL, -- дн≥в (або годин, але тод≥ перейменувати)
    status            NVARCHAR(20) NOT NULL CONSTRAINT DF_Project_status DEFAULT('ACTIVE'),

    CONSTRAINT FK_Project_Customer
        FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),

    CONSTRAINT FK_Project_Manager
        FOREIGN KEY (manager_id) REFERENCES dbo.Employee(employee_id),

    CONSTRAINT FK_Project_Category
        FOREIGN KEY (category_id) REFERENCES dbo.ContractCategory(category_id),

    CONSTRAINT CK_Project_duration CHECK (planned_duration > 0)
);

-- ’то входить в команду проекту (M:N)
CREATE TABLE dbo.ProjectEmployee (
    project_id   INT NOT NULL,
    employee_id  INT NOT NULL,
    role_on_project NVARCHAR(100) NULL,

    CONSTRAINT PK_ProjectEmployee PRIMARY KEY (project_id, employee_id),

    CONSTRAINT FK_ProjectEmployee_Project
        FOREIGN KEY (project_id) REFERENCES dbo.Project(project_id),

    CONSTRAINT FK_ProjectEmployee_Employee
        FOREIGN KEY (employee_id) REFERENCES dbo.Employee(employee_id)
);

-- ўоденний зв≥т (табель)
CREATE TABLE dbo.WorkReport (
    report_id         BIGINT IDENTITY(1,1) CONSTRAINT PK_WorkReport PRIMARY KEY,
    work_date         DATE NOT NULL,
    hours             DECIMAL(5,2) NOT NULL,
    work_description  NVARCHAR(1000) NOT NULL,
    employee_id       INT NOT NULL,
    project_id        INT NOT NULL,

    CONSTRAINT FK_WorkReport_Employee
        FOREIGN KEY (employee_id) REFERENCES dbo.Employee(employee_id),

    CONSTRAINT FK_WorkReport_Project
        FOREIGN KEY (project_id) REFERENCES dbo.Project(project_id),

    CONSTRAINT CK_WorkReport_hours CHECK (hours > 0 AND hours <= 10)
);

-- –ахунок (щом≥с€чний)
CREATE TABLE dbo.Invoice (
    invoice_id      BIGINT IDENTITY(1,1) CONSTRAINT PK_Invoice PRIMARY KEY,
    project_id      INT NOT NULL,
    billing_month   DATE NOT NULL, -- збер≥гай €к перший день м≥с€ц€
    created_at      DATETIME2 NOT NULL CONSTRAINT DF_Invoice_created_at DEFAULT(SYSDATETIME()),

    subtotal_amount DECIMAL(14,2) NOT NULL,  -- сума по зв≥тах
    overhead_amount DECIMAL(14,2) NOT NULL,  -- 40% накладн≥
    total_amount    AS (subtotal_amount + overhead_amount) PERSISTED,

    status          NVARCHAR(20) NOT NULL CONSTRAINT DF_Invoice_status DEFAULT('SENT'),

    CONSTRAINT FK_Invoice_Project
        FOREIGN KEY (project_id) REFERENCES dbo.Project(project_id),

    CONSTRAINT UQ_Invoice_ProjectMonth UNIQUE (project_id, billing_month),
    CONSTRAINT CK_Invoice_amounts CHECK (subtotal_amount >= 0 AND overhead_amount >= 0)
);

-- ќплати
CREATE TABLE dbo.Payment (
    payment_id    BIGINT IDENTITY(1,1) CONSTRAINT PK_Payment PRIMARY KEY,
    invoice_id    BIGINT NOT NULL,
    payment_date  DATETIME2 NOT NULL CONSTRAINT DF_Payment_date DEFAULT(SYSDATETIME()),
    amount        DECIMAL(14,2) NOT NULL,

    CONSTRAINT FK_Payment_Invoice
        FOREIGN KEY (invoice_id) REFERENCES dbo.Invoice(invoice_id),

    CONSTRAINT CK_Payment_amount CHECK (amount > 0)
);
