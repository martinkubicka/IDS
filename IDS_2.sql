/*
* ROZDELENIE: 
* Martin: Entity: Nakup (+ generalizace), Lekarna | Vztahy: Obsahuje, Byl proveden | Ukazkove data  
*
* Matej: Entity: Lek, Poistovna | Vztahy: Skladuje, Hradi | Ukazkove data
*/


--------- Entity ---------
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

--------- Vztahy ---------
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

--------- Ukazkove data ---------
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

