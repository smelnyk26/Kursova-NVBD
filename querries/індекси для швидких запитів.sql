CREATE INDEX IX_WorkReport_EmployeeDate ON dbo.WorkReport(employee_id, work_date);
CREATE INDEX IX_WorkReport_ProjectDate  ON dbo.WorkReport(project_id, work_date);
CREATE INDEX IX_Project_Customer        ON dbo.Project(customer_id);
CREATE INDEX IX_Invoice_StatusMonth     ON dbo.Invoice(status, billing_month);
