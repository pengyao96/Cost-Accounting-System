USE [master];
GO

IF DB_ID(N'SecondRollingCost') IS NULL
BEGIN
    DECLARE @dataFile NVARCHAR(4000) = N'D:\Code\Cost-Accounting-System\第二炼轧厂-bs\database\data\SecondRollingCost.mdf';
    DECLARE @logFile NVARCHAR(4000) = N'D:\Code\Cost-Accounting-System\第二炼轧厂-bs\database\data\SecondRollingCost_log.ldf';
    DECLARE @createSql NVARCHAR(MAX) =
        N'CREATE DATABASE [SecondRollingCost] ON PRIMARY '
        + N'(NAME = N''SecondRollingCost'', FILENAME = N''' + REPLACE(@dataFile, '''', '''''') + N''', SIZE = 64MB, FILEGROWTH = 32MB) '
        + N'LOG ON (NAME = N''SecondRollingCost_log'', FILENAME = N''' + REPLACE(@logFile, '''', '''''') + N''', SIZE = 32MB, FILEGROWTH = 16MB);';
    EXEC (@createSql);
END
GO

USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.sys_user_groups', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sys_user_groups (
        id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        group_name  NVARCHAR(50) NOT NULL,
        is_enabled  BIT NOT NULL CONSTRAINT DF_sys_user_groups_enabled DEFAULT (1),
        created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_sys_user_groups_created DEFAULT (SYSDATETIME()),
        updated_at  DATETIME2(0) NOT NULL CONSTRAINT DF_sys_user_groups_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_sys_user_groups_name UNIQUE (group_name)
    );
END
GO

IF OBJECT_ID(N'dbo.sys_users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sys_users (
        id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        account             NVARCHAR(50) NOT NULL,
        display_name        NVARCHAR(50) NULL,
        phone               NVARCHAR(30) NULL,
        password_hash       VARBINARY(64) NOT NULL,
        password_salt       VARBINARY(32) NOT NULL,
        password_iterations INT NOT NULL CONSTRAINT DF_sys_users_iterations DEFAULT (100000),
        group_id            INT NOT NULL,
        is_enabled          BIT NOT NULL CONSTRAINT DF_sys_users_enabled DEFAULT (1),
        created_at          DATETIME2(0) NOT NULL CONSTRAINT DF_sys_users_created DEFAULT (SYSDATETIME()),
        updated_at          DATETIME2(0) NOT NULL CONSTRAINT DF_sys_users_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_sys_users_account UNIQUE (account),
        CONSTRAINT FK_sys_users_group FOREIGN KEY (group_id) REFERENCES dbo.sys_user_groups(id)
    );
END
GO

MERGE dbo.sys_user_groups AS target
USING (VALUES (N'系统管理员'), (N'财务科'), (N'安全科'), (N'技术科')) AS source(group_name)
ON target.group_name = source.group_name
WHEN NOT MATCHED THEN
    INSERT (group_name) VALUES (source.group_name);
GO
