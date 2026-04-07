-- ============================================================
-- 📚 [5주차] SQL 문법 심화반 복습 과제
-- 작성자 : 이창현
-- 데이터셋: classicmodels
-- ============================================================
-- 복습 키워드
--   1. CTE
--   2. KPI 지표
--   3. 문자열 함수
--   4. 쿼리 구조화
-- ============================================================


-- ============================================================
-- 1️⃣  CTE (Common Table Expression)
-- ============================================================
-- 개념: WITH 절로 임시 결과셋을 정의해서 재사용
--       복잡한 쿼리를 단계별로 나눠 가독성 향상

-- 기본 구조
-- WITH cte명 AS (
--     SELECT ...
-- ),
-- cte명2 AS (
--     SELECT ... FROM cte명   -- 앞서 정의한 CTE 참조 가능
-- )
-- SELECT * FROM cte명2;

-- 예제1: 단일 CTE - 주문별 총금액 계산
WITH order_totals AS (
    SELECT
        orderNumber,
        SUM(quantityOrdered * priceEach) AS order_total,
        COUNT(productCode)               AS product_count
    FROM orderdetails
    GROUP BY orderNumber
)
SELECT
    o.orderNumber,
    o.orderDate,
    o.status,
    ROUND(ot.order_total, 2)  AS order_total,
    ot.product_count
FROM orders o
JOIN order_totals ot ON o.orderNumber = ot.orderNumber
ORDER BY order_total DESC
LIMIT 10;


-- 예제2: 다중 CTE - 단계별 분석
WITH
-- STEP 1: 고객별 주문 금액 합산
customer_revenue AS (
    SELECT
        o.customerNumber,
        SUM(od.quantityOrdered * od.priceEach) AS total_revenue
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY o.customerNumber
),
-- STEP 2: 고객 등급 분류
customer_segment AS (
    SELECT
        c.customerNumber,
        c.customerName,
        c.country,
        cr.total_revenue,
        CASE
            WHEN cr.total_revenue >= 100000 THEN 'A: VIP'
            WHEN cr.total_revenue >=  50000 THEN 'B: Gold'
            WHEN cr.total_revenue >=  20000 THEN 'C: Silver'
            ELSE                                 'D: Bronze'
        END AS customer_grade
    FROM customers c
    JOIN customer_revenue cr ON c.customerNumber = cr.customerNumber
)
-- STEP 3: 등급별 집계
SELECT
    customer_grade,
    COUNT(*)                       AS customer_count,
    ROUND(SUM(total_revenue), 2)   AS grade_revenue,
    ROUND(AVG(total_revenue), 2)   AS avg_revenue
FROM customer_segment
GROUP BY customer_grade
ORDER BY customer_grade;


-- ============================================================
-- 2️⃣  KPI 지표
-- ============================================================
-- 개념: Key Performance Indicator (핵심 성과 지표)
-- 비즈니스 목표 달성 여부를 측정하는 정량적 수치
--
-- classicmodels 주요 KPI
-- ① 매출 관련  : 총매출, 월별매출, 제품라인별 매출
-- ② 주문 관련  : 주문건수, 취소율, 평균주문금액
-- ③ 고객 관련  : 신규고객수, 재구매율, 고객당 평균매출
-- ④ 배송 관련  : 평균배송일, 배송 지연율

-- 예제1: 매출 KPI - 연도별 / 월별 매출 추이
SELECT
    YEAR(o.orderDate)                               AS order_year,
    MONTH(o.orderDate)                              AS order_month,
    COUNT(DISTINCT o.orderNumber)                   AS order_count,       -- 주문건수
    COUNT(DISTINCT o.customerNumber)                AS customer_count,    -- 주문 고객수
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS total_revenue,    -- 총매출
    ROUND(AVG(od.quantityOrdered * od.priceEach), 2) AS avg_order_revenue -- 평균주문금액
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE o.status = 'Shipped'
GROUP BY
    YEAR(o.orderDate),
    MONTH(o.orderDate)
ORDER BY
    order_year,
    order_month;


-- 예제2: 주문 KPI - 상태별 취소율 / 완료율
WITH order_status_summary AS (
    SELECT
        COUNT(*)                                                     AS total_orders,
        SUM(CASE WHEN status = 'Shipped'    THEN 1 ELSE 0 END)       AS shipped,
        SUM(CASE WHEN status = 'Cancelled'  THEN 1 ELSE 0 END)       AS cancelled,
        SUM(CASE WHEN status = 'On Hold'    THEN 1 ELSE 0 END)       AS on_hold,
        SUM(CASE WHEN status = 'Resolved'   THEN 1 ELSE 0 END)       AS resolved,
        SUM(CASE WHEN status = 'In Process' THEN 1 ELSE 0 END)       AS in_process,
        SUM(CASE WHEN status = 'Disputed'   THEN 1 ELSE 0 END)       AS disputed
    FROM orders
)
SELECT
    total_orders,
    shipped,
    cancelled,
    on_hold,
    resolved,
    in_process,
    disputed,
    -- KPI: 취소율
    ROUND(cancelled  / total_orders * 100, 2) AS cancel_rate_pct,
    -- KPI: 완료율
    ROUND(shipped    / total_orders * 100, 2) AS shipped_rate_pct,
    -- KPI: 문제 주문율 (취소+분쟁)
    ROUND((cancelled + disputed) / total_orders * 100, 2) AS issue_rate_pct
FROM order_status_summary;


-- 예제3: 고객 KPI - 재구매율 (2회 이상 주문한 고객 비율)
WITH customer_order_count AS (
    SELECT
        customerNumber,
        COUNT(orderNumber) AS order_count
    FROM orders
    GROUP BY customerNumber
)
SELECT
    COUNT(*)                                                         AS total_customers,
    SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END)               AS repeat_customers,
    ROUND(
        SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END)
        / COUNT(*) * 100
    , 2)                                                             AS repeat_rate_pct  -- 재구매율
FROM customer_order_count;


-- 예제4: 배송 KPI - 평균 배송 소요일 / 지연율
SELECT
    ROUND(AVG(DATEDIFF(shippedDate, orderDate)), 1)  AS avg_shipping_days,  -- 평균 배송일
    ROUND(AVG(DATEDIFF(requiredDate, orderDate)), 1) AS avg_lead_days,      -- 평균 리드타임
    -- 지연 건수 (shippedDate > requiredDate)
    SUM(CASE WHEN shippedDate > requiredDate THEN 1 ELSE 0 END)    AS delayed_count,
    COUNT(shippedDate)                                              AS shipped_count,
    -- KPI: 배송 지연율
    ROUND(
        SUM(CASE WHEN shippedDate > requiredDate THEN 1 ELSE 0 END)
        / COUNT(shippedDate) * 100
    , 2)                                                            AS delay_rate_pct
FROM orders
WHERE shippedDate IS NOT NULL;


-- ============================================================
-- 3️⃣  문자열 함수
-- ============================================================
-- 주요 문자열 함수 정리
--
-- UPPER(str)           : 대문자 변환
-- LOWER(str)           : 소문자 변환
-- LENGTH(str)          : 문자열 길이
-- SUBSTRING(str,pos,n) : 부분 문자열 추출
-- LEFT(str, n)         : 왼쪽에서 n글자
-- RIGHT(str, n)        : 오른쪽에서 n글자
-- TRIM(str)            : 앞뒤 공백 제거
-- REPLACE(str,old,new) : 문자열 치환
-- CONCAT(str1, str2)   : 문자열 합치기
-- CONCAT_WS(sep,...)   : 구분자로 합치기
-- INSTR(str, substr)   : 부분 문자열 위치 반환
-- REGEXP               : 정규표현식 패턴 매칭

-- 예제1: 기본 문자열 함수 활용
SELECT
    customerName,
    UPPER(customerName)                      AS upper_name,        -- 대문자
    LOWER(customerName)                      AS lower_name,        -- 소문자
    LENGTH(customerName)                     AS name_length,       -- 글자수
    LEFT(customerName, 5)                    AS left_5,            -- 왼쪽 5글자
    RIGHT(customerName, 5)                   AS right_5,           -- 오른쪽 5글자
    SUBSTRING(customerName, 1, 8)            AS substr_1_8         -- 1번째부터 8글자
FROM customers
LIMIT 10;


-- 예제2: CONCAT / REPLACE / TRIM 활용
SELECT
    firstName,
    lastName,
    -- 성+이름 합치기
    CONCAT(firstName, ' ', lastName)                         AS full_name,
    -- 구분자로 합치기
    CONCAT_WS(' | ', firstName, lastName, jobTitle)          AS employee_info,
    -- 이메일에서 도메인 추출
    REPLACE(email, SUBSTRING(email, 1, INSTR(email, '@')-1), '') AS email_domain
FROM employees;


-- 예제3: REGEXP 패턴 매칭
SELECT
    customerName,
    phone,
    country
FROM customers
WHERE
    -- 'Gifts' 또는 'Toys' 포함된 고객
    customerName REGEXP 'Gifts|Toys'
ORDER BY country;


-- 예제4: 문자열 함수로 데이터 정제
SELECT
    productCode,
    productName,
    -- 제품코드에서 스케일 코드 추출 (S10, S12 등)
    LEFT(productCode, 3)                     AS scale_code,
    -- 제품명에서 연도 추출 (4자리 숫자)
    CASE
        WHEN productName REGEXP '^[0-9]{4}'
        THEN LEFT(productName, 4)
        ELSE 'N/A'
    END                                      AS model_year,
    -- 제품명 길이로 긴 이름 여부 판단
    CASE
        WHEN LENGTH(productName) > 30 THEN '긴 이름'
        ELSE '보통 이름'
    END                                      AS name_type
FROM products
ORDER BY scale_code, model_year;


-- ============================================================
-- 4️⃣  쿼리 구조화
-- ============================================================
-- 개념: 복잡한 분석을 CTE로 단계별로 나눠 작성
--       각 단계에 명확한 주석을 달아 가독성 향상
--
-- 구조화 원칙
-- ① 각 CTE는 하나의 역할만 수행
-- ② CTE명은 역할을 명확히 표현
-- ③ 주석으로 각 단계 설명
-- ④ 최종 SELECT는 단순하게 유지

-- 예제: 영업사원별 성과 분석 (구조화된 쿼리)
WITH
-- ============================================================
-- STEP 1: 주문별 총금액 계산
-- ============================================================
order_revenue AS (
    SELECT
        orderNumber,
        SUM(quantityOrdered * priceEach) AS revenue
    FROM orderdetails
    GROUP BY orderNumber
),
-- ============================================================
-- STEP 2: 고객별 총 구매금액 집계
-- ============================================================
customer_revenue AS (
    SELECT
        o.customerNumber,
        COUNT(o.orderNumber)         AS order_count,
        SUM(orv.revenue)             AS total_revenue
    FROM orders o
    JOIN order_revenue orv ON o.orderNumber = orv.orderNumber
    WHERE o.status = 'Shipped'       -- 실제 배송 완료 주문만
    GROUP BY o.customerNumber
),
-- ============================================================
-- STEP 3: 영업사원별 담당 고객 매출 집계
-- ============================================================
rep_performance AS (
    SELECT
        e.employeeNumber,
        CONCAT(e.firstName, ' ', e.lastName) AS rep_name,
        e.jobTitle,
        COUNT(cr.customerNumber)             AS customer_count,  -- 담당 고객 수
        SUM(cr.order_count)                  AS total_orders,    -- 총 주문 건수
        ROUND(SUM(cr.total_revenue), 2)      AS total_revenue,   -- 총 매출
        ROUND(AVG(cr.total_revenue), 2)      AS avg_revenue      -- 고객당 평균 매출
    FROM employees e
    JOIN customers c  ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN customer_revenue cr ON c.customerNumber = cr.customerNumber
    GROUP BY
        e.employeeNumber,
        e.firstName,
        e.lastName,
        e.jobTitle
),
-- ============================================================
-- STEP 4: 순위 부여
-- ============================================================
rep_ranked AS (
    SELECT
        *,
        RANK()       OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_dense_rank
    FROM rep_performance
)
-- ============================================================
-- STEP 5: 최종 출력
-- ============================================================
SELECT
    revenue_rank,
    rep_name,
    customer_count,
    total_orders,
    total_revenue,
    avg_revenue,
    -- KPI: 성과 등급
    CASE
        WHEN revenue_rank = 1               THEN '🥇 1등'
        WHEN revenue_rank <= 3              THEN '🥈 TOP3'
        WHEN revenue_rank <= 5              THEN '🥉 TOP5'
        ELSE                                     '일반'
    END AS performance_grade
FROM rep_ranked
ORDER BY revenue_rank;


-- ============================================================
-- 📝 키워드 요약
-- ============================================================
-- CTE (WITH)     : 임시 결과셋 → 가독성 ↑ 재사용 ↑ 단계별 분리
-- KPI 지표       : 매출/주문/고객/배송 핵심 수치를 SQL로 계산
-- 문자열 함수    : UPPER/LOWER/CONCAT/REPLACE/SUBSTRING/REGEXP
-- 쿼리 구조화   : CTE 단계 분리 + 명확한 CTE명 + 주석으로 설명
-- ============================================================
