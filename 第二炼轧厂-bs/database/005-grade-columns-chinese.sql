USE [SecondRollingCost];
GO

IF COL_LENGTH(N'dbo.lggradeForm', N'grade') IS NOT NULL EXEC sp_rename N'dbo.lggradeForm.grade', N'钢种', N'COLUMN';
IF COL_LENGTH(N'dbo.lggradeForm', N'product') IS NOT NULL EXEC sp_rename N'dbo.lggradeForm.product', N'品种', N'COLUMN';
IF COL_LENGTH(N'dbo.lggradeForm', N'series') IS NOT NULL EXEC sp_rename N'dbo.lggradeForm.series', N'系列', N'COLUMN';
GO

IF COL_LENGTH(N'dbo.ljgradeForm', N'grade') IS NOT NULL EXEC sp_rename N'dbo.ljgradeForm.grade', N'钢种', N'COLUMN';
IF COL_LENGTH(N'dbo.ljgradeForm', N'product') IS NOT NULL EXEC sp_rename N'dbo.ljgradeForm.product', N'品种', N'COLUMN';
IF COL_LENGTH(N'dbo.ljgradeForm', N'series') IS NOT NULL EXEC sp_rename N'dbo.ljgradeForm.series', N'系列', N'COLUMN';
GO

IF COL_LENGTH(N'dbo.rzgradeForm', N'grade') IS NOT NULL EXEC sp_rename N'dbo.rzgradeForm.grade', N'钢种', N'COLUMN';
IF COL_LENGTH(N'dbo.rzgradeForm', N'product') IS NOT NULL EXEC sp_rename N'dbo.rzgradeForm.product', N'品种', N'COLUMN';
IF COL_LENGTH(N'dbo.rzgradeForm', N'series') IS NOT NULL EXEC sp_rename N'dbo.rzgradeForm.series', N'系列', N'COLUMN';
GO
