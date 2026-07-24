USE [SecondRollingCost];
GO

IF OBJECT_ID(N'dbo.yclyqForm', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.yclyqForm (
        id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        rclyq       NVARCHAR(10) NOT NULL,
        rclms       NVARCHAR(100) NOT NULL,
        created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_yclyqForm_created DEFAULT (SYSDATETIME()),
        updated_at  DATETIME2(0) NOT NULL CONSTRAINT DF_yclyqForm_updated DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_yclyqForm_rclyq UNIQUE (rclyq)
    );
END
GO

MERGE dbo.yclyqForm AS target
USING (VALUES (N'N', N'要求热处理'), (N'X', N'不要求热处理')) AS source(rclyq, rclms)
ON target.rclyq = source.rclyq
WHEN NOT MATCHED THEN
    INSERT (rclyq, rclms) VALUES (source.rclyq, source.rclms);
GO
