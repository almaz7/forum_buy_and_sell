DROP SCHEMA PUBLIC CASCADE;
CREATE SCHEMA PUBLIC;
/*DROP TABLE Price IF EXIST;
DROP TABLE Review;
DROP TABLE Tracking;
DROP TABLE Reject;
DROP TABLE PaymentDoc;
DROP TABLE ExchangeRate;
DROP TABLE Currency;
DROP TABLE ProdOrd;
DROP TABLE Product;
DROP TABLE "Order";
DROP TABLE "User";
DROP TABLE Role;*/
SET TIME ZONE 'Europe/Moscow';
CREATE TABLE Role(
    RoleID int NOT NULL PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL
);
CREATE TABLE "User"(
    UserID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    NickName VARCHAR(100) NOT NULL UNIQUE, /*alternative*/
    RoleID int NOT NULL REFERENCES Role (RoleID) ON DELETE RESTRICT, 
    ModerID int REFERENCES "User" (UserID) ON DELETE RESTRICT,
    Password VARCHAR(100) NOT NULL,
    Age int NOT NULL CHECK (Age > 17),
    BillNum VARCHAR(100) NOT NULL CHECK (BillNum SIMILAR TO '[0-9][0-9][0-9]:::[A-Z][A-Z][a-z][a-z]::__&\^'),  -- NUMNUMNUM:::CHARCHARcharchar::ANYANY&^ 
    IfBlocked BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE Product(
    ProdID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    UserID int NOT NULL REFERENCES "User" (UserID) ON DELETE RESTRICT, 
    ProdName VARCHAR(100) NOT NULL,
    ProdDescription VARCHAR(100),
    ProdState int NOT NULL DEFAULT 0, --0 черновой, 1 выставлен, 2 снят, 3 скрыт
    ProdNumber int NOT NULL CHECK (ProdNumber >= 0)
);
CREATE TABLE "Order"(
    OrderID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    CustID int NOT NULL REFERENCES "User" (UserID) ON DELETE RESTRICT, 
    OrderState int NOT NULL --0 черновой, 1 ожидает подтверждение, 2 отказан, 3 оплачен, 4 отправлен, 5 выполнен
);
CREATE TABLE ProdOrd(
    ProdID int NOT NULL REFERENCES Product (ProdID) ON DELETE RESTRICT,
    OrderID int NOT NULL REFERENCES "Order" (OrderID) ON DELETE RESTRICT,
    PRIMARY KEY(ProdID, OrderID),
    OrderState int NOT NULL, --0 черновой, 1 ожидает подтверждение, 2 отказан, 3 оплачен, 4 отправлен, 5 выполнен
    ProdNum int NOT NULL CHECK (ProdNum >= 0)
);
CREATE TABLE Currency(
    CurID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY, 
    CurName VARCHAR(100) NOT NULL UNIQUE,
    CurDescription VARCHAR(200)
);
CREATE TABLE ExchangeRate(
    CurID int NOT NULL REFERENCES Currency (CurID) ON DELETE RESTRICT,
    RateTime DATE NOT NULL,
    PRIMARY KEY(CurID, RateTime),
    SellRate int NOT NULL,
    BuyRate int NOT NULL
);
CREATE TABLE PaymentDoc(
    DocID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    CurID int NOT NULL REFERENCES Currency (CurID) ON DELETE RESTRICT,
    OrderID int NOT NULL REFERENCES "Order" (OrderID) ON DELETE RESTRICT,
    ModerID int REFERENCES "User" (UserID) ON DELETE RESTRICT,
    Sum int NOT NULL,
    PayTime DATE NOT NULL
);
CREATE TABLE Price(
    ProdID int NOT NULL REFERENCES Product (ProdID) ON DELETE RESTRICT,
    CurID int NOT NULL REFERENCES Currency (CurID) ON DELETE RESTRICT,
    PriceTime DATE NOT NULL,
    PRIMARY KEY(ProdID, PriceTime),
    CurrentPrice int NOT NULL
);
CREATE TABLE Tracking(
    TrackID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    ProdID int NOT NULL,
    OrderID int NOT NULL,
    FOREIGN KEY (ProdID, OrderId) REFERENCES ProdOrd (ProdID, OrderID) ON DELETE RESTRICT,
    Address VARCHAR(200) NOT NULL,
    TrackTime TIMESTAMP NOT NULL,
    LastFlag BOOLEAN NOT NULL,
    PlaceNumber int NOT NULL
);
CREATE TABLE Reject(
    ProdID int NOT NULL,
    OrderID int NOT NULL,
    FOREIGN KEY (ProdID, OrderId) REFERENCES ProdOrd (ProdID, OrderID) ON DELETE RESTRICT,
    PRIMARY KEY (ProdID, OrderID),
    Reason VARCHAR(200)
);
CREATE TABLE Review(
    ReviewID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    ProdID int NOT NULL,
    OrderID int NOT NULL,
    FOREIGN KEY (ProdID, OrderId) REFERENCES ProdOrd (ProdID, OrderID) ON DELETE RESTRICT,
    Grade int NOT NULL CHECK (Grade BETWEEN 1 AND 5),
    Comment VARCHAR(200), 
    ReviewDate DATE NOT NULL,
    Reply VARCHAR(200),
    ReplyDate DATE 
);

