CREATE OR REPLACE PROCEDURE product_block(str VARCHAR(100))
LANGUAGE PLPGSQL
AS $$
    DECLARE 
    p RECORD;
    
    BEGIN
        --block products and change order's state
        FOR p IN
            SELECT ProdID, ProdName FROM Product WHERE lower(ProdName) SIMILAR TO lower(concat('%',str,'%'))
        LOOP
            DELETE FROM ProdOrd WHERE ProdID = p.ProdID AND OrderState = 0;
            DELETE FROM "Order" WHERE (SELECT COUNT(*) FROM ProdOrd WHERE ProdOrd.OrderID = "Order".OrderID) = 0;
            UPDATE ProdOrd SET OrderState = 2 WHERE ProdID = p.ProdID AND OrderState = 1;
            UPDATE "Order" SET OrderState = 2 WHERE OrderID IN (SELECT OrderID FROM ProdOrd WHERE ProdID = p.ProdID AND OrderState = 2);
            INSERT INTO Reject (OrderID, ProdID, Reason)
                SELECT OrderID, p.ProdID, concat('Product "', p.ProdName, '" in order was blocked') 
                FROM ProdOrd WHERE ProdId = p.ProdID 
                ON CONFLICT DO NOTHING;
            UPDATE Product SET ProdState = 3 WHERE ProdID = p.ProdID; --block product
        END LOOP;
        --block sellers who sell only blocked products
        UPDATE "User" SET ifblocked = TRUE WHERE userid IN 
            (SELECT userid FROM Product WHERE userid NOT IN 
                (SELECT userid FROM Product WHERE lower(ProdName) NOT SIMILAR TO lower(concat('%',str,'%'))));
    END;
$$;

SELECT * FROM prodord JOIN Product ON prodord.prodid = Product.prodid ORDER BY orderid;

-- CALL product_block('MAC');
-- CALL product_block('M');

CREATE OR REPLACE PROCEDURE insert_trackpoint(pid INT, oid INT, addr VARCHAR(200), lf BOOLEAN)
LANGUAGE PLPGSQL
AS $$
    DECLARE
    S INT;
    pnum INT;
    BEGIN
        SELECT OrderState INTO S FROM ProdOrd WHERE ProdID = pid AND OrderID = oid;
        IF S = 2 THEN
            RAISE EXCEPTION 'Unable to add trackpoint: Order is refused';
        ELSIF S = 5 THEN
            RAISE EXCEPTION 'Unable to add trackpoint: Order is done';
        ELSIF S = 3 THEN
            UPDATE ProdOrd SET OrderState = 4 WHERE ProdID = pid AND OrderID = oid;
        END IF;
        IF lf = TRUE THEN
            UPDATE ProdOrd SET OrderState = 5 WHERE ProdID = pid AND OrderID = oid; --done
        END IF;
        SELECT coalesce(max(placenumber), 0) INTO pnum FROM tracking WHERE ProdID = pid AND OrderID = oid;
        INSERT INTO Tracking (ProdID, OrderID, Address, TrackTime, LastFlag, PlaceNumber)
        VALUES (pid, oid, addr, CURRENT_TIMESTAMP, lf, pnum + 1);
    END;
$$;


CALL insert_trackpoint(2, 2, 'Neftekamsk', FALSE);
CALL insert_trackpoint(2, 2, 'Moscow', true);
--CALL insert_trackpoint(2, 2, 'Sochi', TRUE);
CALL insert_trackpoint(3, 3, 'Neftekamsk', false);
CALL insert_trackpoint(3, 1, 'Sochi', false);
CALL insert_trackpoint(3, 1, 'Moscow', false);