USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'User_Actions')
BEGIN
    CREATE DATABASE User_Actions;
END
GO

USE User_Actions;
GO

IF OBJECT_ID('dbo.User_Logs', 'U') IS NOT NULL
    DROP TABLE dbo.User_Logs;
GO
IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_Monthly2025')
    DROP PARTITION SCHEME PS_Monthly2025;
GO
IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_Monthly2025')
    DROP PARTITION FUNCTION PF_Monthly2025;
GO

CREATE PARTITION FUNCTION PF_Monthly2025 (DATE)
AS RANGE RIGHT FOR VALUES 
(
    '2025-02-01', 
    '2025-03-01', 
    '2025-04-01', 
    '2025-05-01', 
    '2025-06-01', 
    '2025-07-01', 
    '2025-08-01', 
    '2025-09-01', 
    '2025-10-01', 
    '2025-11-01', 
    '2025-12-01'
)
GO

CREATE PARTITION SCHEME PS_Monthly2025
AS PARTITION PF_Monthly2025
ALL TO ([PRIMARY]);
GO

CREATE TABLE dbo.User_Logs(
    id INT IDENTITY(1,1) NOT NULL,
    username NVARCHAR(50) NOT NULL,
    user_action NVARCHAR(50) NOT NULL,
    action_date date NOT NULL,
    action_time time NOT NULL,
    action_result NVARCHAR(MAX) NOT NULL,
    CONSTRAINT PK_User_Logs PRIMARY KEY CLUSTERED (id, action_date)
) ON PS_Monthly2025(action_date);
GO

SET NOCOUNT ON;

DECLARE @TargetRows INT = 1000000;
DECLARE @RowsPerBatch INT = 50000;
DECLARE @RowsInserted INT = 0;
WHILE @RowsInserted < @TargetRows
BEGIN
    DECLARE @CurrentBatch INT = CASE WHEN @TargetRows - @RowsInserted >= @RowsPerBatch THEN @RowsPerBatch ELSE @TargetRows - @RowsInserted END;
    DECLARE @SeedUser INT = CAST(CRYPT_GEN_RANDOM(4) AS INT);
    DECLARE @SeedAct  INT = CAST(CRYPT_GEN_RANDOM(4) AS INT);
    DECLARE @SeedDate INT = CAST(CRYPT_GEN_RANDOM(4) AS INT);
    DECLARE @SeedTime INT = CAST(CRYPT_GEN_RANDOM(4) AS INT);
    DECLARE @SeedRes  INT = CAST(CRYPT_GEN_RANDOM(4) AS INT);
    ;WITH
    E1(n) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
             UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1), 
    E2(n) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b), 
    E4(n) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b), 
    Tally AS (
        SELECT TOP (@CurrentBatch) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM E4 a CROSS JOIN E1 b
    )
    INSERT INTO dbo.User_Logs (username, user_action, action_date, action_time, action_result)
    SELECT
        CHOOSE(((CHECKSUM(t.n, @SeedUser) & 0x7FFFFFFF) % 10) + 1, N'ivan', N'anna', N'petr', N'olga', N'maria', N'alex', N'dmitry', N'ekaterina', N'sergey', N'oleg'),
        CHOOSE(((CHECKSUM(t.n, @SeedAct)  & 0x7FFFFFFF) % 10) + 1, N'login', N'logout', N'view_page', N'edit_profile', N'create_order', N'cancel_order', N'upload_file', N'download_report', N'search', N'change_password'),
        DATEADD(DAY, (CHECKSUM(t.n, @SeedDate) & 0x7FFFFFFF) % (DATEDIFF(DAY, '2025-01-01', '2025-12-31')), '2025-01-01'),
        CAST(DATEADD(SECOND, (CHECKSUM(t.n, @SeedTime) & 0x7FFFFFFF) % 86400, '00:00:00') AS TIME(0)),
        CHOOSE(((CHECKSUM(t.n, @SeedRes)  & 0x7FFFFFFF) % 6) + 1, N'success', N'failure', N'not_found', N'forbidden', N'timeout', N'partial_success')
    FROM Tally t;
    SET @RowsInserted += @CurrentBatch;
    PRINT CONCAT('Inserted rows: ', @RowsInserted);
END

SET NOCOUNT OFF;
GO

SELECT 
    p.partition_number AS [Номер секции],
    p.rows AS [Количество строк],
    CASE 
        WHEN p.partition_number = 1 THEN 'Начало времен' 
        ELSE CONVERT(VARCHAR, LAG(rv.value) OVER (ORDER BY p.partition_number)) 
    END AS [Нижняя граница (Включая)],
    ISNULL(CONVERT(VARCHAR, rv.value), 'Конец времен') AS [Верхняя граница (Исключая)]
FROM sys.partitions p
JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
LEFT JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
LEFT JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values rv ON pf.function_id = rv.function_id AND p.partition_number = rv.boundary_id
WHERE p.object_id = OBJECT_ID('dbo.User_Logs') 
  AND i.index_id <= 1;