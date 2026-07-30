USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.accounting_periods', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.accounting_periods (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        period_name NVARCHAR(50) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        status NVARCHAR(20) NOT NULL CONSTRAINT DF_accounting_periods_status DEFAULT (N'open'),
        closed_by INT NULL,
        closed_at DATETIME2(0) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_accounting_periods_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_accounting_periods_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_accounting_periods_dates UNIQUE (start_date, end_date),
        CONSTRAINT CK_accounting_periods_dates CHECK (end_date >= start_date),
        CONSTRAINT CK_accounting_periods_status CHECK (status IN (N'open', N'closed')),
        CONSTRAINT FK_accounting_periods_closed_by FOREIGN KEY (closed_by) REFERENCES dbo.sys_users(id)
    );
END
GO

IF OBJECT_ID(N'dbo.cost_calculation_batches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.cost_calculation_batches (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        batch_no NVARCHAR(40) NOT NULL,
        period_id INT NOT NULL,
        line_code NVARCHAR(10) NOT NULL,
        dimension_code NVARCHAR(20) NOT NULL,
        status NVARCHAR(20) NOT NULL CONSTRAINT DF_cost_batches_status DEFAULT (N'completed'),
        source_row_count INT NOT NULL CONSTRAINT DF_cost_batches_source_count DEFAULT (0),
        output_row_count INT NOT NULL CONSTRAINT DF_cost_batches_output_count DEFAULT (0),
        total_output_weight DECIMAL(18,4) NOT NULL CONSTRAINT DF_cost_batches_weight DEFAULT (0),
        calculated_by INT NULL,
        calculated_at DATETIME2(0) NOT NULL CONSTRAINT DF_cost_batches_calculated DEFAULT (SYSDATETIME()),
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_cost_batches_created DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_cost_batches_no UNIQUE (batch_no),
        CONSTRAINT CK_cost_batches_line CHECK (line_code IN (N'lj', N'rz', N'lg')),
        CONSTRAINT FK_cost_batches_period FOREIGN KEY (period_id) REFERENCES dbo.accounting_periods(id),
        CONSTRAINT FK_cost_batches_user FOREIGN KEY (calculated_by) REFERENCES dbo.sys_users(id)
    );
END
GO

IF OBJECT_ID(N'dbo.cost_calculation_results', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.cost_calculation_results (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        batch_id INT NOT NULL,
        display_name NVARCHAR(255) NOT NULL,
        grade NVARCHAR(100) NULL,
        product NVARCHAR(100) NULL,
        series NVARCHAR(100) NULL,
        thickness NVARCHAR(50) NULL,
        width NVARCHAR(50) NULL,
        coil_weight DECIMAL(18,4) NOT NULL,
        input_weight DECIMAL(18,4) NOT NULL,
        yield_rate DECIMAL(12,6) NULL,
        material_cost DECIMAL(18,4) NOT NULL,
        process_cost DECIMAL(18,4) NOT NULL,
        manufacturing_cost DECIMAL(18,4) NOT NULL,
        sale_price DECIMAL(18,4) NOT NULL,
        profit_per_ton DECIMAL(18,4) NOT NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_cost_results_created DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_cost_results_batch FOREIGN KEY (batch_id) REFERENCES dbo.cost_calculation_batches(id) ON DELETE CASCADE
    );
    CREATE INDEX IX_cost_results_batch ON dbo.cost_calculation_results(batch_id);
END
GO

IF OBJECT_ID(N'dbo.cost_calculation_details', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.cost_calculation_details (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        result_id INT NOT NULL,
        item_name NVARCHAR(100) NOT NULL,
        amount DECIMAL(18,4) NOT NULL,
        note NVARCHAR(500) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_cost_details_created DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_cost_details_result FOREIGN KEY (result_id) REFERENCES dbo.cost_calculation_results(id) ON DELETE CASCADE
    );
    CREATE INDEX IX_cost_details_result ON dbo.cost_calculation_details(result_id);
END
GO

IF OBJECT_ID(N'dbo.sys_permissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sys_permissions (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        group_id INT NOT NULL,
        module_code NVARCHAR(50) NOT NULL,
        can_read BIT NOT NULL CONSTRAINT DF_permissions_read DEFAULT (0),
        can_write BIT NOT NULL CONSTRAINT DF_permissions_write DEFAULT (0),
        can_calculate BIT NOT NULL CONSTRAINT DF_permissions_calculate DEFAULT (0),
        can_approve BIT NOT NULL CONSTRAINT DF_permissions_approve DEFAULT (0),
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_permissions_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_permissions_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_permissions_group_module UNIQUE (group_id, module_code),
        CONSTRAINT FK_permissions_group FOREIGN KEY (group_id) REFERENCES dbo.sys_user_groups(id)
    );
END
GO

IF OBJECT_ID(N'dbo.sys_audit_logs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sys_audit_logs (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        occurred_at DATETIME2(0) NOT NULL CONSTRAINT DF_audit_occurred DEFAULT (SYSDATETIME()),
        user_id INT NULL,
        action NVARCHAR(50) NOT NULL,
        entity_type NVARCHAR(100) NOT NULL,
        entity_id NVARCHAR(100) NULL,
        before_data NVARCHAR(MAX) NULL,
        after_data NVARCHAR(MAX) NULL,
        detail NVARCHAR(1000) NULL,
        CONSTRAINT FK_audit_user FOREIGN KEY (user_id) REFERENCES dbo.sys_users(id)
    );
    CREATE INDEX IX_audit_occurred ON dbo.sys_audit_logs(occurred_at DESC);
    CREATE INDEX IX_audit_entity ON dbo.sys_audit_logs(entity_type, entity_id);
END
GO

MERGE dbo.sys_permissions AS target
USING (
    SELECT g.id AS group_id, module_code, can_read, can_write, can_calculate, can_approve
    FROM dbo.sys_user_groups g
    CROSS JOIN (VALUES
        (N'cost', CAST(1 AS BIT), CAST(0 AS BIT), CAST(0 AS BIT), CAST(0 AS BIT)),
        (N'datasets', CAST(1 AS BIT), CAST(0 AS BIT), CAST(0 AS BIT), CAST(0 AS BIT))
    ) AS p(module_code, can_read, can_write, can_calculate, can_approve)
    WHERE g.group_name <> N'系统管理员'
    UNION ALL
    SELECT g.id, N'cost', CAST(1 AS BIT), CAST(1 AS BIT), CAST(1 AS BIT), CAST(1 AS BIT)
    FROM dbo.sys_user_groups g WHERE g.group_name = N'系统管理员'
    UNION ALL
    SELECT g.id, N'datasets', CAST(1 AS BIT), CAST(1 AS BIT), CAST(1 AS BIT), CAST(1 AS BIT)
    FROM dbo.sys_user_groups g WHERE g.group_name = N'系统管理员'
) AS source
ON target.group_id = source.group_id AND target.module_code = source.module_code
WHEN NOT MATCHED THEN
    INSERT(group_id, module_code, can_read, can_write, can_calculate, can_approve)
    VALUES(source.group_id, source.module_code, source.can_read, source.can_write, source.can_calculate, source.can_approve);
GO
