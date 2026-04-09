DECLARE @table SYSNAME = 'stg_flight_raw';
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = STRING_AGG(
N'SELECT N''' + REPLACE(name,'''','''''') + N''' AS column_name,
        SUM(CASE 
              WHEN [' + name + N'] IS NULL 
                OR LTRIM(RTRIM(CONVERT(NVARCHAR(MAX), [' + name + N']))) = N'''' 
              THEN 1 ELSE 0 END) AS null_or_blank_count,
        COUNT(*) AS total_rows
   FROM dbo.' + @table
, N' UNION ALL ')
FROM sys.columns
WHERE object_id = OBJECT_ID(N'dbo.' + @table);

SET @sql = N'
WITH p AS (
' + @sql + N'
)
SELECT  column_name,
        null_or_blank_count,
        total_rows,
        CAST(100.0 * null_or_blank_count / NULLIF(total_rows,0) AS DECIMAL(6,2)) AS null_pct
FROM p
ORDER BY null_pct DESC, column_name;';

EXEC sp_executesql @sql;