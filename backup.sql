USE master;
GO

IF OBJECT_ID('dbo.sp_RestoreUserDatabase', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RestoreUserDatabase;
GO

CREATE PROCEDURE dbo.sp_RestoreUserDatabase
    @DatabaseName NVARCHAR(128),  
    @BackupFilePath NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DynamicSql NVARCHAR(MAX);
    PRINT 'Восстановление базы: ' + @DatabaseName;
    PRINT 'Файл бэкапа: ' + @BackupFilePath;
    IF EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        PRINT 'Отключение пользователей (SINGLE_USER)...';
        SET @DynamicSql = N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
        EXEC sp_executesql @DynamicSql;
    END
    ELSE
    BEGIN
        PRINT 'База данных не существует. Создание из бэкапа...';
    END
    PRINT 'Запуск RESTORE...';
    SET @DynamicSql = N'RESTORE DATABASE ' + QUOTENAME(@DatabaseName) + N' 
                        FROM DISK = ' + QUOTENAME(@BackupFilePath, '''') + N' 
                        WITH REPLACE, RECOVERY;';
    BEGIN TRY
        EXEC sp_executesql @DynamicSql;
        PRINT 'База данных успешно восстановлена.';
    END TRY
    BEGIN CATCH
        PRINT 'Ошибка восстановления: ' + ERROR_MESSAGE();
        IF EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
        BEGIN
            SET @DynamicSql = N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET MULTI_USER;';
            EXEC sp_executesql @DynamicSql;
        END
        ;THROW;
    END CATCH
    IF EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        SET @DynamicSql = N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET MULTI_USER;';
        EXEC sp_executesql @DynamicSql;
        PRINT 'Доступ открыт (MULTI_USER).';
    END
END;
GO