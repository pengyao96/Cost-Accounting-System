USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.yclyqForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.yclyq', N'U') IS NULL EXEC sp_rename N'dbo.yclyqForm', N'yclyq';
IF OBJECT_ID(N'dbo.lggradeForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.lggrade', N'U') IS NULL EXEC sp_rename N'dbo.lggradeForm', N'lggrade';
IF OBJECT_ID(N'dbo.ljgradeForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.ljgrade', N'U') IS NULL EXEC sp_rename N'dbo.ljgradeForm', N'ljgrade';
IF OBJECT_ID(N'dbo.rzgradeForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.rzgrade', N'U') IS NULL EXEC sp_rename N'dbo.rzgradeForm', N'rzgrade';
IF OBJECT_ID(N'dbo.lgthickForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.lgthick', N'U') IS NULL EXEC sp_rename N'dbo.lgthickForm', N'lgthick';
IF OBJECT_ID(N'dbo.ljthickForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.ljthick', N'U') IS NULL EXEC sp_rename N'dbo.ljthickForm', N'ljthick';
IF OBJECT_ID(N'dbo.thickForm', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.thick', N'U') IS NULL EXEC sp_rename N'dbo.thickForm', N'thick';
GO
