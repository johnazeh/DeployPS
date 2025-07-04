

# Create an empty collection to hold all results
$allResults = @()

# Get list of user databases
$databases = Invoke-Sqlcmd -ServerInstance $serverName -Credential $credential -Query "
    SELECT name FROM sys.databases 
    WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')"

foreach ($db in $databases) {
    $dbName = $db.name
    Write-Host "`nChecking database: $dbName" -ForegroundColor Cyan

    # Query masked columns
    $query = @"
    SELECT 
        '$dbName' AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName,
        c.is_masked AS IsMasked,
        c.masking_function AS MaskingFunction
    FROM sys.masked_columns c
    JOIN sys.columns col ON c.column_id = col.column_id AND c.object_id = col.object_id
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id;
"@

    $results = Invoke-Sqlcmd -ServerInstance $serverName -Database $dbName -Credential $credential -Query $query

    if ($results) {
        $allResults += $results
        Write-Host "Added results from $dbName." -ForegroundColor Green
    } else {
        Write-Host "No masked columns found in $dbName." -ForegroundColor DarkGray
    }
}

# Export all results to a single CSV file
$finalCsvPath = "C:\AllMaskedColumns.csv"
$allResults | Export-Csv -Path $finalCsvPath -NoTypeInformation
Write-Host "`n✔️ All results saved to $finalCsvPath" -ForegroundColor Cyan
