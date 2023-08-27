INSERT INTO ExchangeRate (curid, ratetime, sellrate, buyrate) 
VALUES (1, '2023-04-28', 27300, 27320);
INSERT INTO ExchangeRate (curid, ratetime, sellrate, buyrate) 
VALUES (2, '2023-04-28', 1800, 1810);
INSERT INTO ExchangeRate (curid, ratetime, sellrate, buyrate) 
VALUES (1, '2023-04-27', 27000, 27020);
INSERT INTO ExchangeRate (curid, ratetime, sellrate, buyrate) 
VALUES (2, '2023-04-27', 1800, 1810);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (1, 2, '2023-04-28', 1);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (1, 2, '2023-04-27', 4);
UPDATE ProdOrd SET OrderState = 4 WHERE ProdID = 5 and OrderID = 1;
UPDATE ProdOrd SET OrderState = 4 WHERE ProdID = 3 and OrderID = 1;
UPDATE ProdOrd SET OrderState = 4 WHERE (ProdID = 1 OR ProdID = 2) and OrderID = 2;
INSERT INTO Product (userid, prodname, prodnumber) 
VALUES (3, 'MACBOOK', 5);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (6, 1, CURRENT_DATE, 4);
INSERT INTO "Order" (CustID, OrderState) VALUES (3, 4);
INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(6,4,4,4);


SELECT * FROM prodord RIGHT JOIN Product ON prodord.prodid = Product.prodid LEFT JOIN "User" ON Product.userid = "User".userid ORDER BY orderid ;

--select1
WITH t1 AS (
    SELECT Prodname, Product.ProdID, max(currentprice*ER.sellrate) as max_price, min(currentprice*ER.sellrate) as min_price, 
    COALESCE(
        (SELECT currentprice*ER.sellrate FROM Price 
        LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = CURRENT_DATE
        WHERE Price.ProdID = Product.ProdID AND Price.pricetime = CURRENT_DATE
    ), -1) as current_price,
    COALESCE(
        (SELECT sum(PO.ProdNum) FROM ProdOrd PO WHERE PO.prodid = Product.prodid AND PO.orderstate >= 4
    ), 0) as sold_number,
    ProdNumber as prod_number,
    (
        SELECT nickname as seller_name FROM "User" WHERE UserID = Product.UserID
    )
    FROM Product 
    LEFT JOIN Price ON Price.ProdID = Product.ProdID 
    LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = Price.pricetime
    GROUP BY Product.ProdID 
) SELECT Prodname, max(max_price) as max_price, min(min_price) as min_price, max(current_price) as max_current_price, min(current_price) as min_current_price,
sum(sold_number) as sold_number, sum(prod_number) as prod_number, 
(
    SELECT t2.seller_name as max_seller_name FROM t1 t2 
    WHERE t2.sold_number = (SELECT max(sold_number) FROM t1 t3 WHERE t3.prodname = t1.prodname GROUP BY prodname) and t2.prodname = t1.prodname 
    ORDER BY t2.current_price DESC LIMIT 1
),
(
    SELECT t2.sold_number as max_sold_number FROM t1 t2 
    WHERE t2.sold_number = (SELECT max(sold_number) FROM t1 t3 WHERE t3.prodname = t1.prodname GROUP BY prodname) and t2.prodname = t1.prodname LIMIT 1
)
FROM t1 GROUP BY Prodname ORDER BY sold_number DESC;


-- WITH t1 AS (
--     SELECT Prodname, Product.ProdID, max(currentprice*ER.sellrate) as max_price, min(currentprice*ER.sellrate) as min_price, 
--     COALESCE(
--         (SELECT currentprice*ER.sellrate FROM Price 
--         LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = CURRENT_DATE
--         WHERE Price.ProdID = Product.ProdID AND Price.pricetime = CURRENT_DATE
--     ), -1) as current_price,
--     COALESCE(
--         (SELECT sum(PO.ProdNum) FROM ProdOrd PO WHERE PO.prodid = Product.prodid AND PO.orderstate >= 4
--     ), 0) as sold_number,
--     ProdNumber as prod_number,
--     (
--         SELECT nickname as seller_name FROM "User" WHERE UserID = Product.UserID
--     )
--     FROM Product
--     LEFT JOIN Price ON Price.ProdID = Product.ProdID 
--     LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = Price.pricetime
--     GROUP BY Prodname, Product.ProdID 
-- ) SELECT Prodname, max_price, min_price, current_price, sold_number, prod_number, seller_name
-- FROM t1 ORDER BY sold_number DESC;


-- CREATE FUNCTION select1() RETURNS void AS $$
--     BEGIN
--         SELECT Prodname, Product.ProdID, max(currentprice*ER.sellrate) as max_price, min(currentprice*ER.sellrate) as min_price, 
--         COALESCE(
--             (SELECT currentprice*ER.sellrate FROM Price 
--             LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = CURRENT_DATE
--             WHERE Price.ProdID = Product.ProdID AND Price.pricetime = CURRENT_DATE
--         ), -1) as current_price,
--         COALESCE(
--             (SELECT sum(PO.ProdNum) FROM ProdOrd PO WHERE PO.prodid = Product.prodid AND PO.orderstate >= 4
--         ), 0) as sold_number,
--         ProdNumber as prod_number,
--         (
--             SELECT nickname as seller_name FROM "User" WHERE UserID = Product.UserID
--         )
--         FROM Product 
--         LEFT JOIN Price ON Price.ProdID = Product.ProdID 
--         LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = Price.pricetime
--         GROUP BY Prodname, Product.ProdID ORDER BY sold_number DESC, max_price DESC, min_price DESC;
--     END;
-- $$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION price_change(id INT, price_new REAL, time_new DATE) RETURNS REAL AS $$
    DECLARE
    price_old REAL;
    BEGIN
        SELECT cast(currentprice*ER.sellrate AS REAL) INTO price_old FROM Price
        LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = pricetime 
        WHERE Price.pricetime < time_new AND Price.prodid = id
        ORDER BY pricetime DESC
        LIMIT 1;
    
        RETURN (price_new-price_old)/price_old*100;
    END;
$$ LANGUAGE PLPGSQL;
--select2
SELECT P.Prodid, P.prodname, Price.curid, pricetime, currentprice, coalesce(currentprice*ER.sellrate, -1) as price_in_dollars,
coalesce((
    SELECT * FROM price_change(P.Prodid, cast(currentprice*ER.sellrate AS REAL), pricetime)
), 0) as "change_in_%",
Nickname as seller_name
FROM Price JOIN Product P ON P.prodid = Price.prodid 
LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = Price.pricetime
JOIN "User" ON "User".userid = P.userid
WHERE Price.prodid = 1
ORDER BY pricetime;



SELECT * FROM prodord RIGHT JOIN Product ON prodord.prodid = Product.prodid LEFT JOIN "User" ON Product.userid = "User".userid ORDER BY orderid ;
INSERT INTO PaymentDoc (CurID, OrderID, Sum, PayTime) VALUES (1, 1, 100, CURRENT_DATE);
INSERT INTO PaymentDoc (CurID, OrderID, Sum, PayTime) VALUES (1, 3, 100, CURRENT_DATE);

--select5
SELECT DISTINCT ON (T.prodid, T.orderid) T.prodid, T.orderid, Prodname, PO.prodnum as product_number, PO.prodnum*Price.currentprice*ER.sellrate as sum,
(
    SELECT nickname as seller_name FROM "User" U WHERE U.userid = P.userid
),
(
    SELECT nickname as customer_name FROM "Order" O 
    JOIN "User" U ON U.userid = O.custid
    WHERE O.orderid = T.orderid
), 
(
    SELECT tracktime FROM Tracking WHERE prodid = T.prodid AND orderid = T.orderid 
    ORDER BY placenumber LIMIT 1
) as first_date,
(
    SELECT tracktime FROM Tracking WHERE prodid = T.prodid AND orderid = T.orderid 
    ORDER BY placenumber DESC LIMIT 1
) as last_date,
(
    SELECT address FROM Tracking WHERE prodid = T.prodid AND orderid = T.orderid 
    ORDER BY placenumber DESC LIMIT 1
) as last_address,
(
    SELECT (EXTRACT(EPOCH FROM (now() - (SELECT tracktime FROM Tracking WHERE prodid = T.prodid AND orderid = T.orderid 
    ORDER BY placenumber LIMIT 1)))/3600)::int
) as hours_in_delivery
FROM Tracking T
JOIN Product P ON P.prodid = T.prodid
JOIN ProdOrd PO ON PO.orderid = T.orderid AND T.prodid = PO.prodid
LEFT JOIN Price ON Price.ProdID = P.ProdID AND 
    Price.pricetime = (SELECT paytime FROM paymentdoc PD WHERE PD.orderid = T.orderid ORDER BY paytime DESC LIMIT 1)
LEFT JOIN ExchangeRate AS ER ON ER.curid = Price.curid AND ER.ratetime = Price.pricetime
WHERE (T.prodid, T.orderid) NOT IN (
    SELECT prodid, orderid FROM Tracking WHERE lastflag = TRUE
); 



-------------------------
CREATE OR REPLACE FUNCTION ER_count(id1 INT, id2 INT, rate_date DATE) RETURNS REAL AS $$
    DECLARE
    sellrate1 REAL;
    buyrate2 REAL;
    BEGIN
        SELECT cast(sellrate as REAL) INTO sellrate1 FROM ExchangeRate WHERE curid = id1 AND ratetime = rate_date;
        SELECT cast(buyrate as REAL) INTO buyrate2 FROM ExchangeRate WHERE curid = id2 AND ratetime = rate_date;
        RETURN sellrate1/buyrate2;
    END;
$$ LANGUAGE PLPGSQL;

-- SELECT curname, ER.curid, ER_count(C.curid, ER.curid, CURRENT_DATE) as rate FROM Currency C LEFT JOIN ExchangeRate ER ON ER.ratetime = CURRENT_DATE;
CREATE EXTENSION IF NOT EXISTS tablefunc;
--select7
SELECT * FROM 
crosstab('SELECT curname, ER.curid, ER_count(C.curid, ER.curid, CURRENT_DATE) as rate FROM Currency C LEFT JOIN ExchangeRate ER ON ER.ratetime = CURRENT_DATE ORDER BY 1, 2')
as ct(curname varchar(100), Bitcoin REAL, Etherium REAL);

SELECT curname, ER.curid, ER_count(C.curid, ER.curid, CURRENT_DATE) as rate FROM Currency C LEFT JOIN ExchangeRate ER ON ER.ratetime = CURRENT_DATE ORDER BY 1, 2;
---------------------------------
UPDATE ProdOrd SET orderstate = 5;
INSERT INTO Review (prodid, orderid, grade, reviewdate)
VALUES(5, 1, 4, CURRENT_DATE);
INSERT INTO Review (prodid, orderid, grade, reviewdate)
VALUES(3, 1, 2, CURRENT_DATE);
INSERT INTO Review (prodid, orderid, grade, reviewdate)
VALUES(1, 2, 5, CURRENT_DATE);
INSERT INTO Review (prodid, orderid, grade, reviewdate)
VALUES(2, 2, 1, CURRENT_DATE);
INSERT INTO Review (prodid, orderid, grade, reviewdate)
VALUES(3, 3, 5, CURRENT_DATE);
INSERT INTO Review (prodid, orderid, grade, reviewdate)
VALUES(6, 4, 3, CURRENT_DATE);
SELECT * FROM prodord RIGHT JOIN Product ON prodord.prodid = Product.prodid LEFT JOIN "User" ON Product.userid = "User".userid ORDER BY orderid ;



-- select6
EXPLAIN ANALYZE
SELECT ProdID, Prodname, 
(SELECT pricetime FROM Price WHERE Price.prodid = Product.prodid ORDER BY pricetime LIMIT 1) as appear_date,
(SELECT count(*) FROM (SELECT DISTINCT ON (custid) * FROM ProdOrd PO JOIN "Order" O USING (orderid) WHERE PO.prodid = Product.prodid) V) as customers_count,
COALESCE(
    (SELECT sum(PO.ProdNum) FROM ProdOrd PO WHERE PO.prodid = Product.prodid AND PO.orderstate >= 4
), 0) as sold_number,
(SELECT count(grade) FROM Review R WHERE R.prodid = Product.prodid AND grade = 1) as "1",
(SELECT count(grade) FROM Review R WHERE R.prodid = Product.prodid AND grade = 2) as "2",
(SELECT count(grade) FROM Review R WHERE R.prodid = Product.prodid AND grade = 3) as "3",
(SELECT count(grade) FROM Review R WHERE R.prodid = Product.prodid AND grade = 4) as "4",
(SELECT count(grade) FROM Review R WHERE R.prodid = Product.prodid AND grade = 5) as "5",
(SELECT avg(grade)::real FROM Review R WHERE R.prodid = Product.prodid) as avg_grade,
(WITH tmp AS (SELECT grade, ROW_NUMBER() OVER (ORDER BY grade) as rn, count(grade) OVER() as cnt FROM Review R WHERE R.prodid = Product.prodid)
    SELECT grade FROM tmp WHERE rn = cnt/2 + 1) as median_grade
FROM Product ORDER BY prodid;


EXPLAIN ANALYZE
WITH T AS (SELECT ProdID, Prodname, 
    COALESCE(CASE grade WHEN 1 THEN count(grade) END , 0) as "1",
    COALESCE(CASE grade WHEN 2 THEN count(grade) END , 0) as "2",
    COALESCE(CASE grade WHEN 3 THEN count(grade) END , 0) as "3",
    COALESCE(CASE grade WHEN 4 THEN count(grade) END , 0) as "4",
    COALESCE(CASE grade WHEN 5 THEN count(grade) END , 0) as "5"
    FROM Product LEFT JOIN Review R USING (prodid) GROUP BY prodid, prodname, grade
    )
SELECT  ProdID, Prodname, 
(SELECT pricetime FROM Price WHERE Price.prodid = T.prodid ORDER BY pricetime LIMIT 1) as appear_date,
(SELECT count(*) FROM (SELECT DISTINCT ON (custid) * FROM ProdOrd PO JOIN "Order" O USING (orderid) WHERE PO.prodid = T.prodid) V) as customers_count,
COALESCE(
    (SELECT sum(PO.ProdNum) FROM ProdOrd PO WHERE PO.prodid = T.prodid AND PO.orderstate >= 4
), 0) as sold_number,
sum("1") as "1", sum("2") as "2", sum("3") as "3", sum("4") as "4", sum("5") as "5",
-- (sum("1") + sum("2")*2 + sum("3")*3 + sum("4")*4 + sum("5")*5)/(sum("1") + sum("2") + sum("3") + sum("4") + sum("5"))::real as avg_grade,
(SELECT avg(grade)::real FROM Review R WHERE R.prodid = T.prodid) as avg_grade,
(WITH tmp AS (SELECT grade, ROW_NUMBER() OVER (ORDER BY grade) as rn, count(grade) OVER() as cnt FROM Review R WHERE R.prodid = T.prodid)
        SELECT grade FROM tmp WHERE rn = cnt/2 + 1) as median_grade
FROM T GROUP BY prodid, prodname ORDER BY prodid;


do $$
begin
for r in 1..100 loop
INSERT INTO "User" (NickName, RoleID, Password, Age, BillNum)
VALUES (random()::text, 2, random()::text, 20, '777:::URra::77&^');
end loop;
end;
$$;


INSERT INTO Product (userid, prodname, prodnumber) VALUES (generate_series(1,100), md5(random()::TEXT), trunc(random()*100));
INSERT INTO Price (prodid, curid, pricetime, currentprice) SELECT id, 1, CURRENT_DATE, 12 FROM generate_series(10, 99) as id;
INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(generate_series(10, 100),trunc(random()*4+1),4,1);

INSERT INTO Review (prodid, orderid, grade, reviewdate)
SELECT prodid, orderid, trunc(random()*5+1), CURRENT_DATE FROM prodord;