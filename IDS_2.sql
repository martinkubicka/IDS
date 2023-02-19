-- @file IDS_2.sql
-- @brief Implementation of second task
-- @author { 
--    Martin Kubička (xkubic45), 
--    Matěj Macek (xmacek27) 
-- }
-- @date 26.3.2023

--------- Reset tables ---------
DROP TABLE Lek;
DROP TABLE Pojistovna;
DROP TABLE Skladuje;
DROP TABLE Hradi;
DROP TABLE Nakup;
DROP TABLE Nakup_na_predpis;
DROP TABLE Lekarna;
DROP TABLE Byl_proveden;
DROP TABLE Obsahuje;

--------- Entities ---------
CREATE TABLE Nakup (
    nakup_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nakup_datum DATE NOT NULL,
    nakup_suma NUMBER(10) NOT NULL
);

-- Implementation of generalization relation of Nakup entity
-- When inserting it needs nakup_pk which is primary key of parent Nakup entity
-- Also it has special atribute rodne_cislo which needs to be in special format
CREATE TABLE Nakup_na_predpis (
    nakup_pk NUMBER NOT NULL PRIMARY KEY,
    rodne_cislo NUMBER NOT NULL CHECK(REGEXP_LIKE(rodne_cislo, '^[0-9]{6}\/?[0-9]{3,4}$')),
    CONSTRAINT nakup_na_predpis_ck
        FOREIGN KEY (nakup_pk)
        REFERENCES Nakup (nakup_pk)
);

CREATE TABLE Lekarna (
    lekarna_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lekarna_nazev VARCHAR2(50) NOT NULL,
    lekarna_jmeno_majitele VARCHAR2(50) NOT NULL,
    lekarna_adresa VARCHAR2(100) NOT NULL
);

CREATE TABLE Lek (
    lek_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lek_nazev VARCHAR2(50) NOT NULL,
    lek_cena NUMBER(10) NOT NULL,
    lek_na_predpis  NUMBER(1) NOT NULL
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

CREATE TABLE Byl_proveden (
    nakup_pk NUMBER NOT NULL,
    lekarna_pk NUMBER NOT NULL,
    CONSTRAINT byl_proveden_ck_nakup
        FOREIGN KEY (nakup_pk)
        REFERENCES Nakup (nakup_pk),
    CONSTRAINT byl_proveden_ck_lekarna
        FOREIGN KEY (lekarna_pk)
        REFERENCES Lekarna (lekarna_pk)
);

CREATE TABLE Skladuje (
    lekarna_pk NUMBER NOT NULL,
    lek_pk NUMBER NOT NULL,
    mnozstvi NUMBER(10) NOT NULL,
    CONSTRAINT skladuje_pk_lekarna
        FOREIGN KEY (lekarna_pk)
        REFERENCES Lekarna (lekarna_pk),
    CONSTRAINT skladuje_pk_lek
        FOREIGN KEY (lek_pk)
        REFERENCES Lek (lek_pk)    
);

CREATE TABLE Hradi (
    lek_pk NUMBER NOT NULL,
    pojistovna_pk NUMBER NOT NULL,
    castka NUMBER(10) NOT NULL,
    CONSTRAINT hradi_pk_lek
        FOREIGN KEY (lek_pk)
        REFERENCES Lek (lek_pk),
    CONSTRAINT hradi_pk_pojistovna
        FOREIGN KEY (pojistovna_pk)
        REFERENCES Pojistovna (pojistovna_pk)
);

--------- Example data ---------
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Paralen', 29.90, 0);
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('VZP', 'Praha 2');
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES (1, 1, 50);
INSERT INTO Hradi (lek_pk, pojistovna_pk,castka) VALUES (1, 1, 10);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Aspirin', 39.90, 0);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Ibuprofen', 49.90, 1);
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Česká pojišťovna', 'Praha 1');
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Uniqa', 'Brno');
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES (1, 2, 30);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES (2, 3, 20);
INSERT INTO Hradi (lek_pk, pojistovna_pk,castka) VALUES (2, 2, 20);
INSERT INTO Hradi (lek_pk, pojistovna_pk,castka) VALUES (3, 1, 15);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Strepsils', 69.90, 0);
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Xanax', 159.90, 1);
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Zdravotní pojišťovna ministerstva vnitra', 'Praha 3');
INSERT INTO Pojistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('Maxima pojišťovna', 'Bratislava');
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES (2, 1, 100);
INSERT INTO Skladuje (lekarna_pk, lek_pk, mnozstvi) VALUES (3, 2, 10);
INSERT INTO Hradi (lek_pk, pojistovna_pk,castka) VALUES (1, 2, 15);
INSERT INTO Hradi (lek_pk, pojistovna_pk,castka) VALUES (3, 2, 20);




INSERT INTO Nakup (nakup_datum, nakup_suma) VALUES (TO_DATE('17.02.2023', 'DD.MM.YYYY'), 59.80);
INSERT INTO Nakup (nakup_datum, nakup_suma) VALUES (TO_DATE('17.02.2023', 'DD.MM.YYYY'), ); -- todo
INSERT INTO Nakup (nakup_datum, nakup_suma) VALUES (TO_DATE('19.02.2023', 'DD.MM.YYYY'), ); -- todo

INSERT INTO Nakup_na_predpis (nakup_pk, rodne_cislo) VALUES (2, "020220/1234");
INSERT INTO Nakup_na_predpis (nakup_pk, rodne_cislo) VALUES (3, "9815121111");

INSERT INTO Lekarna (lekarna_nazev, lekarna_jmeno_majitele, lekarna_adresa) VALUES ("Vaše lekárna", "Matěj Macek", "Kolejní 2, 61200, Brno, Česká republika");
INSERT INTO Lekarna (lekarna_nazev, lekarna_jmeno_majitele, lekarna_adresa) VALUES ("Nejlepší lekárna", "Martin Kubička", "Božetěchova 2, 61200, Brno, Česká republika");

INSERT INTO Byl_proveden (nakup_pk, lekarna_pk) VALUES (1, 1);
INSERT INTO Byl_proveden (nakup_pk, lekarna_pk) VALUES (2, 2);
INSERT INTO Byl_proveden (nakup_pk, lekarna_pk) VALUES (3, 2);

INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES (1, 1, 2);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES (2, 1, 1);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES (2, 2, 1);
INSERT INTO Obsahuje (nakup_pk, lek_pk, mnozstvi) VALUES (3, 3, 3);

--------- End of IDS_2.sql ---------
