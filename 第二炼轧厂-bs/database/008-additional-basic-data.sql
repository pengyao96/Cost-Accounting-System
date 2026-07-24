USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.lgwidth', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lgwidth (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [宽度索引] NVARCHAR(20) NOT NULL,
        [起始] DECIMAL(12,3) NULL,
        [结束] DECIMAL(12,3) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgwidth_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgwidth_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF OBJECT_ID(N'dbo.ljwidth', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ljwidth (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [宽度索引] NVARCHAR(20) NOT NULL,
        [起始] DECIMAL(12,3) NULL,
        [结束] DECIMAL(12,3) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljwidth_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljwidth_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ljwidth)
BEGIN
    INSERT dbo.ljwidth ([宽度索引], [起始], [结束]) VALUES
    (N'1', N'800', N'2000'),
    (N'2', N'2000', N'2400'),
    (N'3', N'2400', N'2750'),
    (N'4', N'2750', N'3000'),
    (N'5', N'3000', N'3400');
END
GO

IF OBJECT_ID(N'dbo.width', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.width (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [宽度索引] NVARCHAR(20) NOT NULL,
        [起始] DECIMAL(12,3) NULL,
        [结束] DECIMAL(12,3) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_width_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_width_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.width)
BEGIN
    INSERT dbo.width ([宽度索引], [起始], [结束]) VALUES
    (N'1', N'800', N'1000'),
    (N'2', N'1000', N'1250'),
    (N'3', N'1250', N'1400'),
    (N'4', N'1400', N'1650');
END
GO

IF OBJECT_ID(N'dbo.lgslablen', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lgslablen (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [序号] INT NOT NULL,
        [长度起始] DECIMAL(12,3) NULL,
        [长度终止] DECIMAL(12,3) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgslablen_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgslablen_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.lgslablen)
BEGIN
    INSERT dbo.lgslablen ([序号], [长度起始], [长度终止]) VALUES
    (N'1', N'4800', N'5100'),
    (N'2', N'5200', N'5700'),
    (N'3', N'5750', N'6200'),
    (N'4', N'6300', N'6600'),
    (N'5', N'6600', N'7200'),
    (N'6', N'7200', N'8800'),
    (N'7', N'8800', N'9500'),
    (N'8', N'9500', N'10500'),
    (N'9', N'10500', N'11500'),
    (N'10', N'11500', N'12500'),
    (N'11', N'12500', N'13500'),
    (N'12', N'13500', N'14500'),
    (N'13', N'14500', N'15500'),
    (N'14', N'15500', N'16500'),
    (N'15', N'16500', N'17500'),
    (N'16', N'17500', N'18000');
END
GO

IF OBJECT_ID(N'dbo.ljpatlen', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ljpatlen (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [序号] INT NOT NULL,
        [长度起始] DECIMAL(12,3) NULL,
        [长度终止] DECIMAL(12,3) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljpatlen_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_ljpatlen_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ljpatlen)
BEGIN
    INSERT dbo.ljpatlen ([序号], [长度起始], [长度终止]) VALUES
    (N'1', N'4700', N'9999'),
    (N'2', N'9999', N'12399'),
    (N'3', N'12399', N'20000'),
    (N'4', N'4000', N'4699');
END
GO

IF OBJECT_ID(N'dbo.lgpath', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lgpath (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [path_idx] INT NOT NULL,
        [zlpath] NVARCHAR(20) NULL,
        [jlpath] NVARCHAR(20) NULL,
        [lzpath] NVARCHAR(20) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgpath_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgpath_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.lgpath)
BEGIN
    INSERT dbo.lgpath ([path_idx], [zlpath], [jlpath], [lzpath]) VALUES
    (N'1', N'A', N'J', N'1'),
    (N'2', N'A', N'JV', N'1'),
    (N'3', N'A', N'K', N'1'),
    (N'4', N'A', N'KH', N'1'),
    (N'5', N'A', N'KHJ', N'1'),
    (N'6', N'A', N'KJ', N'1'),
    (N'7', N'A', N'KL', N'1'),
    (N'8', N'A', N'KR', N'1'),
    (N'9', N'A', N'KRK', N'1'),
    (N'10', N'A', N'KV', N'1'),
    (N'11', N'A', N'L', N'1'),
    (N'12', N'A', N'LH', N'1'),
    (N'13', N'A', N'LHJ', N'1'),
    (N'14', N'A', N'LHK', N'1'),
    (N'15', N'A', N'LR', N'1'),
    (N'16', N'B', N'J', N'1'),
    (N'17', N'B', N'JV', N'1'),
    (N'18', N'B', N'K', N'1'),
    (N'19', N'B', N'KH', N'1'),
    (N'20', N'B', N'KHJ', N'1'),
    (N'21', N'B', N'KJ', N'1'),
    (N'22', N'B', N'KL', N'1'),
    (N'23', N'B', N'KR', N'1'),
    (N'24', N'B', N'KRK', N'1'),
    (N'25', N'B', N'KV', N'1'),
    (N'26', N'B', N'L', N'1'),
    (N'27', N'B', N'LH', N'1'),
    (N'28', N'B', N'LHJ', N'1'),
    (N'29', N'B', N'LHK', N'1'),
    (N'30', N'B', N'LR', N'1'),
    (N'61', N'C', N'J', N'1'),
    (N'62', N'C', N'JV', N'1'),
    (N'63', N'C', N'K', N'1'),
    (N'64', N'C', N'KH', N'1'),
    (N'65', N'C', N'KHJ', N'1'),
    (N'66', N'C', N'KJ', N'1'),
    (N'67', N'C', N'KL', N'1'),
    (N'68', N'C', N'KR', N'1'),
    (N'69', N'C', N'KRK', N'1'),
    (N'70', N'C', N'KV', N'1'),
    (N'71', N'C', N'L', N'1'),
    (N'72', N'C', N'LH', N'1'),
    (N'73', N'C', N'LHJ', N'1'),
    (N'74', N'C', N'LHK', N'1'),
    (N'75', N'C', N'LR', N'1'),
    (N'76', N'A', N'J', N'2'),
    (N'77', N'A', N'JV', N'2'),
    (N'78', N'A', N'K', N'2'),
    (N'79', N'A', N'KH', N'2'),
    (N'80', N'A', N'KHJ', N'2'),
    (N'81', N'A', N'KJ', N'2'),
    (N'82', N'A', N'KL', N'2'),
    (N'83', N'A', N'KR', N'2'),
    (N'84', N'A', N'KRK', N'2'),
    (N'85', N'A', N'KV', N'2'),
    (N'86', N'A', N'L', N'2'),
    (N'87', N'A', N'LH', N'2'),
    (N'88', N'A', N'LHJ', N'2'),
    (N'89', N'A', N'LHK', N'2'),
    (N'90', N'A', N'LR', N'2'),
    (N'91', N'B', N'J', N'2'),
    (N'92', N'B', N'JV', N'2'),
    (N'93', N'B', N'K', N'2'),
    (N'94', N'B', N'KH', N'2'),
    (N'95', N'B', N'KHJ', N'2'),
    (N'96', N'B', N'KJ', N'2'),
    (N'97', N'B', N'KL', N'2'),
    (N'98', N'B', N'KR', N'2'),
    (N'99', N'B', N'KRK', N'2'),
    (N'100', N'B', N'KV', N'2'),
    (N'101', N'B', N'L', N'2'),
    (N'102', N'B', N'LH', N'2'),
    (N'103', N'B', N'LHJ', N'2'),
    (N'104', N'B', N'LHK', N'2'),
    (N'105', N'B', N'LR', N'2'),
    (N'106', N'C', N'J', N'2'),
    (N'107', N'C', N'JV', N'2'),
    (N'108', N'C', N'K', N'2'),
    (N'109', N'C', N'KH', N'2'),
    (N'110', N'C', N'KHJ', N'2'),
    (N'111', N'C', N'KJ', N'2'),
    (N'112', N'C', N'KL', N'2'),
    (N'113', N'C', N'KR', N'2'),
    (N'114', N'C', N'KRK', N'2'),
    (N'115', N'C', N'KV', N'2'),
    (N'116', N'C', N'L', N'2'),
    (N'117', N'C', N'LH', N'2'),
    (N'118', N'C', N'LHJ', N'2'),
    (N'119', N'C', N'LHK', N'2'),
    (N'120', N'C', N'LR', N'2'),
    (N'121', N'A', N'J', N'3'),
    (N'122', N'A', N'JV', N'3'),
    (N'123', N'A', N'K', N'3'),
    (N'124', N'A', N'KH', N'3'),
    (N'125', N'A', N'KHJ', N'3'),
    (N'126', N'A', N'KJ', N'3'),
    (N'127', N'A', N'KL', N'3'),
    (N'128', N'A', N'KR', N'3'),
    (N'129', N'A', N'KRK', N'3'),
    (N'130', N'A', N'KV', N'3'),
    (N'131', N'A', N'L', N'3'),
    (N'132', N'A', N'LH', N'3'),
    (N'133', N'A', N'LHJ', N'3'),
    (N'134', N'A', N'LHK', N'3'),
    (N'135', N'A', N'LR', N'3'),
    (N'136', N'B', N'J', N'3'),
    (N'137', N'B', N'JV', N'3'),
    (N'138', N'B', N'K', N'3'),
    (N'139', N'B', N'KH', N'3'),
    (N'140', N'B', N'KHJ', N'3'),
    (N'141', N'B', N'KJ', N'3'),
    (N'142', N'B', N'KL', N'3'),
    (N'143', N'B', N'KR', N'3'),
    (N'144', N'B', N'KRK', N'3'),
    (N'145', N'B', N'KV', N'3'),
    (N'146', N'B', N'L', N'3'),
    (N'147', N'B', N'LH', N'3'),
    (N'148', N'B', N'LHJ', N'3'),
    (N'149', N'B', N'LHK', N'3'),
    (N'150', N'B', N'LR', N'3'),
    (N'151', N'C', N'J', N'3'),
    (N'152', N'C', N'JV', N'3'),
    (N'153', N'C', N'K', N'3'),
    (N'154', N'C', N'KH', N'3'),
    (N'155', N'C', N'KHJ', N'3'),
    (N'156', N'C', N'KJ', N'3'),
    (N'157', N'C', N'KL', N'3'),
    (N'158', N'C', N'KR', N'3'),
    (N'159', N'C', N'KRK', N'3'),
    (N'160', N'C', N'KV', N'3'),
    (N'161', N'C', N'L', N'3'),
    (N'162', N'C', N'LH', N'3'),
    (N'163', N'C', N'LHJ', N'3'),
    (N'164', N'C', N'LHK', N'3'),
    (N'165', N'C', N'LR', N'3');
END
GO

IF OBJECT_ID(N'dbo.lggongzishebeixishu', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lggongzishebeixishu (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [区域] NVARCHAR(50) NOT NULL,
        [工资系数] DECIMAL(12,3) NULL,
        [设备系数] DECIMAL(12,3) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lggongzishebeixishu_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lggongzishebeixishu_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.lggongzishebeixishu)
BEGIN
    INSERT dbo.lggongzishebeixishu ([区域], [工资系数], [设备系数]) VALUES
    (N'转炉与LF', N'12.4', N'9.8'),
    (N'VD炉', N'1', N'1'),
    (N'RH炉', N'2.18', N'1.2'),
    (N'1#连铸', N'6.37', N'5.16'),
    (N'2#或3#连铸', N'4.34', N'5.48');
END
GO

IF OBJECT_ID(N'dbo.lgxhlx', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.lgxhlx (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [hno] INT NOT NULL,
        [bno] INT NULL,
        [cp] NVARCHAR(100) NULL,
        [dj] NVARCHAR(50) NULL,
        [分摊类型] NVARCHAR(100) NULL,
        [区域] NVARCHAR(50) NULL,
        [列名] NVARCHAR(100) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgxhlx_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_lgxhlx_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.lgxhlx)
BEGIN
    INSERT dbo.lgxhlx ([hno], [bno], [cp], [dj], [分摊类型], [区域], [列名]) VALUES
    (N'1', N'3', N'中高碳锰铁', N'100', N'辊耗分摊', N'炼钢', N''),
    (N'2', N'3', N'低碳锰', N'100', N'轧制方式分摊', N'炼钢', N''),
    (N'3', N'1', N'铁水', N'实绩', N'铁水分摊', N'炼钢', N''),
    (N'4', N'1', N'铁块', N'实绩', N'', N'炼钢', N''),
    (N'5', N'2', N'可深加工废品板', N'3330', N'', N'炼钢', N''),
    (N'6', N'2', N'氧化铁皮', N'260', N'', N'炼钢', N''),
    (N'7', N'2', N'污泥', N'160', N'', N'炼钢', N''),
    (N'8', N'2', N'次品板', N'2900', N'', N'炼钢', N''),
    (N'9', N'2', N'绝废品', N'2350', N'', N'炼钢', N''),
    (N'10', N'2', N'切头尾边', N'2350', N'', N'炼钢', N''),
    (N'11', N'5', N'混煤', N'100', N'产量分摊', N'炼钢', N'hunhemeiqi'),
    (N'12', N'5', N'焦煤', N'100', N'产量分摊', N'炼钢', N'jiaolumeiqi'),
    (N'13', N'5', N'电', N'100', N'产量分摊', N'炼钢', N'dian'),
    (N'14', N'5', N'工业水1', N'100', N'产量分摊', N'炼钢', N'dibiaoshui'),
    (N'15', N'5', N'工业水2', N'100', N'产量分摊', N'炼钢', N'shenjingshui'),
    (N'16', N'5', N'中水', N'100', N'产量分摊', N'炼钢', N'zhongshui'),
    (N'18', N'5', N'压空', N'100', N'产量分摊', N'炼钢', N'yakong'),
    (N'22', N'8', N'工资', N'上月', N'工资系数分摊', N'连铸', N''),
    (N'23', N'8', N'其他职工薪酬', N'上月', N'工资系数分摊', N'连铸', N''),
    (N'24', N'8', N'折旧', N'上月', N'总时间分摊', N'连铸', N''),
    (N'25', N'6', N'直接工资', N'上月', N'工资系数分摊', N'连铸', N''),
    (N'26', N'7', N'直接其他工资薪酬', N'上月', N'工资系数分摊', N'连铸', N''),
    (N'27', N'4', N'铁矿石', N'1.06', N'', N'', N''),
    (N'28', N'8', N'制造费用', N'上月', N'时间乘设备系数分摊', N'连铸', N''),
    (N'29', N'1', N'自产废钢', N'实绩', N'废钢分摊', N'炼钢', N''),
    (N'30', N'1', N'外购废钢', N'实绩', N'废钢分摊', N'炼钢', N''),
    (N'31', N'1', N'渣钢', N'实绩', N'废钢分摊', N'炼钢', N''),
    (N'32', N'3', N'金属锰', N'100', N'实绩消耗', N'炼钢', N''),
    (N'33', N'3', N'硅铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'34', N'3', N'硅锰合金', N'100', N'实绩消耗', N'炼钢', N''),
    (N'35', N'3', N'碳化硅', N'100', N'实绩消耗', N'炼钢', N''),
    (N'36', N'3', N'铝', N'100', N'实绩消耗', N'炼钢', N''),
    (N'37', N'3', N'钢芯铝', N'100', N'实绩消耗', N'炼钢', N''),
    (N'38', N'3', N'铝锰镁铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'39', N'3', N'硅铝铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'40', N'3', N'硅铝钙钡', N'100', N'实绩消耗', N'炼钢', N''),
    (N'41', N'3', N'硅钙合金', N'100', N'实绩消耗', N'炼钢', N''),
    (N'42', N'3', N'钙铁线', N'100', N'实绩消耗', N'炼钢', N''),
    (N'43', N'3', N'铌铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'44', N'3', N'钒氮合金', N'100', N'实绩消耗', N'炼钢', N''),
    (N'45', N'3', N'钒铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'46', N'3', N'铬铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'47', N'3', N'钛铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'48', N'3', N'钼铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'49', N'3', N'硼铁', N'100', N'实绩消耗', N'炼钢', N''),
    (N'50', N'3', N'镍', N'100', N'实绩消耗', N'炼钢', N''),
    (N'51', N'3', N'铜', N'100', N'实绩消耗', N'炼钢', N''),
    (N'52', N'5', N'散装料白灰', N'100', N'实绩消耗', N'炼钢', N''),
    (N'53', N'5', N'散装料白云石', N'100', N'实绩消耗', N'炼钢', N''),
    (N'54', N'5', N'散装料轻烧镁球', N'100', N'实绩消耗', N'炼钢', N''),
    (N'55', N'5', N'散装料萤石', N'100', N'实绩消耗', N'炼钢', N''),
    (N'56', N'5', N'散装料锰矿', N'100', N'实绩消耗', N'炼钢', N''),
    (N'57', N'5', N'散装料碳化钙', N'100', N'实绩消耗', N'炼钢', N''),
    (N'58', N'5', N'散装料钢包改质剂', N'100', N'实绩消耗', N'炼钢', N''),
    (N'59', N'5', N'散装料其它', N'100', N'实绩消耗', N'炼钢', N''),
    (N'60', N'5', N'其他辅助材料增碳剂', N'100', N'实绩消耗', N'炼钢', N''),
    (N'61', N'5', N'其他辅助材料脱硫剂', N'100', N'实绩消耗', N'炼钢', N''),
    (N'62', N'5', N'其他辅助材料其它', N'100', N'实绩消耗', N'炼钢', N''),
    (N'63', N'5', N'铁水包耐材', N'上月', N'脱硫系数分摊', N'炼钢', N''),
    (N'64', N'5', N'冶炼耐材', N'上月', N'钢种系数分摊', N'炼钢', N''),
    (N'65', N'5', N'钢包耐材', N'上月', N'精炼系数分摊', N'炼钢', N''),
    (N'66', N'5', N'连铸耐材', N'上月', N'耐材连铸时间', N'连铸', N''),
    (N'67', N'5', N'其他耐材', N'上月', N'其他耐材产量分摊', N'炼钢', N''),
    (N'68', N'5', N'混煤', N'100', N'按浇次按吨坯', N'连铸', N'hunhemeiqi'),
    (N'69', N'5', N'焦煤', N'100', N'浇铸时间分摊', N'连铸', N'jiaolumeiqi'),
    (N'70', N'5', N'电', N'100', N'浇铸时间分摊', N'连铸', N'dian'),
    (N'71', N'5', N'工业水', N'100', N'浇铸时间分摊', N'连铸', N'dibiaoshui'),
    (N'72', N'5', N'深井水', N'100', N'浇铸时间分摊', N'连铸', N'shenjingshui'),
    (N'73', N'5', N'中水', N'100', N'浇铸时间分摊', N'连铸', N'zhongshui'),
    (N'74', N'5', N'氧气', N'100', N'浇铸时间分摊', N'连铸', N'yangqi'),
    (N'75', N'5', N'氧气', N'100', N'产量分摊', N'炼钢', N'yangqi'),
    (N'76', N'5', N'氩气', N'100', N'产量分摊', N'炼钢', N'yaqi'),
    (N'77', N'5', N'氩气', N'100', N'浇铸时间分摊', N'连铸', N'yaqi'),
    (N'78', N'5', N'氮气', N'100', N'产量分摊', N'炼钢', N'danqi'),
    (N'79', N'5', N'氮气', N'100', N'浇铸时间分摊', N'连铸', N'danqi'),
    (N'80', N'5', N'压空', N'100', N'浇铸时间分摊', N'连铸', N'yakong'),
    (N'81', N'5', N'蒸汽', N'100', N'浇铸时间分摊', N'连铸', N'zhengqi'),
    (N'82', N'5', N'冶炼电极', N'100', N'', N'炼钢', N''),
    (N'83', N'5', N'精炼电极', N'100', N'精炼时间分摊', N'炼钢', N''),
    (N'84', N'5', N'柴油', N'100', N'产量分摊', N'炼钢', N'chaiyou'),
    (N'85', N'5', N'焦炭', N'100', N'产量分摊', N'炼钢', N''),
    (N'87', N'2', N'蒸汽', N'160', N'产量分摊', N'炼钢', N'zhengqi'),
    (N'88', N'2', N'钢渣', N'160', N'', N'炼钢', N''),
    (N'89', N'2', N'回收粗颗粒', N'160', N'钢种标准系分摊', N'炼钢', N'cukeli'),
    (N'90', N'5', N'软水', N'100', N'产量分摊', N'炼钢', N'ruanshui'),
    (N'91', N'5', N'回收煤气', N'0.21', N'产量分摊', N'炼钢', N'huishoumeiqi'),
    (N'92', N'5', N'回收蒸汽', N'50', N'产量分摊', N'炼钢', N'huishouzhengqi'),
    (N'93', N'5', N'软水', N'100', N'浇铸时间分摊', N'连铸', N'ruanshui'),
    (N'94', N'5', N'精炼电耗', N'0', N'精炼时间', N'炼钢', N''),
    (N'95', N'5', N'回收钢渣', N'100', N'产量分摊1', N'炼钢', N'huishougangzha');
END
GO

IF OBJECT_ID(N'dbo.xhlx', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.xhlx (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [序号] INT NOT NULL,
        [消耗类型] NVARCHAR(100) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_xhlx_created DEFAULT (SYSDATETIME()),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_xhlx_updated DEFAULT (SYSDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.xhlx)
BEGIN
    INSERT dbo.xhlx ([序号], [消耗类型]) VALUES
    (N'1', N'钢坯'),
    (N'2', N'回收'),
    (N'3', N'辅助材料'),
    (N'4', N'船级社检测费'),
    (N'5', N'燃料及动力'),
    (N'6', N'直接工资'),
    (N'7', N'直接其他工资薪酬'),
    (N'8', N'制造费用'),
    (N'3', N'辅助材料');
END
GO
