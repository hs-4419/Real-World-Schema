# Stack overflow uses MS SQL Server
# Stack overflow database queries

# 1) Count number of tables in the database
select count(*) as 'No. of tables' from sys.tables;
## No. of tables: 29
## Execution time: <1 ms

# 2) Count number of users in the database
select count(*) as 'No. of users' from users;
## No. of users: 29921408
## Execution time: 1218 ms

# 3) Count number of posts in the database
select count(*) as 'No. of posts' from posts;
## No. of posts: 60374242
## Execution time: 1107 ms

select customer_number from orders
group by customer_number
having count(*) >= (select count(*) from orders group by customer_number order by count(*) desc);


-- analyze my query in detail in postgres and find all the possible pitfalls and suggest improvements and alternatives/optimizations. Also explain the concepts in detail which are reqd to write the query and their nearby concepts reqd to deepen the knowledge


-- i wanna solve this problem
-- make me write the correct query and approach the soln the correct way
-- Also explain the concepts in detail which are reqd to write the query and their nearby concepts reqd to deepen the knowledge

SELECT t.NAME AS TableName,
       p.rows AS RowCounts,
       SUM(a.total_pages) * 8.0  / 1024 / 1024 AS TotalSpaceGB
INTO #tmp
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.NAME NOT LIKE 'dt%' 
  AND t.is_ms_shipped = 0
  AND i.OBJECT_ID > 255 
GROUP BY t.Name, s.Name, p.Rows
ORDER BY s.Name, t.Name

SELECT 'Total' AS TableName, 
       SUM(RowCounts) AS RowCounts, 
       SUM(TotalSpaceGB) AS TotalSpaceGB
FROM #tmp
UNION ALL
SELECT '-----' AS TableName, 
       NULL AS RowCounts, 
       NULL AS TotalSpaceGB
UNION ALL 
SELECT * FROM #tmp
