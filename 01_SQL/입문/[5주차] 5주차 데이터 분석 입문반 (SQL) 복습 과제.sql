-- ============================================================
-- 📚 [5주차] 데이터 분석 입문반 (SQL) 복습 과제
-- 작성자 : 이창현
-- 데이터셋: classicmodels
-- ============================================================
-- 복습 키워드
--   1. RANK
--   2. DENSE_RANK
--   3. ROW_NUMBER
--   4. PARTITION BY
--   5. CTE
-- ============================================================


-- ============================================================
-- 1️⃣  RANK
-- ============================================================
-- 개념: 순위를 매기되, 동점이면 같은 순위 부여
--       다음 순위는 동점 수만큼 건너뜀
--       예) 1, 1, 3, 4  (2위 없음)

-- 예제: 제품라인별 매출 순위 (동점 시 순위 건너뜀)
SELECT
    productLine,
    productName,
    MSRP,
    RANK() OVER (
        PARTITION BY productLine   -- 제품라인별로 그룹
        ORDER BY MSRP DESC         -- 가격 높은 순
    ) AS price_rank
FROM products
ORDER BY productLine, price_rank;


-- ============================================================
-- 2️⃣  DENSE_RANK
-- ============================================================
-- 개념: 순위를 매기되, 동점이면 같은 순위 부여
--       다음 순위는 건너뛰지 않음
--       예) 1, 1, 2, 3  (2위 있음)

-- 예제: 국가별 고객 신용한도 순위 (동점 시 순위 안건너뜀)
SELECT
    country,
    customerName,
    creditLimit,
    DENSE_RANK() OVER (
        PARTITION BY country       -- 국가별로 그룹
        ORDER BY creditLimit DESC  -- 신용한도 높은 순
    ) AS credit_dense_rank
FROM customers
ORDER BY country, credit_dense_rank;


-- ============================================================
-- 3️⃣  ROW_NUMBER
-- ============================================================
-- 개념: 동점 상관없이 무조건 1씩 증가하는 고유 번호 부여
--       예) 1, 2, 3, 4  (항상 유일한 번호)

-- 예제: 고객별 주문을 날짜 순서대로 번호 매기기
SELECT
    customerNumber,
    orderNumber,
    orderDate,
    ROW_NUMBER() OVER (
        PARTITION BY customerNumber  -- 고객별로 그룹
        ORDER BY orderDate ASC       -- 날짜 오래된 순
    ) AS row_num
FROM orders
ORDER BY customerNumber, row_num;


-- ============================================================
-- ✅ RANK vs DENSE_RANK vs ROW_NUMBER 비교
-- ============================================================
-- 같은 데이터에 세 함수를 동시에 적용해서 차이 확인

SELECT
    customerNumber,
    orderNumber,
    orderDate,
    RANK()       OVER (PARTITION BY customerNumber ORDER BY orderDate) AS rnk,
    DENSE_RANK() OVER (PARTITION BY customerNumber ORDER BY orderDate) AS dense_rnk,
    ROW_NUMBER() OVER (PARTITION BY customerNumber ORDER BY orderDate) AS row_num
FROM orders
ORDER BY customerNumber, orderDate;

-- 결과 해석
-- rnk       : 동점이면 같은 순위, 다음 순위 건너뜀  (1,1,3)
-- dense_rnk : 동점이면 같은 순위, 다음 순위 안건너뜀 (1,1,2)
-- row_num   : 항상 고유한 번호 부여                  (1,2,3)


-- ============================================================
-- 4️⃣  PARTITION BY
-- ============================================================
-- 개념: 윈도우 함수에서 그룹을 나누는 기준
--       GROUP BY처럼 집계하지 않고 행을 유지하면서 그룹별 계산

-- 예제1: 제품라인별 평균 가격 대비 각 제품 가격 비교
SELECT
    productLine,
    productName,
    buyPrice,
    ROUND(AVG(buyPrice) OVER (
        PARTITION BY productLine   -- 제품라인별 평균
    ), 2) AS avg_price_by_line,
    ROUND(buyPrice - AVG(buyPrice) OVER (
        PARTITION BY productLine
    ), 2) AS diff_from_avg        -- 평균과의 차이
FROM products
ORDER BY productLine, diff_from_avg DESC;

-- 예제2: PARTITION BY 없을 때 vs 있을 때 차이
SELECT
    productLine,
    productName,
    buyPrice,
    -- PARTITION BY 없음 → 전체 평균
    ROUND(AVG(buyPrice) OVER (), 2)                          AS total_avg,
    -- PARTITION BY 있음 → 제품라인별 평균
    ROUND(AVG(buyPrice) OVER (PARTITION BY productLine), 2)  AS line_avg
FROM products
ORDER BY productLine;


-- ============================================================
-- 5️⃣  CTE (Common Table Expression)
-- ============================================================
-- 개념: WITH 절로 임시 결과셋을 만들어 재사용
--       서브쿼리보다 가독성 좋고 여러 번 참조 가능

-- 기본 구조
-- WITH cte명 AS (
--     SELECT ...
-- )
-- SELECT * FROM cte명;

-- 예제1: 단일 CTE
-- 고객별 총 주문금액 계산 후 상위 5명 추출
WITH customer_sales AS (
    SELECT
        c.customerNumber,
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM customers c
    JOIN orders o        ON c.customerNumber  = o.customerNumber
    JOIN orderdetails od ON o.orderNumber     = od.orderNumber
    GROUP BY c.customerNumber, c.customerName
)
SELECT *
FROM customer_sales
ORDER BY total_sales DESC
LIMIT 5;


-- 예제2: 다중 CTE (CTE를 여러 개 연결)
WITH
-- STEP 1: 주문별 총금액
order_amount AS (
    SELECT
        orderNumber,
        SUM(quantityOrdered * priceEach) AS order_total
    FROM orderdetails
    GROUP BY orderNumber
),
-- STEP 2: 고객별 주문 통계
customer_stats AS (
    SELECT
        o.customerNumber,
        COUNT(o.orderNumber)       AS order_count,
        SUM(oa.order_total)        AS total_spent,
        MAX(o.orderDate)           AS last_order_date
    FROM orders o
    JOIN order_amount oa ON o.orderNumber = oa.orderNumber
    GROUP BY o.customerNumber
)
-- STEP 3: 고객 정보와 합치기
SELECT
    c.customerName,
    c.country,
    cs.order_count,
    ROUND(cs.total_spent, 2)  AS total_spent,
    cs.last_order_date
FROM customers c
JOIN customer_stats cs ON c.customerNumber = cs.customerNumber
ORDER BY total_spent DESC;


-- ============================================================
-- 🔥 복습 키워드 종합 활용 예제
-- ============================================================
-- CTE + PARTITION BY + RANK + DENSE_RANK + ROW_NUMBER 한번에!
-- "제품라인별 매출 TOP3 제품 추출"

WITH product_sales AS (
    -- STEP 1: 제품별 총 매출 계산
    SELECT
        p.productCode,
        p.productName,
        p.productLine,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM products p
    JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY
        p.productCode,
        p.productName,
        p.productLine
),
product_ranked AS (
    -- STEP 2: 제품라인별 순위 매기기
    SELECT
        productCode,
        productName,
        productLine,
        total_sales,
        RANK()       OVER (PARTITION BY productLine ORDER BY total_sales DESC) AS rnk,
        DENSE_RANK() OVER (PARTITION BY productLine ORDER BY total_sales DESC) AS dense_rnk,
        ROW_NUMBER() OVER (PARTITION BY productLine ORDER BY total_sales DESC) AS row_num
    FROM product_sales
)
-- STEP 3: TOP3만 추출
SELECT
    productLine,
    productName,
    ROUND(total_sales, 2) AS total_sales,
    rnk,
    dense_rnk,
    row_num
FROM product_ranked
WHERE rnk <= 3
ORDER BY productLine, rnk;


-- ============================================================
-- 📝 키워드 요약
-- ============================================================
-- RANK()        : 동점 같은 순위, 다음 순위 건너뜀   (1,1,3)
-- DENSE_RANK()  : 동점 같은 순위, 다음 순위 안건너뜀 (1,1,2)
-- ROW_NUMBER()  : 항상 고유 번호                     (1,2,3)
-- PARTITION BY  : 윈도우 함수의 그룹 기준 (행 유지)
-- CTE (WITH)    : 임시 결과셋 → 가독성 ↑ 재사용 ↑
-- ============================================================
