---
layout: post
title: "Ducklake in Production: Some learnings"
date: 2026-07-15 22:00
comments: true
tags: [data, duckdb, ducklake]
---

I'm excited to share some learning on running [Ducklake](http://ducklake.select/) in production. It's an amazing tool that puts your company or project two feet into data and analytics world with such low cost and entry barrier.

In this post, you will see some of the challenges and learning encountered while running Ducklake in production.

**TL;DR:** *You can use many of the shared tips by using [Lakemon](https://www.lakemon.dev/), a tool that is in the making and brings many of the shared tips to our fingertips. It is under construction.*

<!--more-->

# Past experience with data stack and the cost barrier

I started with more substantial data experience back in 2018 at [Omio](https://www.omio.com/). At that time, the experience revolved around using [RedShift](https://aws.amazon.com/redshift/) to manually extract data to serve our SEO needs. Some initial contact with [Kudu](https://kudu.apache.org/) and [BigQuery](https://cloud.google.com/bigquery/) led to the discovery of the world of data stack.

After that, I had the chance to work at Wayfair, where I got to learn more sophisticated tooling (some of them built in-house) to move data, transform and analyze it.

Finally, at [Moss](https://www.getmoss.com/) I was luck to be tasked with features that several dozens of data pipelines built with [DBT](https://www.getdbt.com/) and BigQuery.

Across these companies, one thing was a common theme: the need for data pipelines to move, transform and analyze data. But also, the high cost and complexity of setting up and maintaining these pipelines. Something that can quickly become prohibitive for small teams or startups.

In the last year (2025/26) the companies I worked at, were at a stage where they can't simply jump head first into BigQuery, [Fievetran](https://www.fivetran.com/), [Estuary](https://www.estuary.dev/), [Firebolt](https://www.firebolt.io/); or maybe RedShift, [Clickhouse cloud](https://clickhouse.com/cloud) or [Crunchy Data Postgres Wharehouse](https://www.crunchydata.com/products/warehouse), [MotherDuck](https://motherduck.com/). They are at the stage where they need a more cost-effective and scalable solution. They want to try, experiment with a couple hundred gigabytes of data before committing to a larger solution.

They need a solution that can support them for a couple of years ideally takes little time to try, no significant investment in personnel, infrastructure, or time, and can let them play big in the data game. This where Ducklake comes in.

# What is Ducklake about?

From the [official manifesto](https://ducklake.select/manifesto/):

> DuckLake simplifies lakehouses by using a standard SQL database for all metadata, instead of complex file-based systems, while still storing data in open formats like Parquet. This makes it more reliable, faster, and easier to manage.

And, yet another definition from Google on Lakehouses:

> A data lakehouse is a modern data architecture that creates a single platform by combining the raw data storage capabilities of data lakes with the organized structure of data warehouses. It enables organizations to use low-cost storage all types of data—structured, unstructured, and semistructured while providing essential management functions like ACID transactions and schema enforcement.

From a certain angle, the watershed point is the separation between storage and compute, while still bringing guarantees of ACID transactions and schema enforcement. And what if instead of using convoluted catalogs and parquet files to store metadata about the stored, we use a standard SQL database? Well here we are: Ducklake!

In our case we have a PostgresSQL to store the catalog, and S3 to store the data. And if you already have some PostgresSQL in place that is kinda "multi-use", you don't even need a dedicated one, just create a database and point your [DuckDB](https://duckdb.org/) process to it.

DuckDB is another important element in this mix. I personally believe it is the most innovative project in the data space since Hadoop and its ecosystem.

And where can Ducklake be applied? To be hones, I don't see mother analytics (let's call it more generally: data initiatives) where it can't be applied. Of course you need to remember that Ducklake is a single process (you can run several read processes, but writing you better have 1 write process **per table** to avoid conflicts). And yes, that aplies to CDC scenarios as well.

By the time of writing this post, Ducklake is handling more than 70GB of data in production with data pipelines grinding through hundreds of millions of rows per pipeline run without issues.

# The learnings

This post is not a code tutorial to copy/paste or a step-by-step walkthrough. It is a summary of our experience using Ducklake in production.

## Inline helps but still costs

One of the biggest challenges people complain about [Iceberg](https://iceberg.apache.org/) and the like is the [explosion of small files](https://www.starburst.io/blog/apache-iceberg-files/). Iceberg writes entire new files on updates, deletes, or inserts, which can lead to a large number of small files over time if you touch a small amount of rows per interaction. And that's almost certain if you run CDC-like ingestion into the lake.

In other words, no easy "just use this nice DuckDB command to copy a 1GB CSV into the lake", but rather, get every row change from your source database and put it into the lake as soon as it arrives.

Ducklake offers a clever solution called [Data Inlining](https://ducklake.select/docs/stable/duckdb/advanced_features/data_inlining) that lets you basically write the changes to the catalog instead of the storage (s3 in my case). Data is also queryable and available immediately after ingestion. 

But what people tend to forget to mention is that you still need to [flush this data](https://ducklake.select/docs/stable/duckdb/advanced_features/data_inlining#flushing-inlined-data) from time to time to avoid your catalog growing too large. _At least the doc makes it clear._

Not only catalog bloat, depending on the load you may actually kill your catalog and you end up with no ingestion running and perhaps data piling up in your messaging infrastructure/CDC infrastructure.

Bellow is a script you can use to check the size of inlined data in your catalog:

```python
#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["duckdb"]
# ///

con = duckdb.connect()
con.execute("INSTALL ducklake; LOAD ducklake;")
con.execute("ATTACH 'ducklake:/path/to/lake.ducklake' AS dlw (READ_ONLY);")

# 1. DuckLake tracks its own inline-data tables — no guessing needed
inline_tables = con.execute("""
    SELECT table_id, table_name
    FROM __ducklake_metadata_dlw.ducklake_inlined_data_tables
""").fetchall()

# 2. COUNT(*) each one for real — size estimates are stale here
counts = {}
for table_id, inline_table in inline_tables:
    n = con.execute(f'''
        SELECT COUNT(*) FROM __ducklake_metadata_dlw.main."{inline_table}"
    ''').fetchone()[0]
    counts[table_id] = counts.get(table_id, 0) + n  # a table may have several batches

# 3. Resolve table_id -> readable schema.table name
for table_id, total in sorted(counts.items(), key=lambda kv: -kv[1]):
    if total == 0:
        continue
    schema, table = con.execute("""
        SELECT s.schema_name, t.table_name
        FROM __ducklake_metadata_dlw.ducklake_table t
        JOIN __ducklake_metadata_dlw.ducklake_schema s ON s.schema_id = t.schema_id
        WHERE t.table_id = ? AND t.end_snapshot IS NULL AND s.end_snapshot IS NULL
    """, [table_id]).fetchone()
    print(f"{schema}.{table}: {total} inlined rows")
```

You should see something like this:

```
recruiting.job_postings      40 inlined rows
payroll.payroll_runs         4 inlined rows
hr.departments               3 inlined rows
hr.benefits_plans            2 inlined rows
```

Runnable script available [here](https://gist.github.com/paulosuzart/c2399650decee54294e91159293843d1).

Of course it makes sense if you wrap the inline data size in the write process itself and trigger the inlining via `CALL ducklake_flush_inlined_data('my_ducklake');`. You can take a precise measure of rows in the catalog and flush accordingly.

When invoked, data will be written to parquet files and into your selected storage.

{% include callout.html type="note" text="**The tradeoff is:** What is a good `DATA_INLINING_ROW_LIMIT` for your use case? 

- Too big: you can ruin the catalog (bloat, slow parquet writes due to partitioning/sorting);
- Too little: you end up with too many small files anyway. I personally tend to bet on CDC infrastructure buffering rather than catalog inlining. Something like [Open Data Buffer](https://www.opendata.dev/blog/buffer-ha-pipelines-without-kafka/), for example." %}

## Sorted tables might be enough (no partitions)

Each write to DuckLake results in one or more files already. And in many cases, the CDC data will land into a [bronze layer](https://www.databricks.com/blog/what-is-medallion-architecture) to be used by downstream data pipelines. The pipelines might consider a window of data to process, rather than processing all data at once. So if you include (as a default value column or added to the data during the ingestino) a `_ingestion_timestamp` column, you can easily filter for data that hasn't been processed yet. For that you take advanted of [Sorted Tables](https://ducklake.select/docs/stable/duckdb/advanced_features/sorted_tables).

With pipelines processing recently ingested data on each run, only recent files will be scanned. With Sorted Tables, ducklake will store `min`/`max` values and fewer files will be used at all. From them doc:

> Sorting data before writing improves the effectiveness of min/max statistics at query time, which allows the DuckDB query engine to skip data files whose value ranges do not overlap with a query's filter predicates.

{% include callout.html type="note" text="**The tradeoff is:** Even with 100Mi records, CDC keeps **adding files** (representing updates, deletes, inserts). If you ingest, say 10GB at once, then partitioning plays a bigger role, but if you ingest smaller chunks that are naturall for CDC, your data is already spread across multiple files and Sorted tables statistics avoids scanning files that are not part of the processing window.

**IMPORTANT:** When [Sorted Tables get compacted](https://ducklake.select/docs/stable/duckdb/maintenance/merge_adjacent_files#sorted-compaction) by `ducklake_merge_adjacent_files`, the sorting will be preserved, but sorting can still be disabled if not strictly needed (very often, I would say).
" %}

I'm not advocating against partitions at all. There are other use cases like Asset price ingestion where data is constantly added and never, or almost never touched. Query usually happens with time and asset filters. As opposed to CDC where the same record gets updated overtime demanding N partitions on each data flush. This is where you notice the number of files explode.

## Call maintenance procedures per table

Ducklake offers a `CHECKPOINT` command that can be used to trigger compaction e purging of old snapshots. You can do some gymnastic to scope a `CHECKPOINT` to a specific table or portion of tables by using [autocompact options](https://ducklake.select/docs/stable/duckdb/maintenance/merge_adjacent_files#controlling-which-tables-are-compacted), but what `CHECKPOINT` does behind the scenes is trigger several maintenance commands that I prefer to run manually per table.

Having one writer per table is a good way to increase throughput, so contention happens at table level. And contention here means flushing inlined data, the regular insert/update/delete operations and running all other maintenance commands.

Ducklake comes with a [rich metadata schema](https://ducklake.select/docs/stable/specification/tables/overview) that allows full introspection of the lake state. One way to see the situation of a table is to query the metadata and decide whether or not certain maintenance commands need to be run:

```sql
SELECT
    t.table_name, s.schema_name,
    COUNT(df.data_file_id) FILTER (WHERE df.end_snapshot IS NULL) AS total_files,
    ROUND(SUM(df.file_size_bytes) FILTER (WHERE df.end_snapshot IS NULL) / 1024.0 / 1024, 2) AS total_mb,
    SUM(df.record_count) FILTER (WHERE df.end_snapshot IS NULL) AS total_rows,
    ROUND(AVG(df.file_size_bytes) FILTER (WHERE df.end_snapshot IS NULL) / 1024.0 / 1024, 2) AS avg_file_mb,
    ROUND(MAX(df.file_size_bytes) FILTER (WHERE df.end_snapshot IS NULL) / 1024.0 / 1024, 4) AS max_file_mb,
    ROUND(MIN(df.file_size_bytes) FILTER (WHERE df.end_snapshot IS NULL) / 1024.0 / 1024, 4) AS min_file_mb,
    COUNT(df.data_file_id) FILTER (WHERE df.end_snapshot IS NULL AND df.file_size_bytes < 5242880) AS small_files,
    (SELECT COUNT(*) FROM __ducklake_metadata_dlw.ducklake_delete_file ddf
     WHERE ddf.table_id = t.table_id AND ddf.end_snapshot IS NULL) AS delete_files
FROM __ducklake_metadata_dlw.ducklake_table t
JOIN __ducklake_metadata_dlw.ducklake_schema s ON t.schema_id = s.schema_id
LEFT JOIN __ducklake_metadata_dlw.ducklake_data_file df ON t.table_id = df.table_id
WHERE t.table_name = 'departments' AND s.schema_name = 'hr'
GROUP BY t.table_id, t.table_name, s.schema_name, t.table_uuid, t.begin_snapshot
```

Tables under `__ducklake_metadata_<attachment_mame>` are accessible and can be queried to get information about the lake state. With that your ingestion process can temporarily pause ingestion to run [`CALL ducklake_merge_adjacent_files`](https://ducklake.select/docs/stable/duckdb/maintenance/merge_adjacent_files), and [`CALL ducklake_rewrite_data_files`](https://ducklake.select/docs/stable/duckdb/maintenance/rewrite_data_files) only when certain thresholds are met. You can essentially keep checking the overall state and trigger maintenance when there's the best time for it.

{% include callout.html type="note" text="**The tradeoff is:**

- Call CHECKPOINT globally that affect N tables and the lake state: Less cognitive load, but misses the opportunity to tail the maintenance for the characteristics of the table, 
- CALL individual maintenance procedures (`ducklake_rewrite_data_files`, `ducklake_merge_adjacent_files`) at table level: More things to know about the lake, but a tailored maintenance for the traffic you get on a table. 

In the end the frequency and thresholds for maintenance in the `customer` table will be very different from the need of a `user_visits` table" %}

## Shard the ingestion

Try to shard the ingestion queues<->tables to contain memory usage on merge and maintenance time for the tables involved. Using a single process for N tables is possible, but sharding will strike the right balance of resources vs maintenance time.

## Call global maintenance during lower traffic

Global maintenance are those that affect the whole lake like [`CALL ducklake_expire_snapshots`](https://ducklake.select/docs/stable/duckdb/maintenance/expire_snapshots) and [`CALL ducklake_cleanup_old_files`](https://ducklake.select/docs/stable/duckdb/maintenance/cleanup_of_files) (use `older_than` for both to control the size of affected files).

For simplicity, pick up a lower traffic ingestion process and enable global maintenance on it. For lower traffic, global maintenance is less disruptive and can be done with less impact on the system.

{% include callout.html type="note" text="**The tradeoff is:**

- Calling global maintenance across all ingestion processes will lead to race conditions on the catalog. 
" %}

Also notice that running global maintenance very often affects the ability to use snapshot information for features like [Changed Data Feed](https://ducklake.select/docs/stable/duckdb/advanced_features/data_change_feed#compaction).

## Table Rewrite is an option

From [the doc](https://ducklake.select/docs/stable/duckdb/maintenance/merge_adjacent_files#schema-evolution):

> ducklake_merge_adjacent_files only merges files that share the same schema version. Schema-altering DDL statements such as ADD COLUMN, DROP COLUMN, RENAME COLUMN, or ALTER COLUMN create a new schema version, so files written before and after the change end up in separate compaction groups and are never merged together. 

This means that changing tables over time will lead to compation not picking up files that were created under older schema versions. Therefore in many situations, simply rewriting the table is the best option.

```sql
CREATE TABLE dlw.bronze.departments_copy
AS SELECT * FROM dlw.bronze.departments_copy

BEGIN TRANSACTION;

DROP TABLE dlw.bronze.departments;

CREATE TABLE dlw.bronze.departments
AS SELECT * FROM dlw.bronze.departments_copy;

ALTER TABLE dlw.bronze.departments SET SORTED BY (_ingestion_ts);

COMMIT;

```

Just pay attention to the table size and if possible, stop the ingestion to perform the operation. Your messaging structure will need to hold the traffic in the meantime.

# Conclusion

These are some of the learnings and tips I could share after running a lakehouse in production. It is a couple of hundreds of gigabytes, but it is enough to get exposed to a lot of practices to take the best out of the platform.

I personally get really excited about lakehouses. Their flexibility, scalability, and low cost of entry is what makes them so attractive.

While a powerful tool that can easily become part of your data stack, operating a lakehouse requires constant monitoring of its health. Luckily, DuckLake provides all metadata possible to monitor the health of your lakehouse. And the metadata available allowed me to build [Lakemon](https://www.lakemon.dev/). A tool that is in the making and brings many of the shared tips to our fingertips. It is essentially in the making and being matured with real daily usage.
