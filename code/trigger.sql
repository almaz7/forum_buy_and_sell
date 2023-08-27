CREATE OR REPLACE FUNCTION sum_pay_doc(id INT) RETURNS INT AS $$
    DECLARE
        s INT := 0;
        doc_view RECORD;
    BEGIN
        FOR doc_view IN
            SELECT Sum, SellRate
            FROM PaymentDoc PD 
            JOIN ExchangeRate E ON PD.CurID = E.CurID AND E.ratetime = CURRENT_DATE 
            WHERE OrderID = id
        LOOP
            s := s + doc_view.SellRate*doc_view.Sum;
        END LOOP;
        RETURN s;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION sum_prodord(id INT) RETURNS INT AS $$
    DECLARE
        s INT := 0;
        prod_view RECORD;
    BEGIN
        FOR prod_view IN
            SELECT ProdNum, CurrentPrice, SellRate FROM ProdOrd PO 
            JOIN Price P ON PO.prodid = P.prodid 
            JOIN ExchangeRate E ON E.curid = P.curid AND E.ratetime = CURRENT_DATE 
            WHERE OrderID = id
        LOOP
            s := s + prod_view.ProdNum*prod_view.CurrentPrice*prod_view.SellRate;
        END LOOP;
        RETURN s;
    END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION insert_pay_doc() RETURNS TRIGGER AS $insert_pay_doc$
    DECLARE
    SR INT;
    BEGIN
        IF (SELECT OrderState FROM "Order" WHERE OrderID = NEW.OrderID) >= 3 THEN 
            RAISE EXCEPTION 'Order is already paid';
        END IF;
        IF (SELECT OrderState FROM "Order" WHERE OrderID = NEW.OrderID) = 2 THEN 
            RAISE EXCEPTION 'Order is refused';
        END IF;
        SELECT SellRate INTO SR FROM ExchangeRate E WHERE NEW.CurID = E.CurID AND E.ratetime = CURRENT_DATE;
        IF (sum_pay_doc(NEW.OrderID) + NEW.Sum*SR) >= sum_prodord(NEW.OrderID) THEN 
            UPDATE "Order" SET OrderState = 3 WHERE OrderID = NEW.OrderID;
            UPDATE ProdOrd SET OrderState = 3 WHERE OrderID = NEW.OrderID;
        END IF;
        RETURN NEW;
    END;
$insert_pay_doc$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER insert_pay_doc BEFORE INSERT OR UPDATE ON PaymentDoc
    FOR EACH ROW EXECUTE FUNCTION insert_pay_doc();

CREATE OR REPLACE FUNCTION insert_update_prodord() RETURNS TRIGGER AS $insert_update_prodord$
    DECLARE
    PN INT;
    PS INT;
    BEGIN
        SELECT ProdNumber, ProdState INTO PN, PS FROM Product WHERE ProdID = NEW.ProdID;
        IF (PS = 2) OR (PS = 3) THEN 
            RAISE EXCEPTION 'Unable to insert or update ProdOrd: product is blocked or removed from sale';
        END IF;
        IF NEW.OrderState = 4 THEN 
            IF (OLD.OrderState = 4 OR OLD.OrderState = 5) THEN 
                RETURN NEW;
            END IF;
            IF NEW.ProdNum > PN THEN
                RAISE EXCEPTION 'Unable to insert or update ProdOrd: count of products in order is more than seller has';
            ELSE
                UPDATE Product SET ProdNumber = (PN - NEW.ProdNum) WHERE ProdID = NEW.ProdID;
            END IF;
        END IF;
        RETURN NEW;
    END;
$insert_update_prodord$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER insert_update_prodord BEFORE INSERT OR UPDATE ON ProdOrd
    FOR EACH ROW EXECUTE FUNCTION insert_update_prodord();
