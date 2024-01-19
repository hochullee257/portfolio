-- 0. 거래테이블(pd_de) 내, 연도구분(year)/거래월(ord_month)/거래주차(ord_week)/거래일(de_dt)/브랜드(cco_pd_bra_nm1)/그룹사상품코드(cco_pd_c)/88코드(cco_pd_sell_c_v)/고객번호(cno)/영수증번호(rct_seq)/구매금액(buy_am)/구매수량(buy_ct) 가 있는 것으로 가정
-- 0. 거래일 기준, 2021.01.01~2022.12.31
-- 0. 집계는 sku 기준의 집계로 작성
-- #############################################################
-- 0. 주차별 트렌드의 경우, 16주/24주 등 기간에 맞춰 변경 필요해 보이며, ord_month 대신 ord_week 사용
-- 0. SUM(CASE WHEN ord_week BETWEEN '' AND '' ) 대신
--  -> SUM(buy_am) OVER (PARTITION BY cco_pd_sell_c_v
--											 	ORDER BY cco_pd_sell_c_v, ord_month
--											 	ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) 
--          / SUM(buy_ct) OVER (PARTITION BY cco_pd_sell_c_v
--											 	ORDER BY cco_pd_sell_c_v, ord_month
--											 	ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)                                       
--                                                AS mat_avg_price
-- 을 기준으로 PRECEDING 값을 조정하는게 더 간편할 수 있어보임

-- #############################################################
-- 4.1. 가격-트렌드 분석
-- 1-1) MAT 월 가격/구매수량 트렌드(13개월)
--##### 대상 상품 제한은 사전에 필요(ex, 모든 월에 팔린 상품 or null값은 전월과 다음월의 평균으로 계산 등의 처리 필요)
SELECT 'TTL' AS gb
-- 평균 가격
        , SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_ct END) AS MAT_202112
        , SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_ct END) AS MAT_202201
        , SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_ct END) AS MAT_202202
        , SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_ct END) AS MAT_202203
        , SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_ct END) AS MAT_202204
        , SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_ct END) AS MAT_202205
        , SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_ct END) AS MAT_202206
        , SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_ct END) AS MAT_202207
        , SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_ct END) AS MAT_202208
        , SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_ct END) AS MAT_202209
        , SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_ct END) AS MAT_202210
        , SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_ct END) AS MAT_202211
        , SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_ct END) AS MAT_202212
-- 누적 구매 수량
        , SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_ct END) AS MQT_202112
        , SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_ct END) AS MQT_202201
        , SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_ct END) AS MQT_202202
        , SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_ct END) AS MQT_202203
        , SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_ct END) AS MQT_202204
        , SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_ct END) AS MQT_202205
        , SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_ct END) AS MQT_202206
        , SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_ct END) AS MQT_202207
        , SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_ct END) AS MQT_202208
        , SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_ct END) AS MQT_202209
        , SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_ct END) AS MQT_202210
        , SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_ct END) AS MQT_202211
        , SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_ct END) AS MQT_202212
FROM pd_de
WHERE ord_month BETWEEN '' AND '' --날짜 수정
UNION ALL
SELECT cco_pd_sell_c_v AS gb      -- 상품코드별
-- 평균 가격
        , SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_ct END) AS MAT_202112
        , SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_ct END) AS MAT_202201
        , SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_ct END) AS MAT_202202
        , SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_ct END) AS MAT_202203
        , SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_ct END) AS MAT_202204
        , SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_ct END) AS MAT_202205
        , SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_ct END) AS MAT_202206
        , SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_ct END) AS MAT_202207
        , SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_ct END) AS MAT_202208
        , SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_ct END) AS MAT_202209
        , SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_ct END) AS MAT_202210
        , SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_ct END) AS MAT_202211
        , SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_am END) / SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_ct END) AS MAT_202212
-- 누적 구매 수량
        , SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_ct END) AS MQT_202112
        , SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_ct END) AS MQT_202201
        , SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_ct END) AS MQT_202202
        , SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_ct END) AS MQT_202203
        , SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_ct END) AS MQT_202204
        , SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_ct END) AS MQT_202205
        , SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_ct END) AS MQT_202206
        , SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_ct END) AS MQT_202207
        , SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_ct END) AS MQT_202208
        , SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_ct END) AS MQT_202209
        , SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_ct END) AS MQT_202210
        , SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_ct END) AS MQT_202211
        , SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_ct END) AS MQT_202212
FROM pd_de
WHERE ord_month BETWEEN '' AND '' --날짜 수정
GROUP BY cco_pd_sell_c_v

-- 1-2) 월 가격/구매수량 트렌드(13개월)
SELECT ord_month
    , 'TTL' AS gb  
    , SUM(buy_am) AS am_sum
    , SUM(buy_ct) AS ct_sum
    , SUM(buy_am) / SUM(buy_ct) AS avg_price
FROM pd_de
WHERE ord_month BETWEEN '' AND '' -- 날짜 수정
UNION ALL
SELECT ord_month
    , cco_pd_sell_c_v AS gb  
    , SUM(buy_am) AS am_sum
    , SUM(buy_ct) AS ct_sum
    , SUM(buy_am) / SUM(buy_ct) AS avg_price
FROM pd_de
WHERE ord_month BETWEEN '' AND '' -- 날짜 수정

-- 2-1) Price 포지셔닝맵(상관계수/트렌드) -- MAT 기준
-- 브랜드별 모든 월에 대해 값 생성(null인 경우 0으로 처리)
CREATE TABLE sku_month_summary AS
WITH month_raw AS (
	SELECT 'join_key' AS join_key
		, ord_month
		, ROW_NUMBER() OVER(ORDER BY ord_month) AS month_row    --나중에 LINEST 구할 때 사용 예정
	FROM pd_de
	GROUP BY ord_month)
-- 24개월마다 sku 붙이기 위함
	, sku_raw AS (
	SELECT 'join_key' AS join_key
		, cco_pd_sell_c_v
	FROM pd_de
	GROUP BY cco_pd_sell_c_v
	UNION ALL
	SELECT 'join_key' AS join_key
		, 'TTL' AS cco_pd_sell_c_v
	FROM pd_de)
-- 월별 실적 생성
	, summary AS (
	SELECT ord_month
		, cco_pd_sell_c_v
		, SUM(buy_am) / sum(buy_ct) AS avg_price
	FROM pd_de
	GROUP BY ord_month
		, cco_pd_sell_c_v
	UNION ALL
	SELECT ord_month	
		, 'TTL' AS cco_pd_sell_c_v
		, SUM(buy_am) / sum(buy_ct) AS avg_price
	FROM pd_de
	GROUP BY ord_month)
SELECT t1.ord_month
	, t1.month_row
	, t2.cco_pd_sell_c_v
	, COALESCE(avg_price, 0) AS avg_price
FROM month_raw t1
LEFT JOIN sku_raw t2
ON t1.join_key = t2.join_key
LEFT JOIN summary t3
ON t1.ord_month = t3.ord_month AND t2.cco_pd_sell_c_v = t3.cco_pd_sell_c_v

-- 12개월씩의 MAT 매출액 구하고, 표준화하기
CREATE TABLE sku_month_summary_std AS 
WITH cum_sum AS (
	SELECT ord_month
		, cco_pd_sell_c_v
		, month_row
		, SUM(buy_am) OVER (PARTITION BY cco_pd_sell_c_v
											 	ORDER BY cco_pd_sell_c_v, ord_month
											 	ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) 
          / SUM(buy_ct) OVER (PARTITION BY cco_pd_sell_c_v
											 	ORDER BY cco_pd_sell_c_v, ord_month
											 	ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)                                       
                                                AS mat_avg_price
  FROM sku_month_summary)
  , cum_sum_12 AS (
  SELECT *
  FROM cum_sum
  WHERE month_row BETWEEN '12' AND '24'  -- 최근 13개월에 대한 MAT만 발생하니까
  )
SELECT ord_month
	, cco_pd_sell_c_v
	, month_row
	, mat_avg_price
	, (mat_avg_price - AVG(mat_avg_price) OVER (PARTITION BY cco_pd_sell_c_v)) / STDDEV_SAMP(mat_avg_price) OVER (PARTITION BY cco_pd_sell_c_v) AS std_avg_price
FROM cum_sum_12
-----------------------------------------------
-- 표준화된 std_avg_price 통해 TREND 계수 구하기
-----------------------------------------------
CREATE TABLE trend AS 
SELECT cco_pd_sell_c_v
	, (COUNT(*) * SUM(month_row * std_avg_price) - SUM(month_row)*SUM(std_avg_price)) / COUNT(*) * SUM(month_row*month_row) - SUM(month_row)*sum(month_row) AS trend
FROM sku_month_summary_std
GROUP BY cco_pd_sell_c_v
-----------------------------------------------
-- 표준화된 std_avg_price 통해 correlation 계수 구하기
-----------------------------------------------
CREATE TABLE corr AS 
WITH total AS (
	SELECT ord_month
		, cco_pd_sell_c_v
		, std_avg_price
	FROM sku_month_summary_std
	WHERE cco_pd_sell_c_v = 'TTL'
	)
	, sku AS (
	SELECT w1.ord_month
		, w1.cco_pd_sell_c_v
		, w1.std_avg_price AS std_avg_price_sku
		, w2.std_avg_price AS std_avg_price_total
	FROM sku_month_summary_std w1
	LEFT JOIN total w2
	ON w1.ord_month = w2.ord_month 
	)
SELECT cco_pd_sell_c_v
	, CORR(std_avg_price_sku, std_avg_price_total) AS corr
FROM sku
GROUP BY cco_pd_sell_c_v
