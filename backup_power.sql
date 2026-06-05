USE master;
GO

EXEC dbo.sp_RestoreUserDatabase 
    @DatabaseName = N'User_Actions', 
    @BackupFilePath = N'C:\Users\sanya\OneDrive\Рабочий стол\MSSQL17.MSSQLSERVER\MSSQL\Backup\User_Actions_Generated.bak';