/************************************************************************/
/*         SQL 문법 심화 과제 2 - 이창현 (7597)                          */
/*         키워드: LEFT JOIN / SELF JOIN / 문자열함수 / SUBSTRING / CONCAT */
/************************************************************************/

USE classicmodels;


/************************************************************************/
/* 1. LEFT JOIN                                                         */
/************************************************************************/

-- ▶ 개념
-- 왼쪽(기준) 테이블의 모든 행을 유지하면서
-- 오른쪽 테이블의 일치하는 데이터를 붙임
-- 오른쪽 테이블에 일치하는 데이터가 없으면 NULL로 채움
-- 실무에서 가장 많이 사용하는 JOIN

-- ▶ INNER JOIN vs LEFT JOIN 핵심 차이
-- INNER JOIN → 두 테이블 모두 일치하는 행만 출력 (교집합)
-- LEFT JOIN  → 왼쪽 기준 전체 + 오른쪽 일치하는 데이터 (NULL 포함)

-- ▶ 예문 1. 주문 이력이 없는 고객 포함 전체 고객 조회
-- customers LEFT JOIN orders
-- → 주문 없는 고객도 포함 (orders 컬럼은 NULL)
SELECT  c.customerNumber
        ,c.customerName
        ,c.country
        ,o.orderNumber
        ,o.orderDate
        ,o.status
  FROM  customers AS c
  LEFT
  JOIN  orders AS o
    ON  c.customerNumber = o.customerNumber
 ORDER
    BY  c.customerNumber;

-- ▶ 예문 2. 주문을 한 번도 하지 않은 고객만 추출
-- LEFT JOIN 후 NULL 필터링 → 미주문 고객 추출
SELECT  c.customerNumber
        ,c.customerName
        ,c.country
        ,c.creditLimit
  FROM  customers AS c
  LEFT
  JOIN  orders AS o
    ON  c.customerNumber = o.customerNumber
 WHERE  o.orderNumber IS NULL  -- NULL = 주문 이력 없음
 ORDER
    BY  c.creditLimit DESC;

-- ▶ 예문 3. 신용한도가 평균 이상이지만 주문 이력 없는 고객
-- 잠재 고객 발굴 목적 (마케팅 활용)
SELECT  c.customerNumber
        ,c.customerName
        ,c.country
        ,c.creditLimit
        ,ROUND((SELECT AVG(creditLimit) FROM customers), 2) AS AVG_CREDIT
  FROM  customers AS c
  LEFT
  JOIN  orders AS o
    ON  c.customerNumber = o.customerNumber
 WHERE  o.orderNumber IS NULL
   AND  c.creditLimit > (SELECT AVG(creditLimit) FROM customers)
 ORDER
    BY  c.creditLimit DESC;


/************************************************************************/
/* 2. SELF JOIN                                                         */
/************************************************************************/

-- ▶ 개념
-- 같은 테이블을 두 번 JOIN하는 방법
-- 테이블 내에서 행끼리 비교하거나 계층 구조를 표현할 때 사용
-- 반드시 별칭(AS)을 다르게 지정해야 함
-- employees 테이블의 reportsTo(상사번호) 활용이 대표적 예시

-- ▶ 왜 SELF JOIN이 필요한가?
-- reportsTo 컬럼에는 상사의 employeeNumber(숫자)만 저장됨
-- 상사의 이름을 알려면 같은 테이블을 다시 JOIN해야 함
-- e1(직원) → reportsTo = 상사번호 → e2(상사) employeeNumber와 연결

-- ▶ 예문 1. 직원과 직속 상사 이름 함께 조회
SELECT  e1.employeeNumber                           AS 직원번호
        ,CONCAT(e1.firstName, ' ', e1.lastName)     AS 직원이름
        ,e1.jobTitle                                AS 직책
        ,e1.reportsTo                               AS 상사번호
        ,CONCAT(e2.firstName, ' ', e2.lastName)     AS 상사이름
        ,e2.jobTitle                                AS 상사직책
  FROM  employees AS e1
  LEFT                         -- LEFT: 상사 없는 사장도 포함
  JOIN  employees AS e2
    ON  e1.reportsTo = e2.employeeNumber
 ORDER
    BY  e1.employeeNumber;

-- ▶ 예문 2. 같은 사무소에 근무하는 직원 쌍 조회
SELECT  e1.employeeNumber   AS 직원1번호
        ,e1.lastName        AS 직원1이름
        ,e2.employeeNumber  AS 직원2번호
        ,e2.lastName        AS 직원2이름
        ,e1.officeCode      AS 사무소코드
  FROM  employees AS e1
  JOIN  employees AS e2
    ON  e1.officeCode = e2.officeCode   -- 같은 사무소
   AND  e1.employeeNumber < e2.employeeNumber  -- 중복 제거
 ORDER
    BY  e1.officeCode;


/************************************************************************/
/* 3. 문자열 함수                                                        */
/************************************************************************/

-- ▶ 자주 사용하는 문자열 함수 종류
-- SUBSTRING / SUBSTR  : 문자열 일부 추출
-- CONCAT              : 문자열 합치기
-- UPPER / LOWER       : 대/소문자 변환
-- TRIM / LTRIM / RTRIM: 공백 제거
-- LENGTH              : 문자열 길이
-- REPLACE             : 문자열 치환
-- LIKE                : 문자열 패턴 검색

-- ▶ 문자열 함수 한눈에 보기
SELECT  'Hello World'                       AS 원본
        ,UPPER('Hello World')               AS 대문자
        ,LOWER('Hello World')               AS 소문자
        ,LENGTH('Hello World')              AS 길이
        ,TRIM('  Hello World  ')            AS 공백제거
        ,REPLACE('Hello World', 'World', 'SQL') AS 치환;


/************************************************************************/
/* 4. SUBSTRING (문자열 추출)                                            */
/************************************************************************/

-- ▶ 개념
-- 문자열의 특정 위치에서 원하는 길이만큼 추출
-- SUBSTRING = SUBSTR (동일한 함수)

-- ▶ 기본 구조
-- SUBSTRING(문자열, 시작위치, 길이)
-- 시작위치: 1부터 시작 (0이 아님!)
-- 길이: 생략하면 끝까지 추출

-- ▶ 기본 예시
SELECT  'classicmodels'                         AS 원본
        ,SUBSTRING('classicmodels', 1, 7)       AS 앞7자리    -- 'classic'
        ,SUBSTRING('classicmodels', 8)          AS 8번째부터  -- 'models'
        ,SUBSTRING('classicmodels', -6)         AS 뒤6자리    -- 'models'
        ,SUBSTR('classicmodels', 1, 7)          AS SUBSTR동일;

-- ▶ 예문 1. 고객 전화번호에서 지역번호만 추출
SELECT  customerName
        ,phone
        ,SUBSTRING(phone, 1, LOCATE('-', phone) - 1) AS 지역번호
  FROM  customers
 LIMIT  10;

-- ▶ 예문 2. 제품 코드에서 카테고리 코드만 추출
-- productCode 예시: S10_1678 → S10 추출
SELECT  productCode
        ,productName
        ,SUBSTRING(productCode, 1, 3) AS 카테고리코드
  FROM  products
 ORDER
    BY  productCode;

-- ▶ 예문 3. 주문일자에서 연도만 추출
-- DATE_FORMAT 대신 SUBSTRING으로도 가능
SELECT  orderNumber
        ,orderDate
        ,SUBSTRING(orderDate, 1, 4) AS 연도    -- '2003'
        ,SUBSTRING(orderDate, 6, 2) AS 월      -- '01'
        ,SUBSTRING(orderDate, 9, 2) AS 일      -- '26'
  FROM  orders
 LIMIT  5;


/************************************************************************/
/* 5. CONCAT (문자열 합치기)                                             */
/************************************************************************/

-- ▶ 개념
-- 두 개 이상의 문자열을 하나로 합치는 함수
-- NULL이 하나라도 있으면 결과가 NULL 반환
-- CONCAT_WS는 구분자를 지정할 수 있음

-- ▶ 기본 구조
-- CONCAT(문자열1, 문자열2, ...)
-- CONCAT_WS(구분자, 문자열1, 문자열2, ...)

-- ▶ 기본 예시
SELECT  CONCAT('Hello', ' ', 'World')           AS 기본합치기
        ,CONCAT('2024', '-', '01', '-', '01')   AS 날짜형식
        ,CONCAT_WS(' ', 'Hello', 'World', 'SQL') AS 구분자합치기
        ,CONCAT('이름: ', NULL, '홍길동')        AS NULL포함;  -- NULL 반환

-- ▶ 예문 1. 직원 성과 이름 합치기
SELECT  employeeNumber
        ,firstName
        ,lastName
        ,CONCAT(firstName, ' ', lastName)       AS 전체이름
        ,CONCAT_WS(' / ', jobTitle, email)      AS 직책이메일
  FROM  employees
 ORDER
    BY  employeeNumber;

-- ▶ 예문 2. 고객 주소 합치기
SELECT  customerName
        ,CONCAT_WS(', ', addressLine1, city, country) AS 전체주소
  FROM  customers
 ORDER
    BY  customerName;

-- ▶ 예문 3. CONCAT + SUBSTRING 조합
-- 직원 이름 이니셜 만들기
SELECT  employeeNumber
        ,CONCAT(firstName, ' ', lastName)               AS 전체이름
        ,CONCAT(
            SUBSTRING(firstName, 1, 1), '.',
            SUBSTRING(lastName, 1, 1), '.'
         )                                              AS 이니셜
        ,CONCAT('[', jobTitle, '] ', email)             AS 직책이메일
  FROM  employees
 ORDER
    BY  employeeNumber;

-- ▶ 예문 4. SELF JOIN + CONCAT 조합
-- 직원과 상사 정보를 깔끔하게 출력
SELECT  CONCAT(e1.firstName, ' ', e1.lastName)  AS 직원
        ,e1.jobTitle                             AS 직원직책
        ,CONCAT(e2.firstName, ' ', e2.lastName)  AS 상사
        ,e2.jobTitle                             AS 상사직책
        ,CONCAT(
            SUBSTRING(e1.firstName, 1, 1), '.',
            SUBSTRING(e1.lastName, 1, 1), '.'
         )                                       AS 직원이니셜
  FROM  employees AS e1
  LEFT
  JOIN  employees AS e2
    ON  e1.reportsTo = e2.employeeNumber
 ORDER
    BY  e1.employeeNumber;


/************************************************************************/
/* 핵심 정리                                                              */
/************************************************************************/

-- ▶ LEFT JOIN
--   - 왼쪽 테이블 전체 유지 + 오른쪽 일치하는 데이터
--   - 일치 없으면 NULL
--   - NULL 필터링으로 미포함 데이터 추출 가능
--   - 실무에서 가장 많이 사용

-- ▶ SELF JOIN
--   - 같은 테이블을 두 번 JOIN
--   - 반드시 별칭 다르게 지정 (e1, e2)
--   - 계층 구조 / 같은 값 비교에 활용
--   - reportsTo(상사번호) → 상사 이름 찾기가 대표 예시

-- ▶ 문자열 함수
--   - UPPER/LOWER: 대소문자 변환
--   - LENGTH: 문자열 길이
--   - REPLACE: 특정 문자 치환
--   - TRIM: 공백 제거

-- ▶ SUBSTRING
--   - SUBSTRING(문자열, 시작위치, 길이)
--   - 시작위치는 1부터 시작
--   - 길이 생략 시 끝까지 추출
--   - SUBSTR과 동일

-- ▶ CONCAT
--   - CONCAT(문자열1, 문자열2, ...)
--   - NULL 포함 시 결과 NULL
--   - CONCAT_WS(구분자, ...) 로 구분자 지정 가능
--   - 여러 컬럼을 하나의 문자열로 합칠 때 사용
