-- 1. 제조사 자체 기준 스위칭
switch_raw
WITH ctgr_buy_am AS (  -- 카테고리 매출
    SELECT cno
        , SUM(CASE WHEN year = '2021' THEN buy_am END) AS ctgr_buy_am_21     
        , SUM(CASE WHEN year = '2022' THEN buy_am END) AS ctgr_buy_am_22
        , SUM(CASE WHEN year = '2021' THEN buy_ct END) AS ctgr_buy_ct_21
        , SUM(CASE WHEN year = '2022' THEN buy_ct END) AS ctgr_buy_ct_22
    FROM pd_de
    GROUP BY cno
    )
    , brand_buy_am AS (    -- 브랜드 매출
    SELECT cco_pd_bra_nm1
        , cno
        , SUM(CASE WHEN year = '2021' THEN buy_am END) AS brand_buy_am_21
        , SUM(CASE WHEN year = '2022' THEN buy_am END) AS brand_buy_am_22
        , SUM(CASE WHEN year = '2021' THEN buy_ct END) AS brand_buy_ct_21
        , SUM(CASE WHEN year = '2022' THEN buy_ct END) AS brand_buy_ct_22
    FROM pd_de
    GROUP BY cco_pd_bra_nm1
        , cno
    )
    , switch_raw AS (  
    SELECT w1.cco_pd_bra_nm1
        , w1.cno
        , w1.brand_buy_am_21
        , w1.brand_buy_am_22
        , w2.ctgr_buy_am_21
        , w2.ctgr_buy_am_22
    FROM brand_buy_am w1
    LEFT JOIN ctgr_buy_am w2 ON w1.cno = w2.cno
    )
    , tag_raw AS (
    SELECT *,
    CASE WHEN brand_buy_am_21 > 0 AND brand_buy_am_22 > 0 THEN 'RETENTION'
    
    WHEN brand_buy_am_21 > 0 AND brand_buy_am_22 = 0 AND ctgr_buy_am_22 = 0 THEN 'CATE_OUT'
    WHEN brand_buy_am_21 = 0 AND brand_buy_am_22 > 0 AND ctgr_buy_am_21 = 0 THEN 'CATE_IN'

    WHEN brand_buy_am_21 > 0 AND brand_buy_am_22 = 0 AND ctgr_buy_am_22 > 0 THEN 'BRAND_LOSS'
    WHEN brand_buy_am_21 = 0 AND brand_buy_am_22 > 0 AND ctgr_buy_am_21 > 0 THEN 'BRAND_GAIN'
    ELSE '기타' END AS tag
    FROM switch_raw
    )
SELECT cco_pd_bra_nm1
    , tag
    , COUNT(DISTINCT(cno)) AS user_cnt
    , SUM(brand_buy_am_21) AS buy_am_21
    , SUM(brand_buy_am_22) AS buy_am_22
FROM tag_raw
GROUP BY cco_pd_bra_nm1
    , tag    


-- 2. 제조사 간
WITH retention AS (  -- 연도별 카테고리 매출 구하고
    SELECT cno
        , SUM(CASE WHEN year = '2021' THEN buy_am ELSE 0 END) AS cate_buy_am_21
        , SUM(CASE WHEN year = '2022' THEN buy_am ELSE 0 END) AS cate_buy_am_22
        , SUM(CASE WHEN year = '2021' THEN buy_ct ELSE 0 END) AS cate_buy_ct_21
        , SUM(CASE WHEN year = '2022' THEN buy_ct ELSE 0 END) AS cate_buy_ct_22
    FROM pd_de
    GROUP BY cno
    )
    , sw_cst_inf_1 AS (  -- 21, 22년 모두 카테고리 거래액이 있는 애들 대상 / 브랜드별 21, 22년 거래액 구함
    SELECT cno
        , cco_pd_bra_nm1
        , SUM(CASE WHEN year = '2021' THEN buy_am ELSE 0 END) AS buy_am_21
        , SUM(CASE WHEN year = '2022' THEN buy_am ELSE 0 END) AS buy_am_22
        , SUM(CASE WHEN year = '2021' THEN buy_ct ELSE 0 END) AS buy_ct_21
        , SUM(CASE WHEN year = '2022' THEN buy_ct ELSE 0 END) AS buy_ct_22
    FROM pd_de
    WHERE cno IN (SELECT cno FROM retention WHERE cate_buy_am_21 > 0 AND cate_buy_am_22 > 0)
    GROUP BY cno, cco_pd_bra_nm1
    )
    , sw_cst_inf_2 AS (  -- 고객별로 LEFT OUTER JOIN 해서, 전체 브랜드별 21, 22년 조합을 만들고
    SELECT w1.cno AS af_user_id
        , w2.cno AS bf_user_id
        , IFNULL(w1.cno, w2.cno) AS stnd_user_id
        , w1.cco_pd_bra_nm1 AS af_brand_nm
        , w2.cco_pd_bra_nm1 AS bf_brand_nm
        , w1.buy_am_21 AS a_buy_am_21
        , w2.buy_am_21 AS b_buy_am_21
        , w1.buy_am_22 AS a_buy_am_22
        , w2.buy_am_22 AS b_buy_am_22
        , w1.buy_ct_21 AS a_buy_ct_21
        , w2.buy_ct_21 AS b_buy_ct_21
        , w1.buy_ct_22 AS a_buy_ct_22
        , w2.buy_ct_22 AS b_buy_ct_22
    FROM sw_cst_inf_1 w1
    LEFT OUTER JOIN sw_cst_inf_1 w2
    ON t1.cno = t2.cno
    )
    , sw_cst_inf_3 AS ( -- 21, 22년의 거래액들을 비교해서 ONLY 고객 추출/ 동일 브랜드 내의 고객 구분 / 카테고리 IN,OUT 라벨 생성
    SELECT *
        ,(CASE WHEN a_buy_am_21 = 0 AND b_buy_am_21 > 0 AND a_buy_am_22 > 0 AND b_buy_am_22 = 0 THEN 'GAIN_ONLY'
            WHEN a_buy_am_21 > 0 AND b_buy_am_21 = 0 AND a_buy_am_22 = 0 AND b_buy_am_22 > 0 THEN 'LOSS_ONLY'

            WHEN af_brand_nm = bf_brand_nm AND a_buy_am_21 = 0 AND a_buy_am_22 > 0 THEN 'ELSE'
            WHEN af_brand_nm = bf_brand_nm AND a_buy_am_21 > 0 AND a_buy_am_22 = 0 THEN 'ELSE'
            WHEN af_brand_nm = bf_brand_nm AND a_buy_am_21 > 0 AND a_buy_am_22 > 0 THEN 'RETENTION'

            WHEN a_buy_am_21 = 0 AND b_buy_am_21 = 0 AND a_buy_am_22 > 0 THEN 'OUT'
            WHEN a_buy_am_22 = 0 AND b_buy_am_22 = 0 AND a_buy_am_21 > 0 THEN 'IN'
            
            END) AS a_gb
    FROM sw_cst_inf_2
    )
    , sw_cst_inf_4 AS (  -- 위의 라벨링에서 제외된 21년/22년 브랜드가 다르고 21년, 22년 모두 거래액이 있는 애들에 대해서 어떤 브랜드를 더 많이 샀는지에 대한 라벨링을 함(A는 a브랜드가 큰/R은 동일한/B는 b브랜드가 큰)
    SELECT *
        , CASE WHEN a_buy_ct_21 > b_buy_ct_21 THEN 'A'
            WHEN a_buy_ct_21 = b_buy_ct_21 THEN 'R'
            WHEN a_buy_ct_21 < b_buy_ct_21 THEN 'B'
        END AS y21_gb
        , CASE WHEN a_buy_ct_22 > b_buy_ct_22 THEN 'A'
            WHEN a_buy_ct_22 = b_buy_ct_22 THEN 'R'
            WHEN a_buy_ct_22 < b_buy_ct_22 THEN 'B'
        END AS y22_gb
    FROM sw_cst_inf_3
    WHERE a_gb IS NULL
    )
    , sw_cst_inf_5 AS (  -- 21, 22년의 라벨을 고려하여 CROSS 스위칭 계산
    SELECT *
        , (CASE WHEN y21_gb = 'A' AND y22_gb = 'B' THEN 'LOSS_CROSS'
                WHEN y21_gb = 'R' AND y22_gb = 'B' THEN 'LOSS_CROSS'
                WHEN y21_gb = 'A' AND y22_gb = 'R' THEN 'LOSS_CROSS'

                WHEN y21_gb = 'B' AND y22_gb = 'A' THEN 'GAIN_CROSS'
                WHEN y21_gb = 'R' AND y22_gb = 'A' THEN 'GAIN_CROSS'
                WHEN y21_gb = 'B' AND y22_gb = 'R' THEN 'GAIN_CROSS'

                WHEN y21_gb = 'R' AND y22_gb = 'R' THEN 'SAME'

                WHEN y21_gb = 'A' AND y22_gb = 'A' THEN 'A_DOM'
                WHEN y21_gb = 'B' AND y22_gb = 'B' THEN 'B_DOM'
        END ) AS gb
    FROM sw_cst_inf_4
    )
SELECT af_brand_nm
    , bf_brand_nm
    , a_gb
    , COUNT(DISTINCT(stnd_user_id)) AS cnt_user
FROM sw_cst_inf_3
WHERE A_GB IN ('GAIN_ONLY','LOSS_ONLY')
GROUP BY af_brand_nm
    , bf_brand_nm
    , a_gb
UNION ALL
SELECT af_brand_nm
    , bf_brand_nm
    , gb AS a_gb
    , COUNT(DISTINCT(stnd_user_id)) AS cnt_user
FROM sw_cst_inf_5
WHERE gb IN ('GAIN_CROSS','LOSS_CROSS')
GROUP BY af_brand_nm
    , bf_brand_nm
    , gb