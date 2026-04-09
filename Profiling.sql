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

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), OriginAirportID))), '')) AS OriginAirportID_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), OriginAirportSeqID))), '')) AS OriginAirportSeqID_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), OriginCityMarketID))), '')) AS OriginCityMarketID_i,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), OriginCityName))), '') AS OriginCityName_c,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(10), OriginState))), '') AS OriginState_c,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), OriginStateFips))), '')) AS OriginStateFips_i,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), OriginStateName))), '') AS OriginStateName_c,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), OriginWac))), '')) AS OriginWac_i,

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DestAirportID))), '')) AS DestAirportID_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DestAirportSeqID))), '')) AS DestAirportSeqID_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DestCityMarketID))), '')) AS DestCityMarketID_i,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), DestCityName))), '') AS DestCityName_c,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(10), DestState))), '') AS DestState_c,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DestStateFips))), '')) AS DestStateFips_i,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), DestStateName))), '') AS DestStateName_c,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DestWac))), '')) AS DestWac_i,

    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(200), Marketing_Airline_Network))), '') AS Marketing_Airline_Network_c,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DOT_ID_Marketing_Airline))), '')) AS DOT_ID_Marketing_Airline_i,
    UPPER(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(10), IATA_Code_Marketing_Airline))), '')) AS IATA_Code_Marketing_Airline_c,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Flight_Number_Marketing_Airline))), '') AS Flight_Number_Marketing_Airline_c,

    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(200), Operating_Airline))), '') AS Operating_Airline_c,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DOT_ID_Operating_Airline))), '')) AS DOT_ID_Operating_Airline_i,
    UPPER(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(10), IATA_Code_Operating_Airline))), '')) AS IATA_Code_Operating_Airline_c,
    NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Flight_Number_Operating_Airline))), '') AS Flight_Number_Operating_Airline_c,

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Cancelled))), '')) AS Cancelled_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Diverted))), '')) AS Diverted_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), CRSElapsedTime))), '')) AS CRSElapsedTime_i,

    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), CRSDepTime))), '')) AS CRSDepTime_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), CRSArrTime))), '')) AS CRSArrTime_i,

    TRY_CONVERT(decimal(18,2), NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(30), Distance))), '')) AS Distance_n,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), Flights))), '')) AS Flights_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DistanceGroup))), '')) AS DistanceGroup_i,
    TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(20), DivAirportLandings))), '')) AS DivAirportLandings_i,

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


/* 6) TAO CLEAN TABLE DON GIAN DE NAP DW */
DROP TABLE IF EXISTS dbo.stg_flight_reject;
DROP TABLE IF EXISTS dbo.stg_flight_clean;

SELECT
    t.*,
    CASE
        WHEN t.CRSElapsedTime_i IS NOT NULL AND t.CRSElapsedTime_i > 0 THEN t.CRSElapsedTime_i
        WHEN ISNULL(t.Cancelled_i,0) = 1 OR ISNULL(t.Diverted_i,0) = 1 THEN NULL
        WHEN t.CRSDepTime_i BETWEEN 0 AND 2359
         AND t.CRSArrTime_i BETWEEN 0 AND 2359
         AND (t.CRSDepTime_i % 100) < 60
         AND (t.CRSArrTime_i % 100) < 60
        THEN
            CASE
                WHEN (((t.CRSArrTime_i / 100) * 60 + (t.CRSArrTime_i % 100))
                    - ((t.CRSDepTime_i / 100) * 60 + (t.CRSDepTime_i % 100))) < 0
                THEN (((t.CRSArrTime_i / 100) * 60 + (t.CRSArrTime_i % 100))
                    - ((t.CRSDepTime_i / 100) * 60 + (t.CRSDepTime_i % 100)) + 1440)
                ELSE (((t.CRSArrTime_i / 100) * 60 + (t.CRSArrTime_i % 100))
                    - ((t.CRSDepTime_i / 100) * 60 + (t.CRSDepTime_i % 100)))
            END
        ELSE NULL
    END AS CRSElapsedTime_final
INTO dbo.stg_flight_clean
FROM dbo.stg_flight_typed t;

SELECT COUNT(*) AS clean_rows FROM dbo.stg_flight_clean;


/* 7) TAO DIM_DATE */
DROP TABLE IF EXISTS dbo.Dim_Date;

CREATE TABLE dbo.Dim_Date (
    DateKey int IDENTITY(1,1) PRIMARY KEY,
    FlightDate date NOT NULL,
    [Year] int NULL,
    [Quarter] int NULL,
    [Month] int NULL,
    DayOfMonth int NULL,
    DayOfWeek int NULL,
    CONSTRAINT UQ_Dim_Date_FlightDate UNIQUE (FlightDate)
);

INSERT INTO dbo.Dim_Date (FlightDate, [Year], [Quarter], [Month], DayOfMonth, DayOfWeek)
SELECT
    c.FlightDate_d,
    MAX(c.Year_i) AS [Year],
    MAX(c.Quarter_i) AS [Quarter],
    MAX(c.Month_i) AS [Month],
    MAX(c.DayOfMonth_i) AS DayOfMonth,
    MAX(c.DayOfWeek_i) AS DayOfWeek
FROM dbo.stg_flight_clean c
WHERE c.FlightDate_d IS NOT NULL
GROUP BY c.FlightDate_d;


/* 8) TAO DIM_AIRLINE (DUNG CHUNG CHO MARKETING VA OPERATING) */
DROP TABLE IF EXISTS dbo.Dim_Airline;

CREATE TABLE dbo.Dim_Airline (
    AirlineKey int IDENTITY(1,1) PRIMARY KEY,
    DOT_ID int NULL,
    IATA_Code nvarchar(10) NULL,
    AirlineName nvarchar(200) NULL
);

INSERT INTO dbo.Dim_Airline (DOT_ID, IATA_Code, AirlineName)
SELECT DISTINCT
    x.DOT_ID,
    x.IATA_Code,
    x.AirlineName
FROM (
    SELECT
        c.DOT_ID_Marketing_Airline_i AS DOT_ID,
        c.IATA_Code_Marketing_Airline_c AS IATA_Code,
        c.Marketing_Airline_Network_c AS AirlineName
    FROM dbo.stg_flight_clean c
    UNION
    SELECT
        c.DOT_ID_Operating_Airline_i AS DOT_ID,
        c.IATA_Code_Operating_Airline_c AS IATA_Code,
        c.Operating_Airline_c AS AirlineName
    FROM dbo.stg_flight_clean c
) x
WHERE x.DOT_ID IS NOT NULL OR x.IATA_Code IS NOT NULL OR x.AirlineName IS NOT NULL;

CREATE INDEX IX_Dim_Airline_DOT_IATA
ON dbo.Dim_Airline (DOT_ID, IATA_Code);


/* 9) TAO DIM_AIRPORT (DUNG CHUNG CHO ORIGIN VA DEST) */
DROP TABLE IF EXISTS dbo.Dim_Airport;

CREATE TABLE dbo.Dim_Airport (
    AirportKey int IDENTITY(1,1) PRIMARY KEY,
    AirportCode nvarchar(20) NULL,
    AirportID int NULL,
    AirportSeqID int NULL,
    CityMarketID int NULL,
    CityName nvarchar(100) NULL,
    StateCode nvarchar(10) NULL,
    StateFips int NULL,
    StateName nvarchar(100) NULL,
    Wac int NULL
);

INSERT INTO dbo.Dim_Airport (
    AirportCode,
    AirportID,
    AirportSeqID,
    CityMarketID,
    CityName,
    StateCode,
    StateFips,
    StateName,
    Wac
)
SELECT DISTINCT
    x.AirportCode,
    x.AirportID,
    x.AirportSeqID,
    x.CityMarketID,
    x.CityName,
    x.StateCode,
    x.StateFips,
    x.StateName,
    x.Wac
FROM (
    SELECT
        c.Origin_c AS AirportCode,
        c.OriginAirportID_i AS AirportID,
        c.OriginAirportSeqID_i AS AirportSeqID,
        c.OriginCityMarketID_i AS CityMarketID,
        c.OriginCityName_c AS CityName,
        c.OriginState_c AS StateCode,
        c.OriginStateFips_i AS StateFips,
        c.OriginStateName_c AS StateName,
        c.OriginWac_i AS Wac
    FROM dbo.stg_flight_clean c
    UNION
    SELECT
        c.Dest_c AS AirportCode,
        c.DestAirportID_i AS AirportID,
        c.DestAirportSeqID_i AS AirportSeqID,
        c.DestCityMarketID_i AS CityMarketID,
        c.DestCityName_c AS CityName,
        c.DestState_c AS StateCode,
        c.DestStateFips_i AS StateFips,
        c.DestStateName_c AS StateName,
        c.DestWac_i AS Wac
    FROM dbo.stg_flight_clean c
) x
WHERE x.AirportCode IS NOT NULL;

CREATE INDEX IX_Dim_Airport_Code_Id
ON dbo.Dim_Airport (AirportCode, AirportID);


/* 10) TAO FACT_FLIGHT */
DROP TABLE IF EXISTS dbo.Fact_Flight;

CREATE TABLE dbo.Fact_Flight (
    FactFlightKey bigint IDENTITY(1,1) PRIMARY KEY,
    DateKey int NOT NULL,
    MarketingAirlineKey int NULL,
    OperatingAirlineKey int NULL,
    OriginAirportKey int NULL,
    DestAirportKey int NULL,
    Flights int NULL,
    Distance decimal(18,2) NULL,
    CRSElapsedTime int NULL,
    DistanceGroup int NULL,
    DivAirportLandings int NULL,
    Cancelled bit NULL,
    Diverted bit NULL,
    FlightNumberMarketing nvarchar(20) NULL,
    FlightNumberOperating nvarchar(20) NULL
);

INSERT INTO dbo.Fact_Flight (
    DateKey,
    MarketingAirlineKey,
    OperatingAirlineKey,
    OriginAirportKey,
    DestAirportKey,
    Flights,
    Distance,
    CRSElapsedTime,
    DistanceGroup,
    DivAirportLandings,
    Cancelled,
    Diverted,
    FlightNumberMarketing,
    FlightNumberOperating
)
SELECT
    d.DateKey,
    ma.AirlineKey AS MarketingAirlineKey,
    oa.AirlineKey AS OperatingAirlineKey,
    ao.AirportKey AS OriginAirportKey,
    ad.AirportKey AS DestAirportKey,
    c.Flights_i AS Flights,
    c.Distance_n AS Distance,
    c.CRSElapsedTime_final AS CRSElapsedTime,
    c.DistanceGroup_i AS DistanceGroup,
    c.DivAirportLandings_i AS DivAirportLandings,
    TRY_CONVERT(bit, c.Cancelled_i) AS Cancelled,
    TRY_CONVERT(bit, c.Diverted_i) AS Diverted,
    c.Flight_Number_Marketing_Airline_c AS FlightNumberMarketing,
    c.Flight_Number_Operating_Airline_c AS FlightNumberOperating
FROM dbo.stg_flight_clean c
INNER JOIN dbo.Dim_Date d
    ON d.FlightDate = c.FlightDate_d
LEFT JOIN dbo.Dim_Airline ma
    ON ma.DOT_ID = c.DOT_ID_Marketing_Airline_i
   AND ISNULL(ma.IATA_Code, '') = ISNULL(c.IATA_Code_Marketing_Airline_c, '')
LEFT JOIN dbo.Dim_Airline oa
    ON oa.DOT_ID = c.DOT_ID_Operating_Airline_i
   AND ISNULL(oa.IATA_Code, '') = ISNULL(c.IATA_Code_Operating_Airline_c, '')
LEFT JOIN dbo.Dim_Airport ao
    ON ao.AirportCode = c.Origin_c
   AND ISNULL(ao.AirportID, -1) = ISNULL(c.OriginAirportID_i, -1)
LEFT JOIN dbo.Dim_Airport ad
    ON ad.AirportCode = c.Dest_c
   AND ISNULL(ad.AirportID, -1) = ISNULL(c.DestAirportID_i, -1);

CREATE INDEX IX_Fact_Flight_Date ON dbo.Fact_Flight (DateKey);
CREATE INDEX IX_Fact_Flight_Route ON dbo.Fact_Flight (OriginAirportKey, DestAirportKey);
CREATE INDEX IX_Fact_Flight_Airline ON dbo.Fact_Flight (MarketingAirlineKey, OperatingAirlineKey);


/* 11) DOI SOAT KET QUA NAP DW */
SELECT COUNT(*) AS clean_rows FROM dbo.stg_flight_clean;
SELECT COUNT(*) AS fact_rows FROM dbo.Fact_Flight;

SELECT
    (SELECT SUM(CAST(ISNULL(c.Flights_i, 0) AS bigint)) FROM dbo.stg_flight_clean c) AS clean_total_flights,
    (SELECT SUM(CAST(ISNULL(f.Flights, 0) AS bigint)) FROM dbo.Fact_Flight f) AS fact_total_flights;

SELECT
    CAST(100.0 * SUM(CASE WHEN c.Cancelled_i = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(9,4)) AS clean_cancelled_pct,
    CAST(100.0 * SUM(CASE WHEN c.Diverted_i = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(9,4)) AS clean_diverted_pct
FROM dbo.stg_flight_clean c;

SELECT
    CAST(100.0 * SUM(CASE WHEN f.Cancelled = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(9,4)) AS fact_cancelled_pct,
    CAST(100.0 * SUM(CASE WHEN f.Diverted = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(9,4)) AS fact_diverted_pct
FROM dbo.Fact_Flight f;

SELECT
    SUM(CAST(CASE WHEN f.MarketingAirlineKey IS NULL THEN 1 ELSE 0 END AS bigint)) AS fact_missing_marketing_airline_key,
    SUM(CAST(CASE WHEN f.OperatingAirlineKey IS NULL THEN 1 ELSE 0 END AS bigint)) AS fact_missing_operating_airline_key,
    SUM(CAST(CASE WHEN f.OriginAirportKey IS NULL THEN 1 ELSE 0 END AS bigint)) AS fact_missing_origin_airport_key,
    SUM(CAST(CASE WHEN f.DestAirportKey IS NULL THEN 1 ELSE 0 END AS bigint)) AS fact_missing_dest_airport_key
FROM dbo.Fact_Flight f;


