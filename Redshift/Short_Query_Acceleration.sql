*** Short Query Acceleration (SQA) in Redshift ***
Prioritizes short-running queries ahead of long-running queries.
Short-running queries get executed in a dedicated space.
Can reduce or get rid of WLM queues that are dedicated to running short queries.
CREATE TABLE AS and SELECT statements are eligible for SQA.
WLM by default dynamically assigns a value for the SQA maximum run time based on analysis of your cluster's workload. Alternatively, you can specify a fixed value of 1–20 seconds.
AWS recommends keeping the dynamic setting for SQA maximum run time. 

* Monitoring SQA *
-- To check whether SQA is enabled, run the following query.  If the query returns a row, then SQA is enabled.
SELECT  *
FROM    stv_wlm_service_class_config
WHERE   service_class = 14;

-- The following query shows the number of queries that went through each query queue (service class). 
-- It also shows the average execution time, the number of queries with wait time at the 90th percentile, 
-- and the average wait time. SQA queries use in service class 14.
SELECT  final_state,
        service_class,
        COUNT(1),
        AVG(total_exec_time) as avg_exec_time_in_ms,
        PERCENTILE_CONT(0.9) within group(ORDER BY total_queue_time),
        AVG(total_queue_time) as avg_queue_time_in_ms
FROM    stl_wlm_query
WHERE   userid >= 100 and service_class = 14
GROUP 
BY      final_state,
        service_class
ORDER 
BY      service_class,
        final_state;

-- To find which queries were picked up by SQA and completed successfully, run the following query.
SELECT  a.queue_start_time,
        a.total_exec_time,
        label,
        TRIM(querytxt)
FROM    stl_wlm_query a,
        stl_query b
WHERE   a.query = b.query
AND     a.service_class = 14
AND     a.final_state = 'Completed'
ORDER 
BY      b.query DESC LIMIT 5;

-- To find queries that SQA picked up but that timed out, run the following query.
SELECT  a.queue_start_time,
        a.total_exec_time,
        label,
        TRIM(querytxt)
FROM    stl_wlm_query a,
        stl_query b
WHERE   a.query = b.query
AND     a.service_class = 14
AND     a.final_state = 'Evicted'
ORDER 
BY      b.query DESC LIMIT 5;

Reference: https://docs.aws.amazon.com/redshift/latest/dg/wlm-short-query-acceleration.html
