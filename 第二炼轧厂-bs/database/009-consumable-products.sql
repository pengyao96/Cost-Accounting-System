USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.hccp', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.hccp (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [hno] INT NOT NULL,
        [bno] INT NULL,
        [cp] NVARCHAR(100) NULL,
        [日核算类型] NVARCHAR(50) NULL,
        [分摊类型] NVARCHAR(100) NULL,
        [列名] NVARCHAR(100) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_hccp_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_hccp_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.hccp)
BEGIN
    INSERT dbo.hccp ([hno], [bno], [cp], [日核算类型], [分摊类型], [列名]) VALUES
    (N'1', N'3', N'轧辊', N'上月', N'辊耗分摊', N''),
    (N'2', N'3', N'卷筒', N'上月', N'辊耗分摊', N''),
    (N'3', N'1', N'内部钢坯', N'实时', N'', N''),
    (N'4', N'1', N'外购钢坯', N'实时', N'', N''),
    (N'5', N'2', N'可深加工废品板', N'实时', N'', N''),
    (N'6', N'2', N'氧化铁皮', N'实时', N'', N''),
    (N'7', N'2', N'污泥', N'实时', N'', N''),
    (N'8', N'2', N'次品板', N'实时', N'', N''),
    (N'9', N'2', N'绝废品', N'实时', N'', N''),
    (N'10', N'2', N'切头尾边', N'实时', N'', N''),
    (N'11', N'5', N'混煤', N'实时', N'加热分摊', N'hunhemeiqi'),
    (N'12', N'5', N'焦煤', N'实时', N'轧制分摊', N'jiaolumeiqi'),
    (N'13', N'5', N'电', N'实时', N'轧制分摊', N'dian'),
    (N'14', N'5', N'工业水', N'实时', N'轧制分摊', N'dibiao'),
    (N'15', N'5', N'深井水', N'实时', N'轧制分摊', N'shenjing'),
    (N'16', N'5', N'中水', N'实时', N'null', N''),
    (N'17', N'5', N'软水', N'实时', N'加热分摊', N'ruanshui'),
    (N'18', N'5', N'压空', N'实时', N'轧制分摊', N'yakong'),
    (N'19', N'5', N'氧气', N'实时', N'轧制分摊', N'yangqi'),
    (N'20', N'5', N'氮气', N'实时', N'轧制分摊', N'danqi'),
    (N'21', N'5', N'蒸汽', N'实时', N'轧制分摊', N'zhengqi'),
    (N'22', N'8', N'工资', N'上月', N'轧制平均分摊', N''),
    (N'23', N'8', N'其他职工薪酬', N'上月', N'轧制平均分摊', N''),
    (N'24', N'8', N'折旧', N'上月', N'轧制及硬力系数分摊', N''),
    (N'25', N'6', N'直接工资', N'上月', N'轧制平均分摊', N''),
    (N'26', N'7', N'直接其他工资薪酬', N'上月', N'轧制平均分摊', N''),
    (N'27', N'8', N'备件费', N'上月', N'平均分摊', N''),
    (N'28', N'8', N'刻花费', N'实时', N'花纹分摊', N'');
END
GO

IF OBJECT_ID(N'dbo.lghccp', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lghccp (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [bno] INT NOT NULL,
        [消耗] NVARCHAR(100) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lghccp_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lghccp_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.lghccp)
BEGIN
    INSERT dbo.lghccp ([bno], [消耗]) VALUES
    (N'1', N'钢铁料'),
    (N'2', N'回收'),
    (N'3', N'合金料'),
    (N'4', N'铁矿石'),
    (N'5', N'熔炼费'),
    (N'6', N'直接工资'),
    (N'7', N'直接其他工资薪酬'),
    (N'8', N'制造费用');
END
GO

IF OBJECT_ID(N'dbo.ljhccp', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ljhccp (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [hno] INT NOT NULL,
        [bno] INT NULL,
        [cp] NVARCHAR(100) NULL,
        [日核算类型] NVARCHAR(50) NULL,
        [分摊类型] NVARCHAR(100) NULL,
        [列名] NVARCHAR(100) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljhccp_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljhccp_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ljhccp)
BEGIN
    INSERT dbo.ljhccp ([hno], [bno], [cp], [日核算类型], [分摊类型], [列名]) VALUES
    (N'1', N'3', N'轧辊', N'上月', N'辊耗分摊', N''),
    (N'2', N'3', N'卷筒', N'上月', N'轧制方式分摊', N''),
    (N'3', N'1', N'内部钢坯', N'100', N'', N''),
    (N'4', N'1', N'外购钢坯', N'100', N'', N''),
    (N'5', N'2', N'可深加工废品板', N'3330', N'回收', N''),
    (N'6', N'2', N'氧化铁皮', N'260', N'回收', N''),
    (N'7', N'2', N'污泥', N'160', N'回收', N''),
    (N'8', N'2', N'次品板', N'2900', N'回收', N''),
    (N'9', N'2', N'绝废品', N'2350', N'回收', N''),
    (N'10', N'2', N'切头尾边', N'2350', N'回收', N''),
    (N'11', N'5', N'混合煤气', N'100', N'加热分摊', N'hunhemeiqi'),
    (N'12', N'5', N'焦炉煤气', N'100', N'轧制方式分摊', N'jiaolumeiqi'),
    (N'13', N'5', N'电', N'100', N'轧制分摊', N'dian'),
    (N'14', N'5', N'地表水', N'100', N'轧制分摊', N'dibiao'),
    (N'15', N'5', N'深井水', N'100', N'轧制分摊', N'shenjing'),
    (N'16', N'5', N'中水', N'100', N'', N''),
    (N'17', N'5', N'软水', N'100', N'加热分摊', N'ruanshui'),
    (N'18', N'5', N'压缩空气', N'100', N'轧制分摊', N'yakong'),
    (N'19', N'5', N'氧气', N'100', N'轧制分摊', N'yangqi'),
    (N'20', N'5', N'氮气', N'100', N'轧制分摊', N'danqi'),
    (N'21', N'5', N'蒸汽', N'100', N'轧制分摊', N'zhengqi'),
    (N'22', N'8', N'工资', N'上月', N'轧制平均分摊', N''),
    (N'23', N'8', N'其他职工薪酬', N'上月', N'轧制平均分摊', N''),
    (N'24', N'8', N'折旧', N'上月', N'轧制及硬力系数分摊', N''),
    (N'25', N'6', N'直接工资', N'上月', N'轧制平均分摊', N''),
    (N'26', N'7', N'直接其他工资薪酬', N'上月', N'轧制平均分摊', N''),
    (N'27', N'4', N'检测费', N'上月', N'平均分摊', N''),
    (N'28', N'8', N'制造费用', N'上月', N'平均分摊', N'');
END
GO
