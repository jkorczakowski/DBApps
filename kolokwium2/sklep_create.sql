--MSSQL, baza danych na kolokwium: sklep internetowy
--dr Robert Fidytek 12.11.2013 r.
--(celowo nie ma autoinkrementacji)

CREATE TABLE adres (
  id_adres INTEGER NOT NULL PRIMARY KEY,
  ulica VARCHAR(50) NOT NULL,
  numer VARCHAR(10) NOT NULL,
  kod CHAR(11) NOT NULL,
  miejscowosc VARCHAR(30) NOT NULL
);
GO

CREATE TABLE klient (
  id_klient INTEGER NOT NULL PRIMARY KEY,
  id_adres INTEGER NOT NULL REFERENCES adres(id_adres),
  imie VARCHAR(25) NOT NULL,
  nazwisko VARCHAR(30) NOT NULL,
  pesel CHAR(11) NOT NULL UNIQUE,
  telefon VARCHAR(20) NOT NULL,
  email VARCHAR(30) NOT NULL,
  haslo VARCHAR(30) NOT NULL,
  rabat INTEGER NOT NULL DEFAULT 0,
  data_dodania DATETIME NOT NULL,
  usuniety BIT NOT NULL DEFAULT 0
);
GO
CREATE TABLE kategoria (
  id_kategoria INTEGER NOT NULL PRIMARY KEY,
  nazwa VARCHAR(30) NOT NULL UNIQUE
);
GO

CREATE TABLE podkategoria (
  id_podkategoria INTEGER NOT NULL PRIMARY KEY,
  id_kategoria INTEGER NOT NULL REFERENCES kategoria(id_kategoria),
  nazwa VARCHAR(30) NOT NULL UNIQUE
);
GO

CREATE TABLE pracownik (
  id_pracownik INTEGER NOT NULL PRIMARY KEY,
  id_adres INTEGER NOT NULL REFERENCES adres(id_adres),
  imie VARCHAR(25) NOT NULL,
  nazwisko VARCHAR(30) NOT NULL,
  data_zatrudnienia DATETIME NOT NULL,
  pensja DECIMAL(8,2) NOT NULL CHECK(pensja>0),
  dodatek DECIMAL (8,2) NULL,
  stanowisko VARCHAR(30) NOT NULL,
  usuniety BIT NOT NULL DEFAULT 0
);
GO



CREATE TABLE producent (
  id_producent INTEGER NOT NULL PRIMARY KEY,
  id_adres INTEGER NOT NULL REFERENCES adres(id_adres),
  nazwa VARCHAR(30) NOT NULL UNIQUE
);
GO

CREATE TABLE produkt (
  id_produkt INTEGER NOT NULL PRIMARY KEY,
  id_producent INTEGER NOT NULL REFERENCES producent(id_producent),
  id_podkategoria INTEGER NOT NULL REFERENCES podkategoria(id_podkategoria),
  nazwa VARCHAR(30) NOT NULL,
  opis VARCHAR(50) NOT NULL,
  cena_netto DECIMAL(10,2) NOT NULL CHECK(cena_netto>0),
  podatek INTEGER NOT NULL DEFAULT 23,
  ilosc_sztuk_magazyn INTEGER NOT NULL DEFAULT 0 CHECK(ilosc_sztuk_magazyn>=0)
);
GO
CREATE TABLE status (
  id_status INTEGER NOT NULL PRIMARY KEY,
  nazwa VARCHAR(50) NOT NULL,
  opis VARCHAR(50) NOT NULL
);
GO
CREATE TABLE zamowienie (
  id_zamowienie INTEGER NOT NULL PRIMARY KEY,
  id_pracownik INTEGER NOT NULL REFERENCES pracownik(id_pracownik) ON DELETE CASCADE,
  id_klient INTEGER NOT NULL REFERENCES klient(id_klient) ON DELETE CASCADE,
  data_zamowienia DATETIME NOT NULL,
  cena_netto_dostawy DECIMAL(10,2) NOT NULL DEFAULT 0,
  podatek INTEGER NOT NULL DEFAULT 23
);
GO
CREATE TABLE koszyk (
  id_zamowienie INTEGER NOT NULL REFERENCES zamowienie(id_zamowienie),
  id_produkt INTEGER NOT NULL REFERENCES produkt(id_produkt),
  cena_netto DECIMAL(10,2) NOT NULL CHECK(cena_netto>0),
  podatek INTEGER NOT NULL DEFAULT 23,
  ilosc_sztuk INTEGER NOT NULL DEFAULT 0 CHECK(ilosc_sztuk>=0),
  PRIMARY KEY(id_zamowienie, id_produkt)
);
GO
CREATE TABLE zamowienie_status (
  id_zamowienie INTEGER NOT NULL REFERENCES zamowienie(id_zamowienie),
  id_status INTEGER NOT NULL REFERENCES status(id_status),
  data_zmiany_statusu DATETIME NOT NULL,
  uwagi VARCHAR(100) NULL,
  PRIMARY KEY(id_zamowienie, id_status)
);
GO
CREATE TABLE faktura (
  id_faktura INTEGER NOT NULL PRIMARY KEY,
  id_zamowienie INTEGER NOT NULL REFERENCES zamowienie(id_zamowienie),
  id_klient INTEGER NOT NULL REFERENCES klient(id_klient) ON DELETE CASCADE,
  id_pracownik INTEGER NOT NULL REFERENCES pracownik(id_pracownik) ON DELETE CASCADE,
  nr_faktury VARCHAR(20) NOT NULL,
  data_wystawienia DATETIME NOT NULL,
  data_platnosci DATETIME NOT NULL,
  czy_oplacona BIT NOT NULL DEFAULT 0
);
GO

