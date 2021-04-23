USE [PhoneHomeParsed]
GO
/* =============================================
-- Author:		Kirby Richter
-- Create date: 2021-03-02
-- Description:	Return the partitions for a table 
	eg. SELECT * 
		FROM DBA.GetPartitionsForTable('dbo','iocommon_actioninfostate', default)
		--WHERE [partition] <=13
		ORDER BY [partition]
-- ============================================= */
CREATE OR ALTER FUNCTION DBA.GetPartitionsForTable
(	
	
	  @Schema varchar(20) = 'dbo'
	, @TableName varchar(100)
	, @PartFunction varchar(50) = 'PF_RR_PhoneHomeParsedByWeek'
	
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT schema_name(t.schema_id) as [Schema]
		, t.name as [TableName]
		, p.partition_number as [partition]
		, p.rows
		, p.Data_compression_desc as [compression]
		, cast(prv.value as date) as [boundary]
		, fg.name as [FileGroupName]

	FROM sys.tables t
	JOIN sys.indexes i 
		ON t.object_id = i.object_id
	JOIN sys.partitions p
		on i.[object_id] = p.[object_id]
		and i.index_id = p.index_id
	JOIN sys.partition_schemes ps 
		ON i.data_space_id = ps.data_space_id
	JOIN sys.partition_functions pf 
		ON ps.function_id = pf.function_id
	JOIN sys.destination_data_spaces AS sdd
		ON sdd.partition_scheme_id = ps.data_space_id
		and p.partition_number = CASE WHEN sdd.destination_id <= pf.fanout THEN sdd.destination_id ELSE NULL END 
	JOIN sys.filegroups AS fg
		ON sdd.data_space_id = fg.data_space_id
	LEFT JOIN sys.partition_range_values AS prv
		ON prv.function_id = pf.function_id
		AND SDD.destination_id = prv.boundary_id + 1 
	WHERE i.index_id <=1
		and t.is_ms_shipped=0
		and t.name = @TableName
		and SCHEMA_NAME(t.schema_id) = @Schema
		and pf.name = @PartFunction
)
GO
