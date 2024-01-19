-- ###############################################################
-- ##########################고객 기준#############################
-- ###############################################################
-- 1. 비교군 미설정
-- 관심 카테고리 : 가공식품
-- vs 다른 카테고리
-- 전체 고객의 구매고객 정보
WITH all_cno_info AS
    (SELECT cno
        , SUM(buy_ct) AS buy_ct
    FROM default.pd_de
    GROUP BY cno    
        )
-- 관심카테고리 구매고객 정보
    , inter_cate_info AS 
    (SELECT cno
        , cco_pd_hlv_c_nm                   -- 관심카테고리 tag
        , SUM(buy_ct) AS inter_cate_buy_ct  -- 관심카테고리 구매량
    FROM default.pd_de
    WHERE cco_pd_hlv_c_nm = '가공식품'       -- 관심카테고리 설정
    GROUP BY cno
        , cco_pd_hlv_c_nm    
        )
-- 연관카테고리 구매고객 정보
    , relate_cate_info AS
    (SELECT cno
        , cco_pd_hlv_c_nm                   -- 연관카테고리 tag
        , SUM(buy_ct) AS relate_cate_buy_ct  -- 연관카테고리 구매량
    FROM default.pd_de
    WHERE cco_pd_hlv_c_nm <> '가공식품'       -- 관심카테고리 설정(관심카테고리가 아닌 애들 값)
    GROUP BY cno
        , cco_pd_hlv_c_nm    
        )
-- 둘 다 산 사람들의 구매량 붙이기
    , inter_relate_info AS
    (SELECT w1.cco_pd_hlv_c_nm AS inter_gb
        , w2.cco_pd_hlv_c_nm AS relate_gb
        , w1.cno
        , w1.inter_cate_buy_ct              -- 둘 다 산 사람의 관심카테 구매량
        , w2.relate_cate_buy_ct             -- 둘 다 산 사람의 연관카테 구매량
        , w3.buy_ct                         -- 둘 다 산 사람의 전체 구매량
    FROM inter_cate_info w1                 -- 관심카테 산 사람들
    LEFT JOIN relate_cate_info w2           -- 연관카테 산 사람들
    ON w1.cno = w2.cno
    LEFT JOIN all_cno_info w3
    ON w1.cno = w3.cno
    WHERE w2.cco_pd_hlv_c_nm IS NOT NULL
    )
-- 전체 고객의 전체구매량
    , all_cno_sum AS 
    (SELECT 'join_key' AS join_key
        , COUNT(DISTINCT(cno)) AS cnt_all_cno
        , SUM(buy_ct) AS sum_all_cno_buy_ct
    FROM all_cno_info)
-- 모든 고객의 연관카테 구매량
    , relate_cno_sum AS 
    (SELECT cco_pd_hlv_c_nm
        , COUNT(DISTINCT(cno))  AS cnt_relate_cno
        , SUM(relate_cate_buy_ct) AS sum_relate_cno_buy_ct
    FROM relate_cate_info
    GROUP BY cco_pd_hlv_c_nm
    )
-- 모든 고객의 관심카테 구매량
    , inter_cno_sum AS 
    (SELECT cco_pd_hlv_c_nm
        , COUNT(DISTINCT(cno))  AS cnt_inter_cno
        , SUM(inter_cate_buy_ct) AS sum_inter_cno_buy_ct
    FROM inter_cate_info
    GROUP BY cco_pd_hlv_c_nm
    )
-- 둘 다 산 사람들 summary
    , inter_relate_summary AS 
    (SELECT 'join_key' AS join_key
        , inter_gb
        , relate_gb
        , COUNT(DISTINCT(cno)) AS cnt_inter_relate_cno            -- 두 카테고리 모두 산 고객수
        , SUM(inter_cate_buy_ct) AS sum_in_re_inter_cate_buy_ct   -- 두 카테고리 모두 산 고객의 관심카테 구매량
        , SUM(relate_cate_buy_ct) AS sum_in_re_relate_cate_buy_ct -- 두 카테고리 모두 산 고객의 연관카테 구매량
        , SUM(buy_ct) AS sum_in_re_buy_ct                         -- 두 카테고리 모두 산 고객의 전체 구매량
    FROM inter_relate_info
    GROUP BY inter_gb
        , relate_gb
    )
SELECT t1.inter_gb                                               -- 관심카테
    , t1.relate_gb                                               -- 연관카테
    , t1.cnt_inter_relate_cno                                    -- 두 카테고리 모두 산 고객수
--    , t3.cnt_relate_cno                                          -- 연관카테구매고객수
    , t4.cnt_inter_cno                                           -- 관심카테구매고객수
    , t2.cnt_all_cno                                             -- 전체고객수
    , t1.sum_in_re_relate_cate_buy_ct                            -- 두 카테 모두 산 고객의 연관카테구매량
--    , t1.sum_in_re_inter_cate_buy_ct                             -- 두 카테 모두 산 고객의 관심카테구매량(주석처리)   ** 제외
    , t1.sum_in_re_buy_ct                                        -- 두 카테고리 모두 산 고객의 전체 구매량
--    , CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4)) AS ratio_in_re_buy_ct
    , t3.sum_relate_cno_buy_ct                                   -- 전체 연관카테고리 구매량
--    , t4.sum_inter_cno_buy_ct                                    -- 전체 관심카테고리 구매량(주석처리)
    , t2.sum_all_cno_buy_ct                                      -- 전체구매량
--    , CAST(t3.sum_relate_cno_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_cno_buy_ct AS decimal(20,4)) AS ratio_all_buy_ct
--		, (CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4))) / (CAST(t3.sum_relate_cno_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_cno_buy_ct AS decimal(20,4))) AS relate_score
FROM inter_relate_summary t1
LEFT JOIN all_cno_sum t2
ON t1.join_key = t2.join_key
LEFT JOIN relate_cno_sum t3
ON t1.relate_gb = t3.cco_pd_hlv_c_nm
LEFT JOIN inter_cno_sum t4
ON t1.inter_gb = t4.cco_pd_hlv_c_nm
;

-- 2. 비교군 설정
-- 관심 카테고리 : 면
-- vs 비교군 카테고리 : 과자(대카테고리 선택 시 중분류와 비교 / 중분류 선택 시 소분류와 비교)
-- 관심, 비교군 모두 설정 시
WITH pd_de AS
    (SELECT *
    FROM default.pd_de
    WHERE cco_pd_hlv_c_nm IN ('면','과자'))
-- 관심, 비교군 설정한 거래내역에서 고객들의 전체 구매량 구함
    , all_cno_info AS
    (SELECT cno
        , SUM(buy_ct) AS buy_ct
    FROM pd_de
    GROUP BY cno    
        )
-- 관심카테고리 구매고객 정보
    , inter_cate_info AS 
    (SELECT cno
        , cco_pd_hlv_c_nm                   -- 관심카테고리 tag
        , SUM(buy_ct) AS inter_cate_buy_ct  -- 관심카테고리 구매량
    FROM pd_de
    WHERE cco_pd_hlv_c_nm = '면'       -- 관심카테고리 설정
    GROUP BY cno
        , cco_pd_hlv_c_nm    
        )
-- 연관카테고리 구매고객 정보
    , relate_cate_info AS
    (SELECT cno
        , cco_pd_hlv_c_nm                   -- 연관카테고리 tag
        , cco_pd_mcls_c_nm                  -- 연관카테고리 내 하위 카테고리
        , SUM(buy_ct) AS relate_cate_buy_ct  -- 연관카테고리 구매량
    FROM pd_de
    WHERE cco_pd_hlv_c_nm = '과자'       -- 연관카테고리 설정(연관카테고리 내 하위카테고리값들을 가져와야함)
    GROUP BY cno
        , cco_pd_hlv_c_nm
        , cco_pd_mcls_c_nm    
        )
-- 둘 다 산 사람들의 구매량 붙이기
    , inter_relate_info AS
    (SELECT w1.cco_pd_hlv_c_nm AS inter_gb
        , w2.cco_pd_hlv_c_nm AS relate_gb
        , w2.cco_pd_mcls_c_nm AS relate_under_gb
        , w1.cno
        , w1.inter_cate_buy_ct              -- 둘 다 산 사람의 관심카테 구매량
        , w2.relate_cate_buy_ct             -- 둘 다 산 사람의 연관카테 하위카테 구매량
        , w3.buy_ct                         -- 둘 다 산 사람의 전체 구매량
    FROM inter_cate_info w1                 -- 관심카테 산 사람들
    LEFT JOIN relate_cate_info w2           -- 연관카테 산 사람들
    ON w1.cno = w2.cno
    LEFT JOIN all_cno_info w3
    ON w1.cno = w3.cno
    WHERE w2.cco_pd_hlv_c_nm IS NOT NULL
    	AND w2.cco_pd_mcls_c_nm IS NOT NULL
    )
-- 전체 고객의 전체구매량
    , all_cno_sum AS 
    (SELECT 'join_key' AS join_key
        , COUNT(DISTINCT(cno)) AS cnt_all_cno
        , SUM(buy_ct) AS sum_all_cno_buy_ct
    FROM all_cno_info)
-- 모든 고객의 연관카테 구매량
    , relate_cno_sum AS 
    (SELECT cco_pd_hlv_c_nm
    		, cco_pd_mcls_c_nm
        , COUNT(DISTINCT(cno))  AS cnt_relate_cno
        , SUM(relate_cate_buy_ct) AS sum_relate_cno_buy_ct
    FROM relate_cate_info
    GROUP BY cco_pd_hlv_c_nm
    		, cco_pd_mcls_c_nm
    )
-- 모든 고객의 관심카테 구매량
    , inter_cno_sum AS 
    (SELECT cco_pd_hlv_c_nm
        , COUNT(DISTINCT(cno))  AS cnt_inter_cno
        , SUM(inter_cate_buy_ct) AS sum_inter_cno_buy_ct
    FROM inter_cate_info
    GROUP BY cco_pd_hlv_c_nm
    )
-- 둘 다 산 사람들 summary
    , inter_relate_summary AS 
    (SELECT 'join_key' AS join_key
        , inter_gb
        , relate_gb
        , relate_under_gb
        , COUNT(DISTINCT(cno)) AS cnt_inter_relate_cno            -- 두 카테고리 모두 산 고객수
        , SUM(inter_cate_buy_ct) AS sum_in_re_inter_cate_buy_ct   -- 두 카테고리 모두 산 고객의 관심카테 구매량
        , SUM(relate_cate_buy_ct) AS sum_in_re_relate_cate_buy_ct -- 두 카테고리 모두 산 고객의 연관카테 하위카테 구매량
        , SUM(buy_ct) AS sum_in_re_buy_ct                         -- 두 카테고리 모두 산 고객의 전체 구매량
    FROM inter_relate_info
    GROUP BY inter_gb
        , relate_gb
        , relate_under_gb
    )
SELECT t1.inter_gb                                               -- 관심카테
    , t1.relate_gb                                               -- 연관카테
    , t1.relate_under_gb																				 -- 연관카테고리 하위카테고리
    , t1.cnt_inter_relate_cno                                    -- 두 카테고리 모두 산 고객수
--    , t3.cnt_relate_cno                                          -- 연관카테고리 하위카테구매고객수-- 관심카테구매고객수
    , t4.cnt_inter_cno                                           -- 관심카테구매고객수
    , t2.cnt_all_cno                                             -- 전체고객수
    , t1.sum_in_re_relate_cate_buy_ct                            -- 두 카테 모두 산 고객의 연관카테 하위카테구매량
--    , t1.sum_in_re_inter_cate_buy_ct                             -- 두 카테 모두 산 고객의 관심카테구매량(주석처리)
    , t1.sum_in_re_buy_ct                                        -- 두 카테고리 모두 산 고객의 전체 구매량
--    , CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4)) AS ratio_in_re_buy_ct
    , t3.sum_relate_cno_buy_ct                                   -- 전체 연관카테 하위카테고리 구매량
--    , t4.sum_inter_cno_buy_ct                                    -- 전체 관심카테고리 구매량(주석처리)
    , t2.sum_all_cno_buy_ct                                      -- 전체구매량
--    , CAST(t3.sum_relate_cno_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_cno_buy_ct AS decimal(20,4)) AS ratio_all_buy_ct
--		, (CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4))) / (CAST(t3.sum_relate_cno_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_cno_buy_ct AS decimal(20,4))) AS relate_score
FROM inter_relate_summary t1
LEFT JOIN all_cno_sum t2
ON t1.join_key = t2.join_key
LEFT JOIN relate_cno_sum t3
ON t1.relate_gb = t3.cco_pd_hlv_c_nm
AND t1.relate_under_gb = t3.cco_pd_mcls_c_nm
LEFT JOIN inter_cno_sum t4
ON t1.inter_gb = t4.cco_pd_hlv_c_nm
;


-- ##########################################################################
-- ##########################장바구니(영수증) 기준#############################
-- ##########################################################################



-- 1. 비교군 미설정
-- 관심 카테고리 : 가공식품
-- vs 다른 카테고리
-- 전체 영수증의 구매영수증 정보
WITH all_rct_seq_info AS
    (SELECT rct_seq
        , SUM(buy_ct) AS buy_ct
    FROM default.pd_de
    GROUP BY rct_seq    
        )
-- 관심카테고리 구매영수증 정보
    , inter_cate_info AS 
    (SELECT rct_seq
        , cco_pd_hlv_c_nm                   -- 관심카테고리 tag
        , SUM(buy_ct) AS inter_cate_buy_ct  -- 관심카테고리 구매량
    FROM default.pd_de
    WHERE cco_pd_hlv_c_nm = '가공식품'       -- 관심카테고리 설정
    GROUP BY rct_seq
        , cco_pd_hlv_c_nm    
        )
-- 연관카테고리 구매영수증 정보
    , relate_cate_info AS
    (SELECT rct_seq
        , cco_pd_hlv_c_nm                   -- 연관카테고리 tag
        , SUM(buy_ct) AS relate_cate_buy_ct  -- 연관카테고리 구매량
    FROM default.pd_de
    WHERE cco_pd_hlv_c_nm <> '가공식품'       -- 관심카테고리 설정(관심카테고리가 아닌 애들 값)
    GROUP BY rct_seq
        , cco_pd_hlv_c_nm    
        )
-- 둘 다 산 사람들의 구매량 붙이기
    , inter_relate_info AS
    (SELECT w1.cco_pd_hlv_c_nm AS inter_gb
        , w2.cco_pd_hlv_c_nm AS relate_gb
        , w1.rct_seq
        , w1.inter_cate_buy_ct              -- 둘 다 산 사람의 관심카테 구매량
        , w2.relate_cate_buy_ct             -- 둘 다 산 사람의 연관카테 구매량
        , w3.buy_ct                         -- 둘 다 산 사람의 전체 구매량
    FROM inter_cate_info w1                 -- 관심카테 산 사람들
    LEFT JOIN relate_cate_info w2           -- 연관카테 산 사람들
    ON w1.rct_seq = w2.rct_seq
    LEFT JOIN all_rct_seq_info w3
    ON w1.rct_seq = w3.rct_seq
    WHERE w2.cco_pd_hlv_c_nm IS NOT NULL
    )
-- 전체 영수증의 전체구매량
    , all_rct_seq_sum AS 
    (SELECT 'join_key' AS join_key
        , COUNT(DISTINCT(rct_seq)) AS cnt_all_rct_seq
        , SUM(buy_ct) AS sum_all_rct_seq_buy_ct
    FROM all_rct_seq_info)
-- 모든 영수증의 연관카테 구매량
    , relate_rct_seq_sum AS 
    (SELECT cco_pd_hlv_c_nm
        , COUNT(DISTINCT(rct_seq))  AS cnt_relate_rct_seq
        , SUM(relate_cate_buy_ct) AS sum_relate_rct_seq_buy_ct
    FROM relate_cate_info
    GROUP BY cco_pd_hlv_c_nm
    )
-- 모든 영수증의 관심카테 구매량
    , inter_rct_seq_sum AS 
    (SELECT cco_pd_hlv_c_nm
        , COUNT(DISTINCT(rct_seq))  AS cnt_inter_rct_seq
        , SUM(inter_cate_buy_ct) AS sum_inter_rct_seq_buy_ct
    FROM inter_cate_info
    GROUP BY cco_pd_hlv_c_nm
    )
-- 둘 다 산 사람들 summary
    , inter_relate_summary AS 
    (SELECT 'join_key' AS join_key
        , inter_gb
        , relate_gb
        , COUNT(DISTINCT(rct_seq)) AS cnt_inter_relate_rct_seq            -- 두 카테고리 모두 산 영수증수
        , SUM(inter_cate_buy_ct) AS sum_in_re_inter_cate_buy_ct   -- 두 카테고리 모두 산 영수증의 관심카테 구매량
        , SUM(relate_cate_buy_ct) AS sum_in_re_relate_cate_buy_ct -- 두 카테고리 모두 산 영수증의 연관카테 구매량
        , SUM(buy_ct) AS sum_in_re_buy_ct                         -- 두 카테고리 모두 산 영수증의 전체 구매량
    FROM inter_relate_info
    GROUP BY inter_gb
        , relate_gb
    )
SELECT t1.inter_gb                                               -- 관심카테
    , t1.relate_gb                                               -- 연관카테
    , t3.cnt_relate_rct_seq                                          -- 관심카테구매영수증수
    , t4.cnt_inter_rct_seq                                           -- 연관카테구매영수증수
    , t1.cnt_inter_relate_rct_seq                                    -- 두 카테고리 모두 산 영수증수
    , t2.cnt_all_rct_seq                                             -- 전체영수증수
    , t1.sum_in_re_relate_cate_buy_ct                            -- 두 카테 모두 산 영수증의 연관카테구매량
--    , t1.sum_in_re_inter_cate_buy_ct                             -- 두 카테 모두 산 영수증의 관심카테구매량
    , t1.sum_in_re_buy_ct                                        -- 두 카테고리 모두 산 영수증의 전체 구매량
    , CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4)) AS ratio_in_re_buy_ct
    , t3.sum_relate_rct_seq_buy_ct                                   -- 전체 연관카테고리 구매량
--    , t4.sum_inter_rct_seq_buy_ct                                    -- 전체 관심카테고리 구매량
    , t2.sum_all_rct_seq_buy_ct                                      -- 전체구매량
    , CAST(t3.sum_relate_rct_seq_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_rct_seq_buy_ct AS decimal(20,4)) AS ratio_all_buy_ct
		, (CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4))) / (CAST(t3.sum_relate_rct_seq_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_rct_seq_buy_ct AS decimal(20,4))) AS relate_score
FROM inter_relate_summary t1
LEFT JOIN all_rct_seq_sum t2
ON t1.join_key = t2.join_key
LEFT JOIN relate_rct_seq_sum t3
ON t1.relate_gb = t3.cco_pd_hlv_c_nm
LEFT JOIN inter_rct_seq_sum t4
ON t1.inter_gb = t4.cco_pd_hlv_c_nm
;

-- 2. 비교군 설정
-- 관심 카테고리 : 면
-- vs 비교군 카테고리 : 과자(대카테고리 선택 시 중분류와 비교 / 중분류 선택 시 소분류와 비교)
-- 전체 영수증의 구매영수증 정보
-- 관심, 비교군 모두 설정 시
WITH pd_de AS 
    (SELECT *
    FROM default.pd_de
    WHERE cco_pd_hlv_c_nm IN ('면','과자'))
-- 관심, 비교군 설정한 거래내역에서 영수증들의 전체 구매량 구함
    , all_rct_seq_info AS
    (SELECT rct_seq
        , SUM(buy_ct) AS buy_ct
    FROM pd_de
    GROUP BY rct_seq    
        )
-- 관심카테고리 구매영수증 정보
    , inter_cate_info AS 
    (SELECT rct_seq
        , cco_pd_hlv_c_nm                   -- 관심카테고리 tag
        , SUM(buy_ct) AS inter_cate_buy_ct  -- 관심카테고리 구매량
    FROM pd_de
    WHERE cco_pd_hlv_c_nm = '면'       -- 관심카테고리 설정
    GROUP BY rct_seq
        , cco_pd_hlv_c_nm    
        )
-- 연관카테고리 구매영수증 정보
    , relate_cate_info AS
    (SELECT rct_seq
        , cco_pd_hlv_c_nm                   -- 연관카테고리 tag
        , cco_pd_mcls_c_nm                  -- 연관카테고리 내 하위 카테고리
        , SUM(buy_ct) AS relate_cate_buy_ct  -- 연관카테고리 구매량
    FROM pd_de
    WHERE cco_pd_hlv_c_nm = '과자'       -- 연관카테고리 설정(연관카테고리 내 하위카테고리값들을 가져와야함)
    GROUP BY rct_seq
        , cco_pd_hlv_c_nm
        , cco_pd_mcls_c_nm    
        )
-- 둘 다 산 사람들의 구매량 붙이기
    , inter_relate_info AS
    (SELECT w1.cco_pd_hlv_c_nm AS inter_gb
        , w2.cco_pd_hlv_c_nm AS relate_gb
        , w2.cco_pd_mcls_c_nm AS relate_under_gb
        , w1.rct_seq
        , w1.inter_cate_buy_ct              -- 둘 다 산 사람의 관심카테 구매량
        , w2.relate_cate_buy_ct             -- 둘 다 산 사람의 연관카테 하위카테 구매량
        , w3.buy_ct                         -- 둘 다 산 사람의 전체 구매량
    FROM inter_cate_info w1                 -- 관심카테 산 사람들
    LEFT JOIN relate_cate_info w2           -- 연관카테 산 사람들
    ON w1.rct_seq = w2.rct_seq
    LEFT JOIN all_rct_seq_info w3
    ON w1.rct_seq = w3.rct_seq
    WHERE w2.cco_pd_hlv_c_nm IS NOT NULL
    	AND w2.cco_pd_mcls_c_nm IS NOT NULL
    )
-- 전체 영수증의 전체구매량
    , all_rct_seq_sum AS 
    (SELECT 'join_key' AS join_key
        , COUNT(DISTINCT(rct_seq)) AS cnt_all_rct_seq
        , SUM(buy_ct) AS sum_all_rct_seq_buy_ct
    FROM all_rct_seq_info)
-- 모든 영수증의 연관카테 구매량
    , relate_rct_seq_sum AS 
    (SELECT cco_pd_hlv_c_nm
    		, cco_pd_mcls_c_nm
        , COUNT(DISTINCT(rct_seq))  AS cnt_relate_rct_seq
        , SUM(relate_cate_buy_ct) AS sum_relate_rct_seq_buy_ct
    FROM relate_cate_info
    GROUP BY cco_pd_hlv_c_nm
    		, cco_pd_mcls_c_nm
    )
-- 모든 영수증의 관심카테 구매량
    , inter_rct_seq_sum AS 
    (SELECT cco_pd_hlv_c_nm
        , COUNT(DISTINCT(rct_seq))  AS cnt_inter_rct_seq
        , SUM(inter_cate_buy_ct) AS sum_inter_rct_seq_buy_ct
    FROM inter_cate_info
    GROUP BY cco_pd_hlv_c_nm
    )
-- 둘 다 산 사람들 summary
    , inter_relate_summary AS 
    (SELECT 'join_key' AS join_key
        , inter_gb
        , relate_gb
        , relate_under_gb
        , COUNT(DISTINCT(rct_seq)) AS cnt_inter_relate_rct_seq            -- 두 카테고리 모두 산 영수증수
        , SUM(inter_cate_buy_ct) AS sum_in_re_inter_cate_buy_ct   -- 두 카테고리 모두 산 영수증의 관심카테 구매량
        , SUM(relate_cate_buy_ct) AS sum_in_re_relate_cate_buy_ct -- 두 카테고리 모두 산 영수증의 연관카테 하위카테 구매량
        , SUM(buy_ct) AS sum_in_re_buy_ct                         -- 두 카테고리 모두 산 영수증의 전체 구매량
    FROM inter_relate_info
    GROUP BY inter_gb
        , relate_gb
        , relate_under_gb
    )
SELECT t1.inter_gb                                               -- 관심카테
    , t1.relate_gb                                               -- 연관카테
    , t1.relate_under_gb																				 -- 연관카테고리 하위카테고리
    , t3.cnt_relate_rct_seq                                          -- 관심카테구매영수증수
    , t4.cnt_inter_rct_seq                                           -- 연관카테고리 하위카테구매영수증수
    , t1.cnt_inter_relate_rct_seq                                    -- 두 카테고리 모두 산 영수증수
    , t2.cnt_all_rct_seq                                             -- 전체영수증수
    , t1.sum_in_re_relate_cate_buy_ct                            -- 두 카테 모두 산 영수증의 연관카테 하위카테구매량
--    , t1.sum_in_re_inter_cate_buy_ct                             -- 두 카테 모두 산 영수증의 관심카테구매량(주석처리)
    , t1.sum_in_re_buy_ct                                        -- 두 카테고리 모두 산 영수증의 전체 구매량
    , CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4)) AS ratio_in_re_buy_ct
    , t3.sum_relate_rct_seq_buy_ct                                   -- 전체 연관카테 하위카테고리 구매량
--    , t4.sum_inter_rct_seq_buy_ct                                    -- 전체 관심카테고리 구매량(주석처리)
    , t2.sum_all_rct_seq_buy_ct                                      -- 전체구매량
    , CAST(t3.sum_relate_rct_seq_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_rct_seq_buy_ct AS decimal(20,4)) AS ratio_all_buy_ct
		, (CAST(t1.sum_in_re_relate_cate_buy_ct AS decimal(20,4)) / CAST(t1.sum_in_re_buy_ct AS decimal(20,4))) / (CAST(t3.sum_relate_rct_seq_buy_ct AS decimal(20,4)) / CAST(t2.sum_all_rct_seq_buy_ct AS decimal(20,4))) AS relate_score
FROM inter_relate_summary t1
LEFT JOIN all_rct_seq_sum t2
ON t1.join_key = t2.join_key
LEFT JOIN relate_rct_seq_sum t3
ON t1.relate_gb = t3.cco_pd_hlv_c_nm
AND t1.relate_under_gb = t3.cco_pd_mcls_c_nm
LEFT JOIN inter_rct_seq_sum t4
ON t1.inter_gb = t4.cco_pd_hlv_c_nm
;
