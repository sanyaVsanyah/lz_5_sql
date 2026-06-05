USE master;
GO
DECLARE @DefaultBackupDir NVARCHAR(4000);
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @DefaultBackupDir OUTPUT;
IF @DefaultBackupDir IS NOT NULL
BEGIN
    DECLARE @FullBackupPath NVARCHAR(4000) = @DefaultBackupDir + N'\User_Actions_Generated.bak';
    
    BACKUP DATABASE [User_Actions] 
    TO DISK = @FullBackupPath 
    WITH FORMAT, INIT, NAME = N'User_Actions-Full Database Backup';

    PRINT 'Бэкап создан. Путь к файлу:';
    PRINT @FullBackupPath;
END
ELSE
BEGIN
    PRINT 'Ошибка: Стандартная папка бэкапов не найдена.';
END
GO