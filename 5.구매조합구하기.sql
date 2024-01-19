-- 구매 조합 구하기
CREATE TABLE cross1 AS
SELECT itg_user_id
  , group_concat(segment12) AS cross_seg
FROM summers_raw_cross
GROUP BY itg_user_id
;

SELECT cross_seg
  , COUNT(DISTINCT(itg_user_id)) AS user_cnt
FROM cross1
GROUP BY cross_seg

