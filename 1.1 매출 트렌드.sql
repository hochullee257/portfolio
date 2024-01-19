-- 0. 거래테이블(pd_de) 내, 연도구분(year)/거래월(ord_month)/거래일(de_dt)/브랜드(cco_pd_bra_nm1)/그룹사상품코드(cco_pd_c)/88코드(cco_pd_sell_c_v)/고객번호(cno)/영수증번호(rct_seq)/구매금액(buy_am)/구매수량(buy_ct) 가 있는 것으로 가정
-- 0. 거래일 기준, 2021.01.01~2022.12.31
-- 0. 집계는 브랜드 기준의 집계로 작성
-- 1. 매출트렌드 및 포지셔닝맵
-- 1) MAT 매출 트렌드(13개월)
-- 전체
SELECT 'TTL' AS cco_pd_bra_nm1
	, SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_am END) AS MAT_202112
	, SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_am END) AS MAT_202201
	, SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_am END) AS MAT_202202
	, SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_am END) AS MAT_202203
	, SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_am END) AS MAT_202204
	, SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_am END) AS MAT_202205
	, SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_am END) AS MAT_202206
	, SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_am END) AS MAT_202207
	, SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_am END) AS MAT_202208
	, SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_am END) AS MAT_202209
	, SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_am END) AS MAT_202210
	, SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_am END) AS MAT_202211
	, SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_am END) AS MAT_202212	
FROM pd_de
WHERE ord_month BETWEEN '' AND ''  -- 날짜 수정
UNION ALL
-- 브랜드별
SELECT cco_pd_bra_nm1
	, SUM(CASE WHEN ord_month BETWEEN '202101' AND '202112' THEN buy_am END) AS MAT_202112
	, SUM(CASE WHEN ord_month BETWEEN '202102' AND '202201' THEN buy_am END) AS MAT_202201
	, SUM(CASE WHEN ord_month BETWEEN '202103' AND '202202' THEN buy_am END) AS MAT_202202
	, SUM(CASE WHEN ord_month BETWEEN '202104' AND '202203' THEN buy_am END) AS MAT_202203
	, SUM(CASE WHEN ord_month BETWEEN '202105' AND '202204' THEN buy_am END) AS MAT_202204
	, SUM(CASE WHEN ord_month BETWEEN '202106' AND '202205' THEN buy_am END) AS MAT_202205
	, SUM(CASE WHEN ord_month BETWEEN '202107' AND '202206' THEN buy_am END) AS MAT_202206
	, SUM(CASE WHEN ord_month BETWEEN '202108' AND '202207' THEN buy_am END) AS MAT_202207
	, SUM(CASE WHEN ord_month BETWEEN '202109' AND '202208' THEN buy_am END) AS MAT_202208
	, SUM(CASE WHEN ord_month BETWEEN '202110' AND '202209' THEN buy_am END) AS MAT_202209
	, SUM(CASE WHEN ord_month BETWEEN '202111' AND '202210' THEN buy_am END) AS MAT_202210
	, SUM(CASE WHEN ord_month BETWEEN '202112' AND '202211' THEN buy_am END) AS MAT_202211
	, SUM(CASE WHEN ord_month BETWEEN '202201' AND '202212' THEN buy_am END) AS MAT_202212	
FROM pd_de
WHERE ord_month BETWEEN '' AND ''  -- 날짜 수정
GROUP BY cco_pd_bra_nm1
2-1) 포지셔닝맵(상관계수/트렌드 제외)
CREATE TABLE pos AS
WITH total AS (
		SELECT 'TTL' AS cco_pd_bra_nm1     -- 전체 카테고리값 구해야해서
				, 'join_key' AS join_key
		    , SUM(CASE WHEN year = '2021' THEN buy_am END) AS amt_21
		    , COUNT(DISTINCT(CASE WHEN year = '2021' THEN cno END)) AS cno_21
		    , SUM(CASE WHEN year = '2022' THEN buy_am END) AS amt_22
		    , COUNT(DISTINCT(CASE WHEN year = '2022' THEN cno END)) AS cno_22
		    , ((SUM(CASE WHEN year = '2022' THEN buy_am END) / SUM(CASE WHEN year = '2021' THEN buy_am END)) -1)  AS growth_rate
		    , COUNT(DISTINCT(ord_MONTH)) AS buy_month_cnt
		FROM pd_de
		WHERE year IN ('2021','2022')     -- 날짜 수정
		)
		, brand AS (
		SELECT
		    cco_pd_bra_nm1
		    , 'join_key' AS join_key
		    , SUM(CASE WHEN year = '2021' THEN buy_am END) AS amt_21
		    , COUNT(DISTINCT(CASE WHEN year = '2021' THEN itg_user_id END)) AS cno_21
		    , SUM(CASE WHEN year = '2022' THEN buy_am END) AS amt_22
		    , COUNT(DISTINCT(CASE WHEN year = '2022' THEN itg_user_id END)) AS cno_22
		    , ((SUM(CASE WHEN year = '2022' THEN buy_am END) / SUM(CASE WHEN year = '2021' THEN buy_am END)) -1)  AS growth_rate
		    , COUNT(DISTINCT(ord_month)) AS buy_month_cnt
		FROM pd_de
		WHERE year IN ('2021','2022')   -- 날짜 수정
		GROUP BY cco_pd_bra_nm1
		)
		, uni AS (
		SELECT * FROM total
		UNION ALL
		SELECT * FROM brand
		)
SELECT t1.cco_pd_bra_nm1
		, t1.amt_21
		, t1.amt_21 / t2.amt_21 AS share_21
		, t1.cno_21
		, t1.cno_21 / t2.cno_21 AS penet_21
		, t1.amt_22
		, t1.amt_22 / t2.amt_22 AS share_22
		, t1.cno_22
		, t1.cno_22 / t2.cno_22 AS penet_22
		, t1.growth_rate
		, t1.buy_month_cnt		
FROM uni t1
LEFT JOIN total t2
ON t1.join_key = t2.join_key		

2-2) 포지셔닝맵(상관계수/트렌드) -- MAT 기준
-- 브랜드별 모든 월에 대해 값 생성(null인 경우 0으로 처리)
CREATE TABLE brand_month_summary AS
WITH month_raw AS (
	SELECT 'join_key' AS join_key
		, ord_month
		, ROW_NUMBER() OVER(ORDER BY ord_month) AS month_row    --나중에 LINEST 구할 때 사용 예정
	FROM pd_de
	GROUP BY ord_month)
-- 24개월마다 brand 붙이기 위함
	, brand_raw AS (
	SELECT 'join_key' AS join_key
		, cco_pd_bra_nm1
	FROM pd_de
	GROUP BY cco_pd_bra_nm1
	UNION ALL
	SELECT 'join_key' AS join_key
		, 'TTL' AS cco_pd_bra_nm1
	FROM pd_de)
-- 월별 실적 생성
	, summary AS (
	SELECT ord_month
		, cco_pd_bra_nm1
		, SUM(buy_am) AS buy_am
	FROM pd_de
	GROUP BY ord_month
		, cco_pd_bra_nm1
	UNION ALL
	SELECT ord_month	
		, 'TTL' AS cco_pd_bra_nm1
		, SUM(buy_am) AS buy_am
	FROM pd_de
	GROUP BY ord_month)
SELECT t1.ord_month
	, t1.month_row
	, t2.cco_pd_bra_nm1
	, COALESCE(t3.buy_am, 0) AS buy_am
FROM month_raw t1
LEFT JOIN brand_raw t2
ON t1.join_key = t2.join_key
LEFT JOIN summary t3
ON t1.ord_month = t3.ord_month AND t2.cco_pd_bra_nm1 = t3.cco_pd_bra_nm1

-- 12개월씩의 MAT 매출액 구하고, 표준화하기
CREATE TABLE brand_month_summary_std AS 
WITH cum_sum AS (
	SELECT ord_month
		, cco_pd_bra_nm1
		, month_row
		, SUM(buy_am) OVER (PARTITION BY cco_pd_bra_nm1
											 	ORDER BY cco_pd_bra_nm1, ord_month
											 	ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS mat_buy_am
  FROM brand_month_summary)
  , cum_sum_12 AS (
  SELECT *
  FROM cum_sum
  WHERE month_row BETWEEN '12' AND '24'  -- 최근 13개월에 대한 MAT만 발생하니까
  )
SELECT ord_month
	, cco_pd_bra_nm1
	, month_row
	, mat_buy_am
	, (mat_buy_am - AVG(mat_buy_am) OVER (PARTITION BY cco_pd_bra_nm1)) / STDDEV_SAMP(mat_buy_am) OVER (PARTITION BY cco_pd_bra_nm1) AS std_buy_am
FROM cum_sum_12
-----------------------------------------------
-- 표준화된 std_buy_am을 통해 TREND 계수 구하기
-----------------------------------------------
CREATE TABLE trend AS 
SELECT cco_pd_bra_nm1
	, (COUNT(*) * SUM(month_row * std_buy_am) - SUM(month_row)*SUM(std_buy_am)) / COUNT(*) * SUM(month_row*month_row) - SUM(month_row)*sum(month_row) AS trend
FROM brand_month_summary_std
GROUP BY cco_pd_bra_nm1
-----------------------------------------------
-- 표준화된 std_buy_am을 통해 correlation 계수 구하기
-----------------------------------------------
CREATE TABLE corr AS 
WITH total AS (
	SELECT ord_month
		, cco_pd_bra_nm1
		, std_buy_am
	FROM brand_month_summary_std
	WHERE cco_pd_bra_nm1 = 'TTL'
	)
	, brand AS (
	SELECT w1.ord_month
		, w1.cco_pd_bra_nm1
		, w1.std_buy_am AS std_buy_am_brand
		, w2.std_buy_am AS std_buy_am_total
	FROM brand_month_summary_std w1
	LEFT JOIN total w2
	ON w1.ord_month = w2.ord_month 
	)
SELECT cco_pd_bra_nm1
	, CORR(std_buy_am_brand, std_buy_am_total) AS corr
FROM brand
GROUP BY cco_pd_bra_nm1
-------------------------------------------------------------
-- 2-3) 포지셔닝맵(최종테이블) -- MAT 기준
-------------------------------------------------------------
SELECT t1.*
	, t2.trend
	, t3.corr
FROM pos t1
LEFT JOIN trend t2 ON t1.cco_pd_bra_nm1=t2.cco_pd_bra_nm1
LEFT JOIN corr t3 ON t1.cco_pd_bra_nm1=t3.cco_pd_bra_nm1
