-- @file IDS_4.sql
-- @brief Implementation of second task
-- @author { 
--    Martin Kubička (xkubic45), 
--    Matěj Macek (xmacek27) 
-- }
-- @date 1.5.2023

--------- Reset tables ---------
DROP TABLE Skladuje;
DROP TABLE Obsahuje;
DROP TABLE Hradi;
DROP TABLE Nakup_na_predpis;
DROP TABLE Nakup;
DROP TABLE Lekarna;
DROP TABLE Lek;
DROP TABLE Pojistovna;
DROP MATERIALIZED VIEW xmacek27_view;

--------- Entities ---------
CREATE TABLE Lekarna (
    lekarna_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lekarna_nazev VARCHAR2(50) NOT NULL,
    lekarna_jmeno_majitele VARCHAR2(50) NOT NULL,
    lekarna_ulice VARCHAR2(50) NOT NULL,
    lekarna_psc NUMBER(10) NOT NULL,
    lekarna_mesto VARCHAR2(50) NOT NULL,
    lekarna_stat VARCHAR2(50) NOT NULL
);

CREATE TABLE Nakup (
    nakup_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nakup_datum DATE NOT NULL,
    nakup_suma NUMBER(10, 2) NOT NULL,
    lekarna_pk NUMBER NOT NULL, -- relationship 0..* to 1
    CONSTRAINT byl_proveden_ck_lekarna
        FOREIGN KEY (lekarna_pk)
        REFERENCES Lekarna (lekarna_pk)
);

-- Implementation of generalization relation of Nakup entity
-- When inserting it needs nakup_pk which is primary key of parent Nakup entity
-- Also it has special atribute rodne_cislo which needs to be in special format
CREATE TABLE Nakup_na_predpis (
    nakup_pk NUMBER NOT NULL PRIMARY KEY,
    rodne_cislo VARCHAR2(11) NOT NULL CHECK(REGEXP_LIKE(rodne_cislo, '^[0-9]{6}\/?[0-9]{3,4}$')),
    CONSTRAINT nakup_na_predpis_ck
        FOREIGN KEY (nakup_pk)
        REFERENCES Nakup (nakup_pk)
);


CREATE TABLE Lek (
    lek_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lek_nazev VARCHAR2(50) NOT NULL,
    lek_cena NUMBER(10, 2) NOT NULL,
    lek_na_predpis  NUMBER(1) NOT NULL CHECK(REGEXP_LIKE(lek_na_predpis, '^(0|1)$'))
);

CREATE TABLE Pojistovna (
    pojistovna_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pojistovna_nazev VARCHAR2(50) NOT NULL,
    pojistovna_sidlo VARCHAR2(50) NOT NULL
);

--------- Relations ---------
CREATE TABLE Obsahuje (
    obsahuje_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nakup_pk NUMBER NOT NULL,
    lek_pk NUMBER NOT NULL,
    mnozstvi NUMBER(5) NOT NULL,
    CONSTRAINT obsahuje_ck_lek
        FOREIGN KEY (lek_pk)
        REFERENCES Lek (lek_pk),
    CONSTRAINT obsahuje_ck_nakup
        FOREIGN KEY (nakup_pk)
        REFERENCES Nakup (nakup_pk)
);

CREATE TABLE Skladuje (
    skladuje_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lekarna_pk NUMBER NOT NULL,
    lek_pk NUMBER NOT NULL,
    mnozstvi NUMBER(10) NOT NULL,
    CONSTRAINT skladuje_ck_lekarna
        FOREIGN KEY (lekarna_pk)
        REFERENCES Lekarna (lekarna_pk),
    CONSTRAINT skladuje_ck_lek
        FOREIGN KEY (lek_pk)
        REFERENCES Lek (lek_pk)
);

CREATE TABLE Hradi (
    hradi_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pojistovna_pk NUMBER NOT NULL,
    lek_pk NUMBER NOT NULL,
    castka NUMBER(10, 2) NOT NULL,
    CONSTRAINT hradi_ck_pojistovna
        FOREIGN KEY (pojistovna_pk)
        REFERENCES Pojistovna (pojistovna_pk),
    CONSTRAINT hradi_ck_lek
        FOREIGN KEY (lek_pk)
        REFERENCES Lek (lek_pk)
);

--------- Triggers ---------

-- The purchase does not contain or exceed the amount of a drug that is not in stock.
CREATE OR REPLACE TRIGGER lek_na_sklade BEFORE
    INSERT OR UPDATE OF obsahuje_pk, mnozstvi ON Obsahuje
    FOR EACH ROW
DECLARE
    mnozstvi_leku_na_sklade NUMBER;
BEGIN
    SELECT mnozstvi
    INTO
        mnozstvi_leku_na_sklade
    FROM
        Skladuje
    WHERE
        lekarna_pk = (SELECT lekarna_pk FROM Nakup CROSS JOIN Lek WHERE nakup_pk = :NEW.nakup_pk AND lek_pk = :NEW.lek_pk)
        AND lek_pk = :NEW.lek_pk;

    IF (:NEW.mnozstvi > mnozstvi_leku_na_sklade) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Není dostatečné množství léku na skladě.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Lekárna neobsahuje daný lék.');
END;
/
    
-- The insurance company covers the drug that exists.
CREATE OR REPLACE TRIGGER existuje_lek BEFORE
    INSERT OR UPDATE OF lek_pk ON Hradi
    FOR EACH ROW
DECLARE
    existuje_lek_num NUMBER;
BEGIN
    SELECT COUNT(lek_pk)
    INTO
        existuje_lek_num
    FROM
        Lek
    WHERE
        lek_pk = :NEW.lek_pk;

    IF (existuje_lek_num = 0) THEN
        RAISE_APPLICATION_ERROR(-20000, 'Pokus o hrazení léku, který neexistuje.');
    END IF;
END;
/   

--------- Procedures ---------
-- Procedure shows the purchase details for the given purchase ID
CREATE OR REPLACE PROCEDURE zobrazit_nakup(
    p_nakup_pk IN Nakup.nakup_pk%TYPE
) AS
  -- Cursor to retrieve medication details for the given purchase ID
  CURSOR c_obsahuje IS
    SELECT L.lek_nazev, O.mnozstvi
    FROM Obsahuje O
    INNER JOIN Lek L ON O.lek_pk = L.lek_pk
    WHERE O.nakup_pk = p_nakup_pk;
  -- Variable to hold the total purchase amount for the given purchase ID
  v_nakup_suma Nakup.nakup_suma%TYPE;
  -- Variables to hold medication name and quantity for each purchase item
  v_lek_nazev Lek.lek_nazev%TYPE;
  v_mnozstvi Obsahuje.mnozstvi%TYPE;
BEGIN
  -- Retrieve the total purchase amount for the given purchase ID
  SELECT nakup_suma INTO v_nakup_suma
  FROM Nakup
  WHERE nakup_pk = p_nakup_pk;

  -- Print the total purchase amount for the given purchase ID
  DBMS_OUTPUT.PUT_LINE('Purchase with ID ' || p_nakup_pk || ' has a total amount of ' || v_nakup_suma);

  -- Open the cursor to retrieve medication details for the given purchase ID
  OPEN c_obsahuje;
  -- Loop through all medication items for the given purchase ID
  LOOP
    -- Fetch the next medication name and quantity
    FETCH c_obsahuje INTO v_lek_nazev, v_mnozstvi;
    -- Exit the loop if no more medication items are found
    EXIT WHEN c_obsahuje%NOTFOUND;
    -- Print the medication name and quantity for the current purchase item
    DBMS_OUTPUT.PUT_LINE('  ' || v_lek_nazev || ': ' || v_mnozstvi);
  END LOOP;
  -- Close the cursor for the medication details
  CLOSE c_obsahuje;

EXCEPTION
  -- Handle the case where no purchase with the given purchase ID is found
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Purchase with ID ' || p_nakup_pk || ' not found');
  -- Handle any other exceptions that may occur
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error occurred while retrieving purchase information');
    RAISE;
END;
/

-- Procedure which calculates average price for medicine in the city passed as a argument.
CREATE OR REPLACE PROCEDURE prumerna_cena (param_mesto IN Lekarna.lekarna_mesto%TYPE) 
IS 
    pocet_leku NUMBER;
    suma_spolu NUMBER;
    
    CURSOR cursor_lekarna IS
        SELECT DISTINCT lek_pk, lek_cena
        FROM Lekarna NATURAL JOIN SKLADUJE NATURAL JOIN Lek
        WHERE lekarna_mesto = param_mesto;

    row_lek cursor_lekarna%ROWTYPE;
BEGIN
    pocet_leku := 0;
    suma_spolu := 0;

    OPEN cursor_lekarna;
    LOOP
        FETCH cursor_lekarna INTO row_lek;
        EXIT WHEN cursor_lekarna%NOTFOUND;
        pocet_leku := pocet_leku + 1;
        suma_spolu := suma_spolu + row_lek.lek_cena;
    END LOOP;
    CLOSE cursor_lekarna;

    DBMS_OUTPUT.PUT_LINE('Průměrná cena za lék: ' || suma_spolu/pocet_leku);

    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            DBMS_OUTPUT.PUT_LINE('Neexistují žádné léky ve městě ' || param_mesto || '.');
END;
/

--------- Example data ---------

INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Paralen', 29.90, 0);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Aspirin', 39.90, 0);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Strepsils', 69.90, 0);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Ibuprofen', 49.90, 1);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Xanax', 159.90, 1);

INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('VZP', 'Praha 2');
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Česká pojišťovna', 'Praha 1');
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Uniqa', 'Brno');
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Zdravotní pojišťovna ministerstva vnitra', 'Praha 3');
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Maxima pojišťovna', 'Bratislava');

INSERT INTO Lekarna (lekarna_nazev, lekarna_jmeno_majitele, lekarna_ulice, lekarna_psc, lekarna_mesto, lekarna_stat) VALUES ('Vaše lékárna', 'Matěj Macek', 'Kolejní 2', 61200, 'Brno', 'Česká republika');
INSERT INTO Lekarna (lekarna_nazev, lekarna_jmeno_majitele, lekarna_ulice, lekarna_psc, lekarna_mesto, lekarna_stat) VALUES ('Nejlepší lékárna', 'Martin Kubička', 'Božetěchova 2', 61200, 'Brno', 'Česká republika');

INSERT INTO Nakup (nakup_datum, nakup_suma, lekarna_pk) VALUES (TO_DATE('17.02.2023', 'DD.MM.YYYY'), 59.80, (SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Vaše lékárna'));
INSERT INTO Nakup (nakup_datum, nakup_suma, lekarna_pk) VALUES (TO_DATE('17.02.2023', 'DD.MM.YYYY'), 159.60, (SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Nejlepší lékárna')); 
INSERT INTO Nakup (nakup_datum, nakup_suma, lekarna_pk) VALUES (TO_DATE('19.02.2023', 'DD.MM.YYYY'), 369.6, (SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Nejlepší lékárna'));

INSERT INTO Nakup_na_predpis (nakup_pk, rodne_cislo) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=159.60), '020220/1234');
INSERT INTO Nakup_na_predpis (nakup_pk, rodne_cislo) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('19.02.2023', 'DD.MM.YYYY') AND nakup_suma=369.60), '981512111');

INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Vaše lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 50);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Vaše lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Aspirin'), 30);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Vaše lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Ibuprofen'), 10);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Nejlepší lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Strepsils'), 20);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Nejlepší lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 30);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Nejlepší lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Ibuprofen'), 100);

INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='Česká pojišťovna'), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 15);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='Česká pojišťovna'), (SELECT lek_pk from Lek WHERE lek_nazev='Aspirin'), 20);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='Česká pojišťovna'), (SELECT lek_pk from Lek WHERE lek_nazev='Strepsils'), 20);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='VZP'), (SELECT lek_pk from Lek WHERE lek_nazev='Xanax'), 15);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='VZP'), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 10);

INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=59.80), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 2);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=159.60), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 1);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=159.60), (SELECT lek_pk from Lek WHERE lek_nazev='Ibuprofen'), 1);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('19.02.2023', 'DD.MM.YYYY') AND nakup_suma=369.60), (SELECT lek_pk from Lek WHERE lek_nazev='Strepsils'), 3);

---------  SELECTS ---------

-- Find all pharmacies that store Paralen
SELECT
    lekarna_nazev,
    lekarna_ulice,
    lekarna_mesto,
    lekarna_psc,
    lekarna_stat
FROM
    Lekarna NATURAL
    JOIN Skladuje
WHERE
    lek_pk =(
        SELECT
            lek_pk
        from
            Lek
        WHERE
            lek_nazev = 'Paralen'
    );

-- Find all medicines that are covered by Česká pojišťovna
SELECT
    lek_nazev
FROM
    Lek NATURAL
    JOIN Hradi
WHERE
    pojistovna_pk =(
        SELECT
            pojistovna_pk
        from
            Pojistovna
        WHERE
            pojistovna_nazev = 'Česká pojišťovna'
    );

-- Find all medicines that stored by any of pharmacies
SELECT
    lek_nazev
FROM
    lek
WHERE
    EXISTS (
        SELECT
            lekarna_pk
        FROM
            Skladuje
        WHERE
            lek_pk = Lek.lek_pk
    );

-- Find all purchases that contain Aspirin.
SELECT
    nakup_datum,
    nakup_suma
FROM
    Nakup
WHERE
    nakup_pk IN (
        SELECT
            nakup_pk
        FROM
            Obsahuje NATURAL
            JOIN Lek
        WHERE
            lek_nazev = 'Aspirin'
    );
    
-- This query selects the name of a medicine, the name of the pharmacy where it is stored, and the quantity of the medicine in stock
SELECT
    lek_nazev,
    lekarna_nazev,
    mnozstvi
FROM
    Skladuje
    JOIN Lek ON Skladuje.lek_pk = Lek.lek_pk
    JOIN Lekarna ON Skladuje.lekarna_pk = Lekarna.lekarna_pk;

-- This query selects the name of a medicine and the total quantity of the medicine in stock across all pharmacies
SELECT
    lek_nazev,
    SUM(mnozstvi) AS mnozstvi_spolu
FROM
    Skladuje
    JOIN Lek ON Skladuje.lek_pk = Lek.lek_pk
GROUP BY
    lek_nazev;

-- This query selects the name of an insurance company and the average amount of money paid out by the company
SELECT
    pojistovna_nazev,
    AVG(castka) AS prumer_hrazeni
FROM
    Hradi
    JOIN Pojistovna ON Hradi.pojistovna_pk = Pojistovna.pojistovna_pk 
GROUP BY pojistovna_nazev;

-- SELECT WITH 
-- The query obtains the number of drugs that have been purchased, divided into two categories - "prescription" and "non-prescription".
WITH 
    predpis AS (
        SELECT COUNT(nakup_pk) AS pocet_predpisu
        FROM Nakup_na_predpis
    ),
    bez_predpisu AS (
        SELECT COUNT(nakup_pk) AS pocet_bez_predpisu
        FROM Nakup
        WHERE nakup_pk NOT IN (SELECT nakup_pk FROM Nakup_na_predpis)
    )
SELECT 
    pocet_predpisu, 
    pocet_bez_predpisu,
    CASE
        WHEN pocet_predpisu IS NULL THEN pocet_bez_predpisu
        WHEN pocet_bez_predpisu IS NULL THEN pocet_predpisu
        ELSE 0
    END AS chybejici_data
FROM 
    predpis, bez_predpisu;

--------- Privileges ---------
GRANT ALL ON Lekarna TO xmacek27;
GRANT ALL ON Nakup TO xmacek27;
GRANT ALL ON Nakup_na_predpis TO xmacek27;
GRANT ALL ON Lek TO xmacek27;
GRANT ALL ON Pojistovna TO xmacek27;
GRANT ALL ON Obsahuje TO xmacek27;
GRANT ALL ON Skladuje TO xmacek27;
GRANT ALL ON Hradi TO xmacek27;

GRANT EXECUTE ON prumerna_cena TO xmacek27;
GRANT EXECUTE ON zobrazit_nakup TO xmacek27;

--------- View ---------
CREATE MATERIALIZED VIEW xmacek27_view AS
SELECT
    lekarna_nazev,
    lekarna_ulice,
    lekarna_psc,
    lekarna_mesto,
    lekarna_stat
FROM 
    Lekarna
WHERE
    lekarna_mesto = 'Brno';

GRANT ALL ON xmacek27_view TO xmacek27;

-- Print view
SELECT * FROM xmacek27_view;

-- Update value in view
 UPDATE Lekarna
 SET 
    lekarna_nazev = 'Přírodní lékárna'
 WHERE 
    lekarna_nazev = 'Vaše lékárna';

BEGIN
    DBMS_MVIEW.REFRESH('xmacek27_view');
END;
/

-- Print updated view
SELECT * FROM xmacek27_view;

-- Calling procedures
SET SERVEROUTPUT ON;
EXEC prumerna_cena ('Brno');
EXEC zobrazit_nakup(1);

--------- EXPLAIN PLAN ---------

-- EXPLAIN PLAN without index
EXPLAIN PLAN FOR 
SELECT
    lekarna_nazev,
    SUM(nakup_suma) AS suma
FROM
    Lekarna NATURAL
    JOIN Nakup
GROUP BY
    lekarna_nazev
HAVING
    SUM(nakup_suma) > 100;

-- this will show the plan
SELECT * FROM TABLE(dbms_xplan.display); 
    
-- creating index 
CREATE UNIQUE INDEX ind ON Lekarna(lekarna_nazev);

-- EXPLAIN PLAN with index
EXPLAIN PLAN FOR
SELECT
    lekarna_nazev,
    SUM(nakup_suma) AS suma
FROM
    Lekarna NATURAL
    JOIN Nakup
GROUP BY
    lekarna_nazev
HAVING
    SUM(nakup_suma) > 100;

-- this will show the plan
SELECT * FROM TABLE(dbms_xplan.display);

DROP INDEX ind;

--------- End of IDS_4.sql ---------
