
/*
  Find a GUID

  Find if a supplied GUID is used in any UNIQUEIDENTIFIER field
  in your database.

*/
SET NOCOUNT ON

DECLARE @findGUID UNIQUEIDENTIFIER

/* CHANGE THIS VALUE */
SET @findGUID = N'<INSERT GUID HERE>'

DECLARE @columns  TABLE ( TableName SYSNAME, 
                          ColumnName SYSNAME, 
                          HasProcessed bit DEFAULT(0), 
                          HasValue bit DEFAULT(0) )

DECLARE @sqlBase  NVARCHAR(MAX)
DECLARE @sql      NVARCHAR(MAX)
DECLARE @tblName  SYSNAME
DECLARE @colName  SYSNAME
DECLARE @hasValue INT

SET @sqlBase = N'SELECT @hasValueOUT = COUNT(*) FROM [<tablename>] WHERE [<columnname>] = ''' + CAST(@findGUID AS NVARCHAR(36)) + ''''

INSERT INTO @columns ( TableName, ColumnName )
  SELECT DISTINCT
    OBJECT_NAME(col.object_id), col.name
  FROM
    sys.columns col
      INNER JOIN sys.tables tbl
        ON col.object_id = tbl.object_id
  WHERE
        col.system_type_id = 36   -- UNIQUEIDENTIFIER
    AND tbl.type = N'U'           -- User Table (vs. System Tables or Views)

WHILE EXISTS( SELECT * FROM @columns WHERE HasProcessed = 0 )
BEGIN
  SELECT TOP 1
    @tblName = TableName,
    @colName = ColumnName
  FROM
    @columns
  WHERE
    HasProcessed = 0

  SET @sql = REPLACE(@sqlBase, N'<tablename>', @tblName)
  SET @sql = REPLACE(@sql, N'<columnname>', @colName)
  
  BEGIN TRY
    EXEC sp_executesql @sql, N'@hasValueOUT INT OUTPUT', @hasValueOUT = @hasValue OUTPUT
  END TRY
  BEGIN CATCH
    PRINT N' ERROR -- ' + @sql
  END CATCH

  UPDATE @columns
     SET HasProcessed = 1
       , HasValue     = @hasValue
   WHERE TableName  = @tblName
     AND ColumnName = @colName

END

SELECT *, [sql] = N'SELECT * FROM ' + TableName + N' WHERE ' + ColumnName + ' = N''' + CAST(@findGUID AS NVARCHAR(36)) + ''''
  FROM @columns
 WHERE HasValue = 1

SET NOCOUNT OFF


