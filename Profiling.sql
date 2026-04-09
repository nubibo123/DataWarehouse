/* 0) RAW CHECK SAU IMPORT*/
SELECT COUNT(*) AS total_rows FROM dbo.stg_flight_raw;
SELECT TOP 20 * FROM dbo.stg_flight_raw;


/* 1) TAO BANG TYPED (EP KIEU + CHUAN HOA) */
DROP TABLE IF EXISTS dbo.stg_flight_typed;

SELECT
    COALESCE(
        TRY_CONVERT(date, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), FlightDate))), ''), 23),  -- yyyy-mm-dd
        TRY_CONVERT(date, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), FlightDate))), ''), 101), -- mm/dd/yyyy
        TRY_CONVERT(date, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), FlightDate))), ''), 103)  -- dd/mm/yyyy
    ) AS FlightDate_d,

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), [Year]))), '')) AS Year_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), [Quarter]))), '')) AS Quarter_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), [Month]))), '')) AS Month_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DayofMonth))), '')) AS DayOfMonth_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DayOfWeek))), '')) AS DayOfWeek_i,

    UPPER(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Origin))), '')) AS Origin_c,
    UPPER(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Dest))), '')) AS Dest_c,

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Cancelled))), '')) AS Cancelled_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Diverted))), '')) AS Diverted_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), CRSElapsedTime))), '')) AS CRSElapsedTime_i,

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), CRSDepTime))), '')) AS CRSDepTime_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), CRSArrTime))), '')) AS CRSArrTime_i,

    TRY_CONVERT(decimal(18,2), NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(30), Distance))), '')) AS Distance_n,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Flights))), '')) AS Flights_i,

    UPPER(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(10), [Duplicate]))), '')) AS Duplicate_c
INTO dbo.stg_flight_typed
FROM dbo.stg_flight_raw;


/* 2) INDEX DE CHAY PROFILING NHANH */
CREATE CLUSTERED COLUMNSTORE INDEX CCI_stg_flight_typed
ON dbo.stg_flight_typed;


/* 3) PROFILING TONG QUAN */
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN FlightDate_d IS NULL THEN 1 ELSE 0 END) AS bad_FlightDate,
    SUM(CASE WHEN Duplicate_c <> 'N' OR Duplicate_c IS NULL THEN 1 ELSE 0 END) AS bad_Duplicate,
    SUM(CASE WHEN Cancelled_i NOT IN (0,1) OR Cancelled_i IS NULL THEN 1 ELSE 0 END) AS bad_Cancelled,
    SUM(CASE WHEN Diverted_i NOT IN (0,1) OR Diverted_i IS NULL THEN 1 ELSE 0 END) AS bad_Diverted,
    SUM(CASE WHEN Distance_n <= 0 OR Distance_n IS NULL THEN 1 ELSE 0 END) AS bad_Distance,
    SUM(CASE WHEN CRSElapsedTime_i <= 0 OR CRSElapsedTime_i IS NULL THEN 1 ELSE 0 END) AS bad_CRSElapsed
FROM dbo.stg_flight_typed;


/* 4) PHAN TICH RIENG CRSElapsedTime NULL */
-- 4.1 Ty le null theo trang thai huy/chuyen huong
SELECT
    Cancelled_i,
    Diverted_i,
    COUNT(*) AS rows_cnt,
    SUM(CASE WHEN CRSElapsedTime_i IS NULL THEN 1 ELSE 0 END) AS null_elapsed
FROM dbo.stg_flight_typed
GROUP BY Cancelled_i, Diverted_i
ORDER BY Cancelled_i, Diverted_i;

-- 4.2 Null do raw blank hay parse loi
SELECT
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(50), CRSElapsedTime))), '') IS NULL THEN 1 ELSE 0 END) AS blank_in_raw,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(50), CRSElapsedTime))), '') IS NOT NULL
              AND TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(50), CRSElapsedTime))), '')) IS NULL
             THEN 1 ELSE 0 END) AS invalid_numeric_in_raw
FROM dbo.stg_flight_raw;

-- 4.3 Mau gia tri parse loi
SELECT TOP 50
    CRSElapsedTime
FROM dbo.stg_flight_raw
WHERE NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(50), CRSElapsedTime))), '') IS NOT NULL
  AND TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(50), CRSElapsedTime))), '')) IS NULL;


/* 5) BUSINESS RULE CHECK CHO CRSElapsedTime */
SELECT
    SUM(
        CASE
            WHEN ISNULL(Cancelled_i,0)=0
             AND ISNULL(Diverted_i,0)=0
             AND (CRSElapsedTime_i IS NULL OR CRSElapsedTime_i <= 0)
            THEN 1 ELSE 0
        END
    ) AS bad_CRSElapsed_business
FROM dbo.stg_flight_typed;

;WITH t AS (
    SELECT
        *,
        CASE
            WHEN CRSDepTime_i BETWEEN 0 AND 2359
             AND CRSArrTime_i BETWEEN 0 AND 2359
             AND (CRSDepTime_i % 100) < 60
             AND (CRSArrTime_i % 100) < 60
            THEN ((CRSArrTime_i / 100) * 60 + (CRSArrTime_i % 100))
               - ((CRSDepTime_i / 100) * 60 + (CRSDepTime_i % 100))
            ELSE NULL
        END AS diff_min_raw
    FROM dbo.stg_flight_typed
)
SELECT
    COUNT(*) AS hard_fail_rows,
    SUM(CASE WHEN diff_min_raw IS NOT NULL THEN 1 ELSE 0 END) AS can_derive_same_day,
    SUM(CASE WHEN diff_min_raw < 0 THEN 1 ELSE 0 END) AS overnight_need_plus_1440
FROM t
WHERE Cancelled_i = 0
  AND Diverted_i = 0
  AND CRSElapsedTime_i IS NULL;


/* 6) BUSINESS RULES FINAL: TACH REJECT/CLEAN + DQ FLAG */
DROP TABLE IF EXISTS dbo.stg_flight_reject;
DROP TABLE IF EXISTS dbo.stg_flight_clean;

;WITH rules AS (
    SELECT
        t.*,

        /* Hard rules: vi pham se bi reject */
        CASE WHEN t.Duplicate_c IS NULL OR t.Duplicate_c <> 'N' THEN 1 ELSE 0 END AS r_duplicate,
        CASE WHEN t.FlightDate_d IS NULL THEN 1 ELSE 0 END AS r_flightdate_invalid,
        CASE WHEN t.Origin_c IS NULL OR LEN(t.Origin_c) <> 3 THEN 1 ELSE 0 END AS r_origin_invalid,
        CASE WHEN t.Dest_c IS NULL OR LEN(t.Dest_c) <> 3 THEN 1 ELSE 0 END AS r_dest_invalid,
        CASE WHEN t.Cancelled_i NOT IN (0,1) OR t.Cancelled_i IS NULL THEN 1 ELSE 0 END AS r_cancelled_invalid,
        CASE WHEN t.Diverted_i NOT IN (0,1) OR t.Diverted_i IS NULL THEN 1 ELSE 0 END AS r_diverted_invalid,
        CASE WHEN t.Distance_n IS NULL OR t.Distance_n <= 0 THEN 1 ELSE 0 END AS r_distance_invalid,
        CASE WHEN t.Flights_i IS NULL OR t.Flights_i < 1 THEN 1 ELSE 0 END AS r_flights_invalid,

        /* Soft rules: khong reject, chi gan canh bao */
        CASE
            WHEN ISNULL(t.Cancelled_i,0) = 0
             AND ISNULL(t.Diverted_i,0) = 0
             AND (t.CRSElapsedTime_i IS NULL OR t.CRSElapsedTime_i <= 0)
            THEN 1 ELSE 0
        END AS w_elapsed_missing_on_normal,
        CASE
            WHEN t.CRSDepTime_i IS NOT NULL
             AND NOT (t.CRSDepTime_i BETWEEN 0 AND 2359 AND (t.CRSDepTime_i % 100) < 60)
            THEN 1 ELSE 0
        END AS w_deptime_invalid,
        CASE
            WHEN t.CRSArrTime_i IS NOT NULL
             AND NOT (t.CRSArrTime_i BETWEEN 0 AND 2359 AND (t.CRSArrTime_i % 100) < 60)
            THEN 1 ELSE 0
        END AS w_arrtime_invalid
    FROM dbo.stg_flight_typed t
),
scored AS (
    SELECT
        r.*,
        CASE
            WHEN r.r_duplicate + r.r_flightdate_invalid + r.r_origin_invalid + r.r_dest_invalid
               + r.r_cancelled_invalid + r.r_diverted_invalid + r.r_distance_invalid + r.r_flights_invalid > 0
            THEN 1 ELSE 0
        END AS IsRejected,
        CASE
            WHEN r.w_elapsed_missing_on_normal + r.w_deptime_invalid + r.w_arrtime_invalid > 0
            THEN 1 ELSE 0
        END AS DQFlag,

        CONCAT(
            CASE WHEN r.r_duplicate = 1 THEN ';Duplicate_not_N' ELSE '' END,
            CASE WHEN r.r_flightdate_invalid = 1 THEN ';FlightDate_invalid' ELSE '' END,
            CASE WHEN r.r_origin_invalid = 1 THEN ';Origin_invalid' ELSE '' END,
            CASE WHEN r.r_dest_invalid = 1 THEN ';Dest_invalid' ELSE '' END,
            CASE WHEN r.r_cancelled_invalid = 1 THEN ';Cancelled_not_0_1' ELSE '' END,
            CASE WHEN r.r_diverted_invalid = 1 THEN ';Diverted_not_0_1' ELSE '' END,
            CASE WHEN r.r_distance_invalid = 1 THEN ';Distance_invalid' ELSE '' END,
            CASE WHEN r.r_flights_invalid = 1 THEN ';Flights_invalid' ELSE '' END
        ) AS RejectReasonRaw,

        CONCAT(
            CASE WHEN r.w_elapsed_missing_on_normal = 1 THEN ';Elapsed_missing_normal_flight' ELSE '' END,
            CASE WHEN r.w_deptime_invalid = 1 THEN ';CRSDepTime_invalid' ELSE '' END,
            CASE WHEN r.w_arrtime_invalid = 1 THEN ';CRSArrTime_invalid' ELSE '' END
        ) AS WarningReasonRaw
    FROM rules r
),
finalized AS (
    SELECT
        s.*,
        CASE WHEN LEFT(s.RejectReasonRaw,1) = ';' THEN STUFF(s.RejectReasonRaw,1,1,'') ELSE s.RejectReasonRaw END AS RejectReason,
        CASE WHEN LEFT(s.WarningReasonRaw,1) = ';' THEN STUFF(s.WarningReasonRaw,1,1,'') ELSE s.WarningReasonRaw END AS WarningReason,

        CASE
            WHEN s.CRSElapsedTime_i IS NOT NULL AND s.CRSElapsedTime_i > 0 THEN s.CRSElapsedTime_i
            WHEN ISNULL(s.Cancelled_i,0) = 1 OR ISNULL(s.Diverted_i,0) = 1 THEN NULL
            WHEN s.CRSDepTime_i BETWEEN 0 AND 2359
             AND s.CRSArrTime_i BETWEEN 0 AND 2359
             AND (s.CRSDepTime_i % 100) < 60
             AND (s.CRSArrTime_i % 100) < 60
            THEN
                CASE
                    WHEN (((s.CRSArrTime_i / 100) * 60 + (s.CRSArrTime_i % 100))
                        - ((s.CRSDepTime_i / 100) * 60 + (s.CRSDepTime_i % 100))) < 0
                    THEN (((s.CRSArrTime_i / 100) * 60 + (s.CRSArrTime_i % 100))
                        - ((s.CRSDepTime_i / 100) * 60 + (s.CRSDepTime_i % 100)) + 1440)
                    ELSE (((s.CRSArrTime_i / 100) * 60 + (s.CRSArrTime_i % 100))
                        - ((s.CRSDepTime_i / 100) * 60 + (s.CRSDepTime_i % 100)))
                END
            ELSE NULL
        END AS CRSElapsedTime_final
    FROM scored s
)
SELECT
    *
INTO dbo.stg_flight_reject
FROM finalized
WHERE IsRejected = 1;

;WITH rules AS (
    SELECT
        t.*,
        CASE WHEN t.Duplicate_c IS NULL OR t.Duplicate_c <> 'N' THEN 1 ELSE 0 END AS r_duplicate,
        CASE WHEN t.FlightDate_d IS NULL THEN 1 ELSE 0 END AS r_flightdate_invalid,
        CASE WHEN t.Origin_c IS NULL OR LEN(t.Origin_c) <> 3 THEN 1 ELSE 0 END AS r_origin_invalid,
        CASE WHEN t.Dest_c IS NULL OR LEN(t.Dest_c) <> 3 THEN 1 ELSE 0 END AS r_dest_invalid,
        CASE WHEN t.Cancelled_i NOT IN (0,1) OR t.Cancelled_i IS NULL THEN 1 ELSE 0 END AS r_cancelled_invalid,
        CASE WHEN t.Diverted_i NOT IN (0,1) OR t.Diverted_i IS NULL THEN 1 ELSE 0 END AS r_diverted_invalid,
        CASE WHEN t.Distance_n IS NULL OR t.Distance_n <= 0 THEN 1 ELSE 0 END AS r_distance_invalid,
        CASE WHEN t.Flights_i IS NULL OR t.Flights_i < 1 THEN 1 ELSE 0 END AS r_flights_invalid,
        CASE
            WHEN ISNULL(t.Cancelled_i,0) = 0
             AND ISNULL(t.Diverted_i,0) = 0
             AND (t.CRSElapsedTime_i IS NULL OR t.CRSElapsedTime_i <= 0)
            THEN 1 ELSE 0
        END AS w_elapsed_missing_on_normal,
        CASE
            WHEN t.CRSDepTime_i IS NOT NULL
             AND NOT (t.CRSDepTime_i BETWEEN 0 AND 2359 AND (t.CRSDepTime_i % 100) < 60)
            THEN 1 ELSE 0
        END AS w_deptime_invalid,
        CASE
            WHEN t.CRSArrTime_i IS NOT NULL
             AND NOT (t.CRSArrTime_i BETWEEN 0 AND 2359 AND (t.CRSArrTime_i % 100) < 60)
            THEN 1 ELSE 0
        END AS w_arrtime_invalid
    FROM dbo.stg_flight_typed t
),
scored AS (
    SELECT
        r.*,
        CASE
            WHEN r.r_duplicate + r.r_flightdate_invalid + r.r_origin_invalid + r.r_dest_invalid
               + r.r_cancelled_invalid + r.r_diverted_invalid + r.r_distance_invalid + r.r_flights_invalid > 0
            THEN 1 ELSE 0
        END AS IsRejected,
        CASE
            WHEN r.w_elapsed_missing_on_normal + r.w_deptime_invalid + r.w_arrtime_invalid > 0
            THEN 1 ELSE 0
        END AS DQFlag,
        CONCAT(
            CASE WHEN r.r_duplicate = 1 THEN ';Duplicate_not_N' ELSE '' END,
            CASE WHEN r.r_flightdate_invalid = 1 THEN ';FlightDate_invalid' ELSE '' END,
            CASE WHEN r.r_origin_invalid = 1 THEN ';Origin_invalid' ELSE '' END,
            CASE WHEN r.r_dest_invalid = 1 THEN ';Dest_invalid' ELSE '' END,
            CASE WHEN r.r_cancelled_invalid = 1 THEN ';Cancelled_not_0_1' ELSE '' END,
            CASE WHEN r.r_diverted_invalid = 1 THEN ';Diverted_not_0_1' ELSE '' END,
            CASE WHEN r.r_distance_invalid = 1 THEN ';Distance_invalid' ELSE '' END,
            CASE WHEN r.r_flights_invalid = 1 THEN ';Flights_invalid' ELSE '' END
        ) AS RejectReasonRaw,
        CONCAT(
            CASE WHEN r.w_elapsed_missing_on_normal = 1 THEN ';Elapsed_missing_normal_flight' ELSE '' END,
            CASE WHEN r.w_deptime_invalid = 1 THEN ';CRSDepTime_invalid' ELSE '' END,
            CASE WHEN r.w_arrtime_invalid = 1 THEN ';CRSArrTime_invalid' ELSE '' END
        ) AS WarningReasonRaw
    FROM rules r
),
finalized AS (
    SELECT
        s.*,
        CASE WHEN LEFT(s.RejectReasonRaw,1) = ';' THEN STUFF(s.RejectReasonRaw,1,1,'') ELSE s.RejectReasonRaw END AS RejectReason,
        CASE WHEN LEFT(s.WarningReasonRaw,1) = ';' THEN STUFF(s.WarningReasonRaw,1,1,'') ELSE s.WarningReasonRaw END AS WarningReason,
        CASE
            WHEN s.CRSElapsedTime_i IS NOT NULL AND s.CRSElapsedTime_i > 0 THEN s.CRSElapsedTime_i
            WHEN ISNULL(s.Cancelled_i,0) = 1 OR ISNULL(s.Diverted_i,0) = 1 THEN NULL
            WHEN s.CRSDepTime_i BETWEEN 0 AND 2359
             AND s.CRSArrTime_i BETWEEN 0 AND 2359
             AND (s.CRSDepTime_i % 100) < 60
             AND (s.CRSArrTime_i % 100) < 60
            THEN
                CASE
                    WHEN (((s.CRSArrTime_i / 100) * 60 + (s.CRSArrTime_i % 100))
                        - ((s.CRSDepTime_i / 100) * 60 + (s.CRSDepTime_i % 100))) < 0
                    THEN (((s.CRSArrTime_i / 100) * 60 + (s.CRSArrTime_i % 100))
                        - ((s.CRSDepTime_i / 100) * 60 + (s.CRSDepTime_i % 100)) + 1440)
                    ELSE (((s.CRSArrTime_i / 100) * 60 + (s.CRSArrTime_i % 100))
                        - ((s.CRSDepTime_i / 100) * 60 + (s.CRSDepTime_i % 100)))
                END
            ELSE NULL
        END AS CRSElapsedTime_final
    FROM scored s
)
SELECT
    *
INTO dbo.stg_flight_clean
FROM finalized
WHERE IsRejected = 0;

SELECT COUNT(*) AS reject_rows FROM dbo.stg_flight_reject;
SELECT COUNT(*) AS clean_rows FROM dbo.stg_flight_clean;

SELECT
    DQFlag,
    COUNT(*) AS rows_cnt
FROM dbo.stg_flight_clean
GROUP BY DQFlag
ORDER BY DQFlag;