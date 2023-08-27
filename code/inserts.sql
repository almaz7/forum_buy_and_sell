INSERT INTO Role VALUES(0, 'User');
INSERT INTO Role VALUES(1, 'Moderator');
INSERT INTO Role VALUES(2, 'Administrator');

INSERT INTO "User" (NickName, RoleID, Password, Age, BillNum, IfBlocked)
VALUES ('Ivan', 0, 'ergasd', 18, '123:::DFad::go&^', FALSE);
INSERT INTO "User" (NickName, RoleID, Password, Age, BillNum)
VALUES ('Misha', 0, 'sadsdsa', 20, '333:::AHha::12&^');
INSERT INTO "User" (NickName, RoleID, Password, Age, BillNum)
VALUES ('Almaz', 2, 'almaz_rulid', 20, '777:::URra::77&^');
INSERT INTO "User" (NickName, RoleID, Password, Age, BillNum)
VALUES ('Mark', 1, 'mark_hop', 21, '000:::MArk::am&^');

INSERT INTO Product (userid, prodname, prodnumber) 
VALUES (1, 'IPHONE 13', 10);
INSERT INTO Product (userid, prodname, prodnumber) 
VALUES (1, 'XIAOMI POCO', 25);
INSERT INTO Product (userid, prodname, prodnumber) 
VALUES (2, 'MACBOOK', 5);
INSERT INTO Product (userid, prodname, prodnumber) 
VALUES (2, 'APPLE WATCH', 12);
INSERT INTO Product (userid, prodname, prodnumber) 
VALUES (3, 'BMW M2', 2);

INSERT INTO "Order" (CustID, OrderState) VALUES (1, 0);
INSERT INTO "Order" (CustID, OrderState) VALUES (2, 0);
INSERT INTO "Order" (CustID, OrderState) VALUES (3, 1);

INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(1,2,0,3);
INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(2,2,0,10);
INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(5,1,0,1);
INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(3,1,0,2);
INSERT INTO ProdOrd (ProdID, OrderID, OrderState, ProdNum) 
VALUES(3,3,1,1);

INSERT INTO Currency (curname) VALUES ('Bitcoin');
INSERT INTO Currency (curname) VALUES ('Ethereum');

INSERT INTO ExchangeRate (curid, ratetime, sellrate, buyrate) 
VALUES (1, CURRENT_DATE, 27320, 27350);
INSERT INTO ExchangeRate (curid, ratetime, sellrate, buyrate) 
VALUES (2, CURRENT_DATE, 1835, 1840);

INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (1, 2, CURRENT_DATE, 2);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (2, 2, CURRENT_DATE, 1);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (3, 1, CURRENT_DATE, 3);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (4, 1, CURRENT_DATE, 1);
INSERT INTO Price (prodid, curid, pricetime, currentprice)
VALUES (5, 1, CURRENT_DATE, 17);

INSERT INTO PaymentDoc (CurID, OrderID, Sum, PayTime) VALUES (1, 2, 100, CURRENT_DATE);
--INSERT INTO PaymentDoc (CurID, OrderID, Sum, PayTime) VALUES (1, 1, 16, CURRENT_DATE);

--UPDATE  product SET prodnumber = 5 WHERE prodid = 3;
--UPDATE ProdOrd SET OrderState = 4, ProdNum = 1 WHERE orderid = 1 AND prodid = 3; 
SELECT * FROM sum_prodord(1);
SELECT * FROM sum_pay_doc(2);

--INSERT INTO "Order" (CustID, OrderState) VALUES (2, 0);
--INSERT INTO PaymentDoc (CurID, OrderID, Sum, PayTime) VALUES (1, 5, 1, CURRENT_DATE);