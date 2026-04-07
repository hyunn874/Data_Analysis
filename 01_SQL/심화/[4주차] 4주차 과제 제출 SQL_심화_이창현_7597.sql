
-- [4주차] 4주차 과제 제출 SQL_심화_이창현_7597

## 1. REGEXP (정규표현식)
-- 개념: 특정 패턴을 가진 문자열을 검색
-- LIKE보다 훨씬 강력한 패턴 매칭

-- 자주 쓰는 패턴
-- ^  : 문자열 시작
-- $  : 문자열 끝
-- .  : 임의의 한 문자
-- *  : 0번 이상 반복
-- +  : 1번 이상 반복
-- [] : 괄호 안의 문자 중 하나
-- |  : 또는 (OR)

-- 예제1: 고객명이 'Mini'로 시작하는 고객
SELECT customerName
FROM customers
WHERE customerName REGEXP '^Mini';

-- 예제2: 이메일이 gmail 또는 yahoo인 직원
SELECT firstName, email
FROM employees
WHERE email REGEXP 'gmail|yahoo';

-- 예제3: 제품코드가 숫자로 끝나는 제품
SELECT productCode, productName
FROM products
WHERE productCode REGEXP '[0-9]$';

-- 예제4: 고객 전화번호에 숫자만 포함된 경우
SELECT customerName, phone
FROM customers
WHERE phone REGEXP '^[0-9]+$';

## 2. 정규표현식 패턴 정리
-- 개념: REGEXP에서 사용하는 패턴 모음
-- classicmodels 실전 예제로 정리

-- 패턴1: 특정 문자 포함
-- 제품명에 '1969' 포함된 제품
SELECT productName
FROM products
WHERE productName REGEXP '1969';

-- 패턴2: 대괄호로 범위 지정
-- 제품코드가 S10 또는 S12로 시작하는 제품
SELECT productCode, productName
FROM products
WHERE productCode REGEXP '^S1[02]';

-- 패턴3: 자릿수 지정 {n}
-- 우편번호가 정확히 5자리 숫자인 고객
SELECT customerName, postalCode
FROM customers
WHERE postalCode REGEXP '^[0-9]{5}$';

-- 패턴4: 복합 조건
-- 고객명에 'Co' 또는 'Ltd' 또는 'Inc' 포함
SELECT customerName, country
FROM customers
WHERE customerName REGEXP 'Co\\.|Ltd|Inc';

## 3. CTE (Common Table Expression)
-- 개념: WITH절로 임시 결과셋을 만들어 재사용
-- 서브쿼리보다 가독성 좋고 재사용 가능

-- 기본 구조
-- WITH cte이름 AS (
--     SELECT ...
-- )
-- SELECT * FROM cte이름;

-- 예제1: 단일 CTE
-- 고객별 총 주문금액 계산 후 상위 5명 추출
WITH customer_sales AS (
    SELECT 
        c.customerNumber,
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM customers c
    JOIN orders o      ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY c.customerNumber, c.customerName
)
SELECT *
FROM customer_sales
ORDER BY total_sales DESC
LIMIT 5;

-- 예제2: 다중 CTE (CTE를 여러 개 연결)
WITH 
order_summary AS (
    SELECT 
        customerNumber,
        COUNT(*) AS order_count,
        MAX(orderDate) AS last_order_date
    FROM orders
    GROUP BY customerNumber
),
customer_grade AS (
    SELECT 
        c.customerName,
        c.creditLimit,
        os.order_count,
        os.last_order_date
    FROM customers c
    JOIN order_summary os ON c.customerNumber = os.customerNumber
)
SELECT *
FROM customer_grade
ORDER BY order_count DESC;

## 4. CASE WHEN (심화)
-- 개념: 조건 분기 (SQL_입문에서 배운 내용 심화)
-- 심화반에서는 중첩 CASE WHEN, 집계와 결합 활용

-- 예제1: 중첩 CASE WHEN
-- 국가별 + 신용등급 복합 분류
SELECT 
    customerName,
    country,
    creditLimit,
    CASE 
        WHEN country = 'USA' THEN
            CASE 
                WHEN creditLimit >= 100000 THEN 'USA_VIP'
                ELSE 'USA_일반'
            END
        WHEN country = 'France' THEN
            CASE 
                WHEN creditLimit >= 100000 THEN 'France_VIP'
                ELSE 'France_일반'
            END
        ELSE '기타국가'
    END AS customer_segment
FROM customers;

-- 예제2: CASE WHEN + 집계 (조건부 집계)
-- 연도별 / 상태별 주문 건수 피봇팅
SELECT 
    YEAR(orderDate) AS order_year,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'Shipped'    THEN 1 ELSE 0 END) AS shipped,
    SUM(CASE WHEN status = 'Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN status = 'On Hold'    THEN 1 ELSE 0 END) AS on_hold,
    SUM(CASE WHEN status = 'Resolved'   THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN status = 'In Process' THEN 1 ELSE 0 END) AS in_process,
    SUM(CASE WHEN status = 'Disputed'   THEN 1 ELSE 0 END) AS disputed
FROM orders
GROUP BY YEAR(orderDate);

## 5. 쿼리 구조화
-- 개념: 복잡한 쿼리를 CTE로 단계별로 나눠서 작성
-- 가독성 ↑ / 디버깅 ↑ / 재사용 ↑

-- 예제: 복잡한 분석을 단계별로 구조화
-- "제품라인별 / 연도별 매출 TOP3 제품 추출"

-- STEP 1: 제품별 연도별 매출 계산
WITH product_yearly_sales AS (
    SELECT 
        p.productCode,
        p.productName,
        p.productLine,
        YEAR(o.orderDate)                        AS order_year,
        SUM(od.quantityOrdered * od.priceEach)   AS total_sales
    FROM products p
    JOIN orderdetails od ON p.productCode  = od.productCode
    JOIN orders o        ON od.orderNumber = o.orderNumber
    GROUP BY 
        p.productCode, 
        p.productName, 
        p.productLine, 
        YEAR(o.orderDate)
),
-- STEP 2: 제품라인별 연도별 순위 매기기
product_ranked AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY productLine, order_year
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM product_yearly_sales
)
-- STEP 3: TOP3만 추출
SELECT 
    productLine,
    order_year,
    productName,
    total_sales,
    sales_rank
FROM product_ranked
WHERE sales_rank <= 3
ORDER BY productLine, order_year, sales_rank;