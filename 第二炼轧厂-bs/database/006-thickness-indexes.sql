USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.lgthickForm', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lgthickForm (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [厚度索引] NVARCHAR(20) NOT NULL,
        [厚度起] DECIMAL(10,3) NULL,
        [厚度尾] DECIMAL(10,3) NULL,
        [厚度范围] NVARCHAR(50) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgthickForm_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgthickForm_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_lgthickForm_index UNIQUE ([厚度索引])
    );
END
GO

IF OBJECT_ID(N'dbo.ljthickForm', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ljthickForm (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [厚度索引] NVARCHAR(20) NOT NULL,
        [厚度起] DECIMAL(10,3) NULL,
        [厚度尾] DECIMAL(10,3) NULL,
        [厚度范围] NVARCHAR(50) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljthickForm_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljthickForm_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_ljthickForm_index UNIQUE ([厚度索引])
    );
END
GO

IF OBJECT_ID(N'dbo.thickForm', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.thickForm (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [厚度索引] NVARCHAR(20) NOT NULL,
        [厚度起] DECIMAL(10,3) NULL,
        [厚度尾] DECIMAL(10,3) NULL,
        [厚度范围] NVARCHAR(50) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_thickForm_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_thickForm_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_thickForm_index UNIQUE ([厚度索引])
    );
END
GO

MERGE dbo.ljthickForm AS target
USING (VALUES
    (N'1', 4.74, 6.01, N'(4.74,6.01]'), (N'2', 6.01, 10, N'(6.01,10]'),
    (N'3', 10, 14, N'(9.99,14]'), (N'4', 12, 14, N'(12,14]'),
    (N'5', 14, 20, N'(14,20]'), (N'6', 20, 30, N'(20,30]'),
    (N'7', 30, 50, N'(30,50]'), (N'8', 50, 120, N'(50,120]')
) AS source([厚度索引], [厚度起], [厚度尾], [厚度范围])
ON target.[厚度索引] = source.[厚度索引]
WHEN NOT MATCHED THEN INSERT ([厚度索引], [厚度起], [厚度尾], [厚度范围]) VALUES (source.[厚度索引], source.[厚度起], source.[厚度尾], source.[厚度范围]);
GO

MERGE dbo.thickForm AS target
USING (VALUES
    (N'1', 1.2, 1.6, N'(1.2,1.6]'), (N'2', 1.61, 1.8, N'(1.61,1.8]'), (N'3', 1.81, 2, N'(1.81,2]'),
    (N'4', 2.01, 2.3, N'(2.01,2.3]'), (N'5', 2.31, 2.5, N'(2.31,2.5]'), (N'6', 2.51, 2.75, N'(2.51,2.75]'),
    (N'7', 2.751, 3, N'(2.751,3]'), (N'8', 3.01, 3.5, N'(3.01,3.5]'), (N'9', 3.51, 4.5, N'(3.51,4.5]'),
    (N'10', 4.51, 6, N'(4.51,6]'), (N'11', 6.01, 9, N'(6.01,9]'), (N'12', 9.01, 12, N'(9.01,12]'),
    (N'13', 12.01, 16, N'(12.01,16]'), (N'14', 16.01, 20, N'(16.01,20]'), (N'15', 20.01, 30, N'(20.01,30]')
) AS source([厚度索引], [厚度起], [厚度尾], [厚度范围])
ON target.[厚度索引] = source.[厚度索引]
WHEN NOT MATCHED THEN INSERT ([厚度索引], [厚度起], [厚度尾], [厚度范围]) VALUES (source.[厚度索引], source.[厚度起], source.[厚度尾], source.[厚度范围]);
GO
