USE [SecondRollingCost];
GO

IF COL_LENGTH(N'dbo.sys_users', N'password_plain') IS NULL
BEGIN
    ALTER TABLE dbo.sys_users ADD password_plain NVARCHAR(256) NULL;
END
GO

-- The initial accounts are created by this project with password 123456.
-- Password hashes cannot be reversed; other historical accounts must be reset explicitly.
UPDATE dbo.sys_users
SET password_plain = N'123456'
WHERE password_plain IS NULL
  AND account IN (N'admin', N'yaopeng', N'guoxiaoming', N'songmengxiao');
GO
