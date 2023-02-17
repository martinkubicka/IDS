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

CREATE TABLE Poistovna (
    pojistovna_pk NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pojistovna_nazev VARCHAR2(50) NOT NULL,
    pojistovna_sidlo VARCHAR2(50) NOT NULL
);

--------- Vztahy ---------
CREATE TABLE Skladuje (
    lekarna_pk NUMBER NOT NULL,
    lek_pk NUMBER NOT NULL,
    skladuje_mnozstvi NUMBER(10) NOT NULL,
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
    CONSTRAINT hradi_pk_lek
        FOREIGN KEY (lek_pk)
        REFERENCES Lek (lek_pk),
    CONSTRAINT hradi_pk_pojistovna
        FOREIGN KEY (pojistovna_pk)
        REFERENCES Poistovna (pojistovna_pk)
);

--------- Ukazkove data ---------
INSERT INTO Lek (lek_nazev, lek_cena, lek_na_predpis) VALUES ('Paralen', 29.90, 0);
INSERT INTO Poistovna (pojistovna_nazev, pojistovna_sidlo) VALUES ('VZP', 'Praha 2');
INSERT INTO Skladuje (lekarna_pk, lek_pk, skladuje_mnozstvi) VALUES (1, 1, 50);
INSERT INTO Hradi (lek_pk, pojistovna_pk) VALUES (1, 1);

