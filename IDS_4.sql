-- @file IDS_4.sql
-- @brief Implementation of second task
-- @author { 
--    Martin Kubička (xkubic45), 
--    Matěj Macek (xmacek27) 
-- }
-- @date 26.3.2023

--------- Reset tables ---------
DROP TABLE Skladuje;
DROP TABLE Obsahuje;
DROP TABLE Hradi;
DROP TABLE Nakup_na_predpis;
DROP TABLE Nakup;
DROP TABLE Lekarna;
DROP TABLE Lek;
DROP TABLE Pojistovna;

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
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES ((SELECT lekarna_pk from Lekarna WHERE lekarna_nazev='Nejlepší lékárna'), (SELECT lek_pk from Lek WHERE lek_nazev='Ibuprofen'), 100);

INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='Česká pojišťovna'), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 15);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='Česká pojišťovna'), (SELECT lek_pk from Lek WHERE lek_nazev='Aspirin'), 20);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='Česká pojišťovna'), (SELECT lek_pk from Lek WHERE lek_nazev='Strepsils'), 20);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='VZP'), (SELECT lek_pk from Lek WHERE lek_nazev='Xanax'), 15);
INSERT INTO Hradi (pojistovna_pk, lek_pk, castka) VALUES ((SELECT pojistovna_pk from Pojistovna WHERE pojistovna_nazev='VZP'), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 10);

INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=59.80), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 2);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=159.60), (SELECT lek_pk from Lek WHERE lek_nazev='Paralen'), 1);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES ((SELECT nakup_pk from Nakup WHERE nakup_datum=TO_DATE('17.02.2023', 'DD.MM.YYYY') AND nakup_suma=159.60), (SELECT lek_pk from Lek WHERE lek_nazev='Aspirin'), 2);
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
    SUM(mnozstvi)
FROM
    Skladuje
    JOIN Lek ON Skladuje.lek_pk = Lek.lek_pk
GROUP BY
    lek_nazev;

-- This query selects the name of an insurance company and the average amount of money paid out by the company
SELECT
    pojistovna_nazev,
    AVG(castka)
FROM
    Hradi
    JOIN Pojistovna ON Hradi.pojistovna_pk = Pojistovna.pojistovna_pk
GROUP BY
    pojistovna_nazev;

--------- End of IDS_3.sql ---------
