
### BDA SQL 입문 4주차 복습과제 // 이창현_7597
use classicmodels;


## 1. CROSS JOIN
-- 개념: 두 테이블의 모든 행을 조합 (카테시안 곱)
-- A테이블 3행 × B테이블 4행 = 12행 결과

-- 예제: 모든 사무소(offices)와 제품라인(productlines) 조합
SELECT 
    o.city,
    pl.productLine
FROM offices o
CROSS JOIN productlines pl;
-- 결과: 7개 사무소 × 7개 제품라인 = 49행

## 2. 셀프조인 (SELF JOIN)
-- 개념: 같은 테이블을 두 번 참조해서 JOIN
-- employees 테이블에 reportsTo(상사 번호)가 같은 테이블 내에 존재

-- 예제: 직원과 그 직원의 상사 이름 함께 출력
SELECT 
    e.firstName AS 직원명,
    e.jobTitle  AS 직급,
    m.firstName AS 상사명,
    m.jobTitle  AS 상사직급
FROM employees e
LEFT JOIN employees m ON e.reportsTo = m.employeeNumber;
-- LEFT JOIN 쓰는 이유: 상사가 없는 최상위 직원(President)도 출력하기 위해

## 3. PIVOTING
-- 개념: 행(row) 데이터를 열(column)로 변환
-- MySQL은 PIVOT 함수 없으므로 CASE WHEN + SUM/COUNT 조합으로 구현

-- 예제: 제품라인별 연도별 주문 수량 피봇팅
SELECT 
    p.productLine,
    SUM(CASE WHEN YEAR(o.orderDate) = 2003 THEN od.quantityOrdered ELSE 0 END) AS qty_2003,
    SUM(CASE WHEN YEAR(o.orderDate) = 2004 THEN od.quantityOrdered ELSE 0 END) AS qty_2004,
    SUM(CASE WHEN YEAR(o.orderDate) = 2005 THEN od.quantityOrdered ELSE 0 END) AS qty_2005
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p     ON od.productCode = p.productCode
GROUP BY p.productLine;

## 4. CASE WHEN
-- 개념: 조건에 따라 다른 값을 반환 (if-else 역할)
-- CASE WHEN 조건 THEN 결과 ELSE 기본값 END

-- 예제: 고객 신용한도를 등급으로 분류
SELECT 
    customerName,
    creditLimit,
    CASE 
        WHEN creditLimit >= 150000 THEN 'VIP'
        WHEN creditLimit >= 80000  THEN '일반'
        WHEN creditLimit > 0       THEN '저신용'
        ELSE '한도없음'
    END AS 신용등급
FROM customers
ORDER BY creditLimit DESC;

## 5. 조건부 집계
-- 개념: 집계함수(SUM, COUNT) 안에 CASE WHEN을 넣어
--       특정 조건을 만족하는 행만 선택적으로 집계

-- 예제: 주문 상태별 건수를 한 행에 집계
SELECT 
    customerNumber,
    COUNT(*) AS 전체주문수,
    SUM(CASE WHEN status = 'Shipped'   THEN 1 ELSE 0 END) AS 배송완료,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS 취소,
    SUM(CASE WHEN status = 'On Hold'   THEN 1 ELSE 0 END) AS 보류,
    SUM(CASE WHEN status = 'Resolved'  THEN 1 ELSE 0 END) AS 해결됨,
    SUM(CASE WHEN status = 'In Process'THEN 1 ELSE 0 END) AS 처리중,
    SUM(CASE WHEN status = 'Disputed'  THEN 1 ELSE 0 END) AS 분쟁중
FROM orders
GROUP BY customerNumber
ORDER BY 전체주문수 DESC;