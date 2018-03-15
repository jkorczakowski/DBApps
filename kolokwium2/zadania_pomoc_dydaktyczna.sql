--Autorka pomocy dydaktycznej: Aldona Biewska 
--Cel: pomoc w przygotowaniu si� do kolokwium
--Pomoc dydaktyczna powsta�a w ramach przedmiotu
--aplikacje bazodanowe w dniu 30.04.2015 r.
--pod kierunkiem dra Roberta Fidytka
--Zosta�a wykorzystana baza danych sklep internetowy
--Drobne poprawki wprowadzi� dr Robert Fidytek

--==============================================1.
--Stw�rz kolumne liczba_zamowien w tabeli klient 
--z domy�ln� warto�ci� 0.
--Napisz wyzwalacz, kt�ry po dodaniu nowego zam�wienia, 
--b�dzie aktualizowa� liczb� zam�wie� w kolumnie liczba_zamowien. (1w)

ALTER TABLE klient ADD liczba_zamowien INT DEFAULT '0'; 
GO
UPDATE klient SET liczba_zamowien=0; 
GO

--DROP TRIGGER dodaj_do_liczba_zamowien

CREATE TRIGGER dodaj_do_liczba_zamowien ON zamowienie
AFTER INSERT
AS
BEGIN
	UPDATE klient SET liczba_zamowien=liczba_zamowien + 1 WHERE id_klient IN (SELECT id_klient FROM INSERTED)
END;
GO

--test: dodajemy nowe zam�wienie dla id_klient=4, liczba_zamowien dla id_klient=4 wzros�a o 1
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (44,1,4,'2011-03-06 11:35',100,23);
SELECT * FROM klient;
GO

--==========================================2.
--Napisz funkcj� pomocnicz� spr_status, kt�ra zwraca warto�� true je�li zam�wienie ma status dostarczony 
--( w tabeli status nazwa='dostarczenie przesy�ki') lub false w innym przypadku.(1f)
--Napisz wyzwalacz, kt�ry po dodaniu nowego rekordu w tabeli zamowienie_status, b�dzie aktualizowa� kolumn�
--liczba_zamowien odejmuj�c zam�wienie, wykorzystaj funkcj� spr_status (nie przejmujemy sie warto�ciami ujemnymi).(2w) 


--DROP FUNCTION dbo.spr_status

CREATE FUNCTION spr_status(@id_zamowienie INT)
RETURNS BIT
BEGIN
IF (SELECT COUNT(s.id_status) FROM status s INNER JOIN zamowienie_status zs ON s.id_status=zs.id_status 
		WHERE zs.id_zamowienie=@id_zamowienie AND s.nazwa='dostarczenie przesy�ki' )=1
	RETURN 1
RETURN 0
END;
GO

--test: sprawdzamy, czy zam�wienie ma status dostarczony dla id_zamowienie=1 orad id_zamowienie=21
SELECT dbo.spr_status(1); --domy�lnia baza: tak
SELECT dbo.spr_status(21); --domy�lna baza: nie
GO
--DROP TRIGGER odejmij_od_ilosc_zamowien

CREATE TRIGGER odejmij_od_ilosc_zamowien ON zamowienie_status
AFTER INSERT
AS
BEGIN
	DECLARE @id INT
	SELECT @id=id_zamowienie FROM inserted
	IF dbo.spr_status(@id)=1
	BEGIN
		UPDATE klient SET liczba_zamowien=liczba_zamowien - 1 WHERE id_klient IN 
 		(SELECT z.id_klient FROM zamowienie_status zs  INNER JOIN zamowienie z ON z.id_zamowienie=@id)
	END	
END;
GO

--test: dodajemy nowe zam�wienie ze statusem 'dostarczenie zamowienia' dla id_zamowienie=21, 
--kolumna liczba_zamowien dla klienta o id=19 zmala�a o 1.

INSERT INTO zamowienie_status(id_zamowienie,id_status,data_zmiany_statusu,uwagi) VALUES (21,6,'2013-02-16 21:05','brak');
SELECT * FROM klient;
GO


--=========================================3.
--Napisz funkcj� pomocnicz� spr_koszyk, kt�ra zwraca ilo�� zam�wie�(rodzaju produktu) danego klienta w koszyku podczas jednego zam�wienia(transakcji).(2f)
--Napisz wyzwalacz,kt�ry uniemo�liwi dodanie kolejnego zam�wienia(rodzaju produktu) do koszyka podczas jednego zam�wienia (transakcji), 
--je�li w koszyku s� ju� 4 zam�wienia(rodzaju produktu), skorzystaj z funkcji spr_koszyk.(3w)


--DROP FUNCTION dbo.spr_koszyk

CREATE FUNCTION spr_koszyk(@id_klient INT,@id_zamowienie INT)
RETURNS INT
BEGIN
	RETURN ( SELECT COUNT(*) FROM koszyk ko INNER JOIN zamowienie zm ON ko.id_zamowienie=zm.id_zamowienie 
	WHERE zm.id_klient=@id_klient AND ko.id_zamowienie=@id_zamowienie )
END;
GO

--test: sprawdzamy ilo�� zam�wie�(rodzaju produktu) dla id_klient=9 i id_zamowienie=12
SELECT dbo.spr_koszyk(9,12)
GO


--DROP TRIGGER oganiczenie_zamowien

CREATE TRIGGER oganiczenie_zamowien ON koszyk
AFTER INSERT
AS
BEGIN
	DECLARE @id_zamowienie INT, @id_klient INT
	SELECT @id_zamowienie=id_zamowienie FROM inserted
	SET @id_klient=(SELECT id_klient FROM zamowienie WHERE id_zamowienie=@id_zamowienie)
	IF dbo.spr_koszyk( @id_klient, @id_zamowienie)>4
	BEGIN
		RAISERROR('Max 4 zamowienia na koszyk podczas jednej transakcji',1,2)
		ROLLBACK		
	END
END;
GO

--test: dodajemy dla id_klient=7, zam�wienia, je�li przekroczy 4 wy�wietli si� komunikat
INSERT INTO koszyk(id_zamowienie,id_produkt,cena_netto,podatek,ilosc_sztuk) VALUES (4,13,229,23,1100);
INSERT INTO koszyk(id_zamowienie,id_produkt,cena_netto,podatek,ilosc_sztuk) VALUES (4,14,229,23,1100);
GO
--======================================4.
--Napisz funkcj� pomocnicz�, kt�ra sprawdza poprawno�� zapisu email(3f)
--Napisz wyzwalacz, kt�ry uniemo�liwi modyfikacj� emaila
--w tabeli klient na niepoprawny format, wykorzystaj funkcj� sprawdz_email.(4w)


--DROP FUNCTION dbo.sprawdz_email

CREATE FUNCTION sprawdz_email(@email VARCHAR(30))
RETURNS BIT
BEGIN
	IF @email  LIKE '%_@_%_.__%'
		RETURN 1
	RETURN 0
END;
GO

--test: sprawdzamy poprawno�� maila
SELECT dbo.sprawdz_email('qweq3wp.pl');
GO
SELECT dbo.sprawdz_email('radzetom68@o2.pl');
GO


--DROP TRIGGER spr_dodawany_email;

CREATE TRIGGER spr_dodawany_email ON klient
AFTER UPDATE
AS
BEGIN
	DECLARE @email VARCHAR(30)
	SET @email=-1
	SELECT @email=email FROM inserted;
	IF dbo.sprawdz_email(@email)=0
		BEGIN			
			RAISERROR('Nie mo�na modyfikowac maila na z�y format!', 1, 2)
			ROLLBACK
		END
END;
GO

--test: sprawdzamy poprawno�� aktualizowanego maila dla id_klient=1;
UPDATE klient SET email='dobry@wp.pl' WHERE id_klient=1;
UPDATE klient SET email='zle' WHERE id_klient=1;
GO

--==========================================5.
--Stw�rz widok raport_kategorii(id_kategoria,nazwa, suma_produkt�w), gdzie
--id_kategoria, nazwa to kolumny z tabeli kategoria, suma_produkt�w to
--suma produkt�w w danej kategorii, uwzgl�dnij kategorie bez produkt�w.
--Utw�rz wyzwalacz, kt�ry po wykonaniu zapytania:
--INSERT INTO raport_produkt�w(nazwa) VALUES ('Nowa kategoria');
--doda now� kategori� do tabeli kategoria. (5w)

--DROP VIEW raport_kategorii

CREATE VIEW raport_kategorii
AS
SELECT k.id_kategoria,k.nazwa,COUNT(p.id_produkt) as suma_produkt�w
	FROM kategoria k LEFT JOIN podkategoria pod ON k.id_kategoria=pod.id_kategoria 
		LEFT JOIN produkt p ON pod.id_podkategoria=p.id_podkategoria
			GROUP BY k.id_kategoria, k.nazwa;
GO

--test: sprawdzamy utworzony widok
SELECT * FROM raport_kategorii;
GO


--DROP TRIGGER dodaj_kategorie

CREATE TRIGGER dodaj_kategorie ON raport_kategorii
INSTEAD OF INSERT AS
BEGIN
	DECLARE kursor CURSOR FOR SELECT nazwa, id_kategoria FROM inserted
	DECLARE @nazwa VARCHAR(20), @id_kategoria INT
	OPEN kursor
	FETCH NEXT FROM kursor INTO @nazwa, @id_kategoria
	WHILE @@FETCH_STATUS=0
	BEGIN
		INSERT INTO kategoria(id_kategoria, nazwa) VALUES (@id_kategoria, @nazwa)
		FETCH NEXT FROM kursor INTO @id_kategoria, @nazwa
	END
	CLOSE kursor
	DEALLOCATE kursor
END;
GO

--test: dodajemy kategori� do raport_kategorii, nowe kategorie dodaje si� do tabeli kategoria
INSERT INTO raport_kategorii(id_kategoria, nazwa) VALUES (70,'NOWA KAT5');
INSERT INTO raport_kategorii(id_kategoria, nazwa) VALUES (80,'NOWA KAT6');
SELECT * FROM kategoria;
GO

--============================6.
--Stw�rz widok widok_producent(id_producent,nazwa,id_adres,ulica,numer,kod,miejscowosc), gdzie
--id_producent, nazwa to kolumny z tabeli producent, 
--id_adres,ulica,numer,kod,miejscowosc to kolumny tabeli adres
--Utw�rz procedur� pomocnicz� dodaj_producenta umo�liwaj�ca dodanie nowego producenta 
--i adresu producenta je�li ten nie istnieje w tabeli adres(1p)
--Utw�rz wyzwalacz producenci_dodaj, kt�ry po wykonaniu zapytania:
--INSERT INTO widok_producent (id_producent,nazwa, id_adres,ulica, numer, kod , miejscowosc) VALUES (123,'polkom',123,'ulica','12','12-222','poznan');
--doda nowego producenta do tabeli producent oraz doda nowy adres do tabeli adres, je�li ten nie istnieje (6w)
--uwagi ze wzgl�du na brak autoinkrementacji w insert podajemy id


--DROP VIEW widok_producent

CREATE VIEW widok_producent
AS
SELECT p.id_producent, p.nazwa,m.id_adres,m.miejscowosc, m.ulica,m.numer,m.kod
	FROM producent p INNER JOIN adres m ON p.id_producent=m.id_adres;
GO	

--test: sprawdzamy utworzony widok
SELECT * FROM widok_producent;
GO


--DROP PROCEDURE dodaj_producenta

CREATE PROCEDURE dodaj_producenta
@id_producent INT,
@nazwa VARCHAR(30),
@id_adres INT,
@miejscowosc  VARCHAR(30),
@ulica  VARCHAR(30),
@numer CHAR(10),
@kod CHAR(6)
AS
BEGIN
	DECLARE @id_adresPOM INT
IF NOT EXISTS (SELECT * FROM adres WHERE miejscowosc=@miejscowosc AND ulica=@ulica AND numer=@numer AND kod=@kod)
BEGIN
	INSERT INTO adres(id_adres,ulica,numer,kod,miejscowosc) VALUES (@id_adres,@ulica, @numer, @kod, @miejscowosc)
	INSERT INTO producent(id_producent, id_adres, nazwa) VALUES (@id_producent,@id_adres,@nazwa)
END
ELSE
BEGIN
	SELECT @id_adresPOM=id_adres FROM adres WHERE miejscowosc=@miejscowosc AND ulica=@ulica AND numer=@numer AND kod=@kod
	INSERT INTO producent(id_producent, id_adres, nazwa) VALUES (@id_producent,@id_adresPOM,@nazwa)
END
END;
GO
--test: sprawdzamy procedur�, dodajemy producenta wraz z adresem, w tabeli producent pojawi� si� producent o id 132 i 133
--w tabeli adres, pojawi� adres o id 132, gdy� drugi producent ma ten sam adres

exec dodaj_producenta 132,'SUPER PRODUCENT',132,'Poznan','Morasko','11','50-500';
exec dodaj_producenta 133,'JESZCZE LEPSZY PRODUCENT',133,'Poznan','Morasko','11','50-500';
GO

SELECT *  FROM producent;
SELECT * FROM adres;
GO
--DROP TRIGGER producenci_dodaj

CREATE TRIGGER producenci_dodaj
ON widok_producent
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @id_producent INT, @nazwa VARCHAR(30),@id_adres INT, @miejscowosc VARCHAR(30), @ulica VARCHAR(30), @numer VARCHAR(30), @kod VARCHAR(30)
	SELECT @id_producent=id_producent,@nazwa=nazwa,@id_adres=id_adres, @miejscowosc=miejscowosc, @ulica=ulica, @numer=numer, @kod=kod FROM inserted
	exec dodaj_producenta @id_producent, @nazwa, @id_adres, @miejscowosc, @ulica, @numer, @kod
END;
GO

--test: dodajemy do widoku producenta wraz z adresem, w tabeli producent pojawi� si� producent o id 161 i 157
--w tabeli adres, pojawi� adres o id 161, gdy� drugi producent ma ten sam adres

INSERT INTO widok_producent (id_producent,nazwa, id_adres,ulica, miejscowosc, numer, kod) VALUES (161,'L',161,'Poznan','Batorego','11','50-500');
INSERT INTO widok_producent (id_producent,nazwa, id_adres,ulica, miejscowosc, numer, kod) VALUES (157,'P',157,'Poznan','Batorego','11','50-500');

SELECT *  FROM producent;
SELECT * FROM adres;
GO

--============================7.
--Utw�rz procedur� pomocnicz�, kt�ra zmienia warto�� czy_oplacona w tabeli faktura na true (2p)
--Utw�rz funkcj� pomocznicz�, kt�ra zwraca true je�li status zam�wienia jest 'otrzymano zap�at�', 
--w przciwnym wypadku zwraca false.(4f)
--Utw�rz wyzwalacz, kt�ry po dodaniu nowego rekordu w tabeli zam�wienie_status ze statusem 'otrzymano zap�at�', 
--b�dzie aktualizowa� kolumne czy_opacona w tabeli faktura na true.(7w)


--DROP PROCEDURE zmien_faktura

CREATE PROCEDURE zmien_faktura
@id_zamowienie INT
AS
BEGIN
	UPDATE faktura SET czy_oplacona=1 WHERE id_zamowienie=@id_zamowienie;
END;
GO

--test: zamieniamy warto�� kolumny czy_oplacona dla id_zamowianie=3 na true
exec zmien_faktura 3;
select * from faktura;
GO

--DROP FUNCTION spr_faktura

CREATE FUNCTION spr_faktura(@id_zamowienie INT)
RETURNS BIT
BEGIN
IF (SELECT COUNT(s.id_status) FROM status s INNER JOIN zamowienie_status zs ON s.id_status=zs.id_status 
		WHERE zs.id_zamowienie=@id_zamowienie AND s.nazwa='otrzymano zap�at�' )=1
	RETURN 1
RETURN 0
END;
GO

--test: sprawdzamy czy id_zamowienie=1 oraz id_zamowienie=51 ma status_zamowienia='otrzymano zap�at�'
SELECT dbo.spr_faktura(1); --tak
SELECT dbo.spr_faktura(51); --nie
GO
--DROP TRIGGER sprawdz_faktura

CREATE TRIGGER sprawdz_faktura ON zamowienie_status
AFTER INSERT
AS
BEGIN
	DECLARE @id INT
	SELECT @id=id_zamowienie FROM inserted
	IF dbo.spr_faktura(@id)=1
	BEGIN		
 		exec zmien_faktura @id;
	END	
END;
GO

--test: aktualizujemy kolumne czy_opacona w tabeli faktura na true
--dodajemy nowe zamowienie
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (56,14,22,'2013-10-12 16:46',50,123);

--dodajemy fakture id_faktura=56 do dodanego zamowienia
INSERT INTO faktura(id_faktura,id_zamowienie,id_klient,id_pracownik,nr_faktury,data_wystawienia,data_platnosci,czy_oplacona) VALUES (56,56,22,1,'013','2011-06-23 12:12','2011-06-30 22:32',0);

--dodajemy zamowienie_status  o id_status=3(czyli otzymano_zap�at�)
INSERT INTO zamowienie_status(id_zamowienie,id_status,data_zmiany_statusu,uwagi) VALUES (56,3,'2011-03-07 11:35','brak');

--kolumne czy_opacona w tabeli faktura dla wiersza o id_faktura=56 zmieni�a si� na true;
SELECT * FROM FAKTURA;
GO

--============================8.
--Utw�rz funkcj� spr_stanowiska z trzema parametrami stanowisko,data1 i data2, kt�ra zwraca ilo�� zam�wie� 
--obs�u�onych przez pracownik�w z zadanym stanowiskiem, w okre�lonym przedziale czasowym.(5f)
--Utw�rz wyzwalacz, kt�ry po dodaniu nowego zam�wienia, b�dzie zwi�ksza� o 50 dodatek wszystkim pracownikom 
--danego stanowiska, je�li suma zam�wie� kt�re obs�uzyli przekroczy�a 4 w czasie od 2013-01-01 do 2014-01-01,
--skorzystaj z fucnkji spr_stanowiska.(9w)

--DROP FUNCTION spr_stanowiska

CREATE FUNCTION spr_stanowiska(@stanowisko VARCHAR(30), @data1 DATETIME, @data2 DATETIME)
RETURNS INT
BEGIN
RETURN (SELECT COUNT(z.id_zamowienie)AS suma_zamowien
	FROM pracownik p LEFT JOIN zamowienie z ON p.id_pracownik=z.id_pracownik 
	WHERE stanowisko=@stanowisko AND data_zamowienia BETWEEN @data1 AND @data2)
END;
GO

--test: sprawdzamy ilo�c zam�wie� obs�u�onych przez pracownik�w ze stanowiskiem ksi�gowy w czasie 2013-01-01 - 2014-01-01
SELECT dbo.spr_stanowiska('ksi�gowy','2013-01-01','2014-01-01');
GO

--DROP TRIGGER edytuj_premie

CREATE TRIGGER edytuj_premie ON zamowienie
AFTER INSERT
AS
BEGIN
	DECLARE @stanowisko VARCHAR(30), @id INT
	SELECT @id=id_pracownik FROM inserted
	SELECT @stanowisko=stanowisko FROM pracownik WHERE id_pracownik=@id
	IF dbo.spr_stanowiska(@stanowisko,'2013-01-01','2014-01-01')>4
	BEGIN		
		UPDATE pracownik SET dodatek=dodatek+50 WHERE stanowisko=@stanowisko
	END	
END;
GO


--test: dodajemy zam�wienia dla pracownik�w ze stanowiskiem sprzedawca w odpowiednim przedziale czasu, suma zam�wien przekroczy�a 4 wi�c zwi�kszamy dodatek
--pracownikom stanowiska sprzedawca o 50
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (83,2,10,'2013-03-06 11:35',100,23);
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (84,8,10,'2013-03-06 11:35',100,23);
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (62,1,10,'2011-03-06 11:35',100,23);

SELECT * FROM pracownik;
GO

--============================9.
--Stw�rz funkcj� spr_suma_zamowienie, kt�ra zwraca sum� ca�ego zam�wienia danego klienta (we� pod uwag� podatek).(5f)
--Napisz procedur� suma_zamowienie,posiadaj�ca dwa parametry id_klient, id_zamowienie, kt�ra korzystaj�c z funkcji 
--spr_suma_zamowienie, zwi�ksza rabat danego klienta o 200, je�li suma zadanego zam�wienia klienta przekroczy�a 5000.(3p)
--Utw�rz wyzwalacz, kt�ry po dodaniu,edycji zam�wienia do koszyka b�dzie pobiera� id_klienta i id_zamowienia z dodanych i wywo�ywa� procedur�.(10w)


--DROP FUNCTION spr_suma_zamowienie

CREATE FUNCTION spr_suma_zamowienie(@id_klient INT, @id_zamowienie INT)
RETURNS DECIMAL(8,2)
BEGIN
	RETURN (SELECT SUM((1+ko.podatek)*ko.cena_netto) FROM koszyk ko INNER JOIN zamowienie z ON ko.id_zamowienie=z.id_zamowienie
		WHERE z.id_klient=@id_klient AND z.id_zamowienie=@id_zamowienie)
END;
GO

--test: sprawdzamy sum� zam�wienia o id_zamowienie=23, dla klienta o id=23
SELECT dbo.spr_suma_zamowienie(23,23);
GO

--DROP PROCEDURE suma_zamowienie

CREATE PROCEDURE suma_zamowienie
@id_klient INT,
@id_zamowienie INT
AS
BEGIN
	IF dbo.spr_suma_zamowienie(@id_klient, @id_zamowienie)>5000
	UPDATE klient SET rabat=rabat+200 WHERE id_klient=@id_klient
END;
GO

--test: sprawdzamy, czy suma zamowienia dla id_zamowienie=1 przekroczy�a 5000, 
--je�li tak zwi�kszamy rabat klienta id_klient=10 o 200
exec suma_zamowienie 10,1;
select * from klient;
GO

--DROP TRIGGER zwieksz_rabat 

CREATE TRIGGER zwieksz_rabat ON koszyk
AFTER INSERT
AS
BEGIN
	DECLARE @id_klient INT, @id_zamowienie INT
	SELECT @id_zamowienie=id_zamowienie FROM inserted
	SELECT @id_klient=z.id_klient FROM zamowienie z inner join koszyk ko 
	ON z.id_zamowienie=ko.id_zamowienie WHERE ko.id_zamowienie=@id_zamowienie
	exec suma_zamowienie @id_klient, @id_zamowienie
END;
GO

--test: dodajemy dla id_klient=23 nowe zam�wienie do koszyka, jego rabat zwi�kszy� sie o 200
INSERT INTO koszyk(id_zamowienie,id_produkt,cena_netto,podatek,ilosc_sztuk) VALUES (23,22,229,23,1100);
SELECT * FROM klient;
GO

--===========================10.
--Dodaj do tabeli adres kolumn� dziennik z domy�ln� warto�ci� NULL oraz kolumn� data.
--Stw�rz wyzwalacz, kt�ry po zmodyfikowaniu tabeli adres, b�dzie modyfikowa� kolumn� 
--dziennik na napis 'zedytowano adres', oraz kolumn� data na dat� modyfikacji(11w)

ALTER TABLE adres ADD dziennik VARCHAR(100) DEFAULT NULL, data DATETIME ;
GO

--DROP TRIGGER edytuj_dziennik

CREATE TRIGGER edytuj_dziennik ON adres
AFTER UPDATE
AS
BEGIN
	declare @id int, @ulica VARCHAR(30), @numer VARCHAR (30), @kod VARCHAR(30), @miejscowosc VARCHAR(30)
	select @id=id_adres, @ulica=ulica,@numer=numer, @kod=kod, @miejscowosc=miejscowosc from inserted
	IF(SELECT COUNT(*) FROM adres WHERE ulica=@ulica AND numer=@numer AND kod=@kod AND miejscowosc=@miejscowosc)>0
	BEGIN
		UPDATE adres SET dziennik='zedytowano adres' WHERE id_adres=@id
		UPDATE adres SET data= GETDATE() WHERE id_adres=@id
	END
END;
GO

--test: edytujemy adres o id=2,4,12, w kolumnie dziennik pojawi� si� napis 'zedytowano adres' w kolumnie data pojawi�a si� data edycji
UPDATE adres SET ulica='marcinkowska' where id_adres=2;
UPDATE adres SET ulica='helska' where id_adres=4;
UPDATE adres SET ulica='batorego' where id_adres=12;

select * from adres;
GO


--==========================11.
--Napisz funkcj� spr_pensje, kt�ra zwraca �redni� pensje pracownik�w danego stanowiska je�li by�a wi�ksza ni� 4700 (6f)
--Napisz procedur� zwieksz_pensje, kt�ra zwi�ksza pensj� pracownik�w danego stanowiska o 10% je�li ich �rednia pensja
--by�a nie mniejsza ni� 5000 i o 5% je�li ich pensja by�a wi�ksza ni� 5000 i mniejsza ni� 6000.(4p)

--DROP FUNCTION spr_pensje

CREATE FUNCTION spr_pensje(@stanowisko VARCHAR(30))
RETURNS DECIMAL(8,2)
BEGIN
	RETURN (SELECT AVG(pensja) FROM pracownik WHERE stanowisko=@stanowisko
	HAVING AVG(pensja)>4700)
END;
GO

--test: sprawdzamy �redni� pensj� dla podanych stanowisk, �rednia pensja wy�wietla si� je�li jest wi�ksza ni� 4700
SELECT dbo.spr_pensje('kierownik');
SELECT dbo.spr_pensje('sprzedawca');
SELECT dbo.spr_pensje('ksiegowy');
GO

--DROP PROCEDURE zwieksz_pensje

CREATE PROCEDURE zwieksz_pensje
@stanowisko VARCHAR(30)
AS
BEGIN
	IF dbo.spr_pensje(@stanowisko)<=5000 AND dbo.spr_pensje(@stanowisko)!=NULL UPDATE pracownik SET pensja=pensja+pensja*0.10 WHERE stanowisko=@stanowisko
	IF dbo.spr_pensje(@stanowisko)>5000 UPDATE pracownik SET pensja=pensja+pensja*0.05 WHERE stanowisko=@stanowisko
END;
GO

--test: uruchamiaj�c procedur� zwi�kszamy pensj� kolejno 
--stanowiska sprzedawca (nie zwi�kszy si� bo poni�ej �redniej) i kierownik
exec zwieksz_pensje 'sprzedawca'
exec zwieksz_pensje 'kierownik'
select * from pracownik;
GO

--=======================================12.
--Napisz wyzwalacz, kt�ry po dodaniu lub zmodyfikowaniu zam�wienia, zmniejszy kolumne cena_netto_dostawy w tabeli zamowienie o 50%, 
--je�li zamowienie zosta�o zam�wione w dniach 2013-02-14 2013-02-16(12w)

--DROP TRIGGER  zmniejsz_cene_dostawy

CREATE TRIGGER zmniejsz_cene_dostawy ON zamowienie
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @data DATETIME, @id INT
	SELECT @data=data_zamowienia, @id=id_zamowienie FROM inserted
	IF @data BETWEEN '2013-02-14' AND '2013-02-16'
		UPDATE zamowienie SET cena_netto_dostawy=cena_netto_dostawy*0.5 WHERE id_zamowienie=@id
END;
GO

--test: dodajemy nowe zam�wienia o id=100,101 w zadanym przedziale czasowym
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (100,1,10,'2013-02-15 11:35',100,23);
INSERT INTO zamowienie(id_zamowienie,id_pracownik,id_klient,data_zamowienia,cena_netto_dostawy,podatek) VALUES (101,1,10,'2013-02-15 11:35',100,23);

--edytujemy zamowienia o id=1 na zadany przedzia� czasowy
UPDATE zamowienie SET data_zamowienia='2013-02-16' WHERE id_zamowienie=1;

--zam�wienia o id=100,101,1 maj� cene dostawy mniejsza o 50%
select * from zamowienie;
GO

--==========================13.
--Napisz procedur� zwieksz_rabat_data, kt�ra zwi�ksza o 400 rabat klientowi, kt�ry zosta� dodany najwcze�niej.(5p)

--DROP PROCEDURE zwieksz_rabat_data

CREATE PROCEDURE zwieksz_rabat_data
AS
BEGIN

	UPDATE klient SET rabat=rabat+400 WHERE 
		id_klient=(SELECT id_klient FROM klient WHERE data_dodania=(SELECT MIN(data_dodania) FROM klient))
END;
GO

--test: sprawdzamy jaki klient zosta� dodany najwcze�niej i zwi�kszamy jego rabat o 400
EXEC zwieksz_rabat_data;
GO

--==========================14.
--Napisz funkcj� brak_produktow, kt�ra zwr�ci nazwy id producent�w, kt�rzy nie sprowadzili �adnego produktu.
--(podpowied�: funkcja tabelowa)(7f)
--Napisz wyzwalacz, kt�ry zabroni modyfikacji rekord�w w tabeli producent, je�li dany producent sprowadzi� produkt, 
--skorzystaj z funkcji brak_produkt�w. (13w)

--DROP FUNCTION brak_produktow

CREATE FUNCTION brak_produktow()
RETURNS TABLE AS
	RETURN ( SELECT id_producent FROM producent WHERE id_producent NOT IN(SELECT id_producent FROM produkt));
GO

--test: wy�wietlamy id_producent�w, kt�rzy nie sprowadzili �adnego produktu
SELECT * FROM brak_produktow();
GO


--DROP TRIGGER zabron_brak_produktow

CREATE TRIGGER zabron_brak_produktow ON producent
AFTER UPDATE
AS
BEGIN
	DECLARE @id INT
	SELECT @id=id_producent FROM deleted
	IF NOT EXISTS ( SELECT * FROM brak_produktow() WHERE id_producent=@id)
	BEGIN 
		RAISERROR('Nie mozna edytowac producenta, kt�ry sprowadzi� produkt',1,2)
		ROLLBACK
	END
END;
GO

--test:sprawdzamy czy da si� zmieni� nazw� producenta o id=12,15, nie da si� je�li dany producent sprowadzi� produkt
UPDATE producent SET nazwa='NOWY2' where id_producent=15;
UPDATE producent SET nazwa='NOWY1' where id_producent=12;
SELECT * FROM producent;
GO


--============================15.
--Utw�rz funkcj� znajdz_produkty, kt�ra wy�wietla id_produktu, nazwe oraz ilosc(ile razy zakupiony dany produkt), 
--dla produkt�w, kt�re zosta�y zakupione conajmniej 4 razy.(8f)
--Utw�rz procedur� zwieksz_cene_produktu, kt�ra podnosi cena_netto w kolumnie produkt o 20%, je�li
--dany produkt by� zakupiony conajmniej 4 razy, skorzystaj z funkcji znajdz_produkty (6p)

--DROP FUNCTION znajdz_produkty

CREATE FUNCTION znajdz_produkty()
RETURNS TABLE AS
	RETURN ( SELECT p.id_produkt, p.nazwa, COUNT(p.id_produkt) AS ilosc FROM produkt p 
			INNER JOIN koszyk k ON p.id_produkt=k.id_produkt GROUP BY p.id_produkt, p.nazwa
			HAVING COUNT(p.id_produkt)>=4 );
GO

--test: wy�wietlamy przy pomocy funkcji produkty, kt�re zosta�y zakupione conajmniej 4 razy
SELECT * FROM znajdz_produkty();
GO

--DROP PROCEDURE zwieksz_cene_produktu

CREATE PROCEDURE zwieksz_cene_produktu
AS
BEGIN
	UPDATE produkt SET cena_netto=cena_netto+0.20*cena_netto WHERE 
		id_produkt IN (SELECT id_produkt FROM znajdz_produkty())
END;
GO

--test: zwi�kszamy cene produkt�w, kt�re zosta�y zakupione conajmniej 4 razy
EXEC zwieksz_cene_produktu;
SELECT * FROM produkt;
GO

--============================16.
--Utw�rz procedur� najczesciej_klient, przyjmuj�ca parametry min_ilosc, id_klient 
--kt�ra zwr�ci id_klienta, imie, nazwisko klienta, kt�ry najcz�sciej sk�ada� zam�wienia, 
--a minimalna ilosc najcz�stszych zamowie� jest okre�lona parametrem min_ilosc.(9f)
--Utw�rz procedur�, kt�ra b�dzie przymowa�a jako parametr id_klienta, min_ilosc, 
--i korzystaj�c z funkcji  najczesciej_klient, do kt�rej przekazuje parametr min_ilosc, b�dzie
--sprawdza�a czy dany klient jest klientem najcz�sciej zamawiajcym, je�li tak zwi�kszy jego rabat o 50%.(7p)

--DROP FUNCTION najczesciej_klient

CREATE FUNCTION najczesciej_klient(@min_ilosc INT)
RETURNS TABLE AS
	RETURN (SELECT k.id_klient,k.imie, k.nazwisko, COUNT (z.id_klient)AS ilosc FROM klient k INNER JOIN zamowienie z ON k.id_klient=z.id_klient
				GROUP BY k.id_klient, k.imie, k.nazwisko
				HAVING COUNT(z.id_klient)=
					(
						SELECT TOP 1 COUNT (z.id_klient)AS ilosc
						FROM zamowienie z
						GROUP BY z.id_klient
						HAVING COUNT (z.id_klient)>@min_ilosc
						ORDER BY ilosc DESC
					)
			)
GO

--test: wy�wietlamy przy pomocy funkcji id_klienta, kt�ry najcz�sciej sk�ada� zam�wienia, w nawiasie min ilo�c zam�wie�				
SELECT * FROM najczesciej_klient(3);					
SELECT * FROM najczesciej_klient(4);
GO				


--DROP PROCEDURE zwieksz_rabat_data_klient

CREATE PROCEDURE zwieksz_rabat_data_klient
@id_klient INT,
@min_ilosc INT
AS
BEGIN
	IF EXISTS(SELECT id_klient FROM najczesciej_klient(3) WHERE id_klient=@id_klient)
	BEGIN
		UPDATE klient SET rabat=rabat+0.50*rabat WHERE id_klient=@id_klient
	END
END;
GO

--test: zwi�kszamy rabat klientowi o zadanym id, je�li by� on najcz�sciej zamawiaj�cym, drugi parametr to min ilo�� zam�wie�
EXEC zwieksz_rabat_data_klient 2,3;
EXEC zwieksz_rabat_data_klient 3,4;
EXEC zwieksz_rabat_data_klient 10,3;

SELECT * FROM klient;
GO

--============================17.	
--Procedura o nazwie zmien_telefon, kt�ra posiada dwa parametry: id klienta i numer telefonu.
--Procedura sprawdza, czy istnieje klient o zadanym id, je�li istnieje to zmienia numer telefonu na zadany numer,
--je�li nie istnieje klient o zadanym id to wy�wietla napis "Nie ma klienta o zadanym ID!". (8p)

--DROP PROCEDURE zmien_telefon

CREATE PROCEDURE zmien_telefon
 @id INT,
 @telefon VARCHAR(20)
AS
BEGIN
	IF EXISTS(SELECT * FROM klient WHERE id_klient=@id)
		BEGIN
			UPDATE klient
			SET telefon=@telefon
			WHERE id_klient=@id
		END
	ELSE  
		PRINT 'Nie ma klienta o zadanym ID!'
END;
GO

--test: sprawdzamy czy klient o id=2,23 istnieje je�li tak zmieniamy mu numer telefony na zadany, je�li nie wy�wietlamy komunikat
EXECUTE zmien_telefon '2','123456789';
EXECUTE zmien_telefon '123','123456789';
GO
--==============================18.
--Napisz funkcj� spr_telefon, kt�ra zwraca true je�li numer telefonu, ma 9 cyfr i jest w formacie 123-123-123 lub 12-123-12-12 
--oraz false w przeciwnym przypadku(10f)
--Napisz wyzwalacz, kt�ry zabroni modyfikacji rekord�w, kt�re maj� z�y format numeru telefonu, oraz modyfikacji na z�y format numeru telefonu
--skorzystaj z funkcji spr_telefon. (14w)

--DROP FUNCTION spr_telefon

CREATE FUNCTION spr_telefon(@telefon VARCHAR(30))
RETURNS BIT
BEGIN
	IF @telefon LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]' OR @telefon LIKE '[0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
		RETURN 1
	RETURN 0
END;
GO

--test: sprawdzamy poprawno�� zapisu numeru telefonu
SELECT dbo.spr_telefon('111-111-111');
SELECT dbo.spr_telefon('11-111-11-11');
SELECT dbo.spr_telefon('aaa-aaa-aaa');
GO
--DROP TRIGGER zabron_numer

CREATE TRIGGER zabron_numer ON klient
AFTER UPDATE
AS
BEGIN
	DECLARE  @telefon VARCHAR(30)
	SELECT  @telefon=telefon FROM inserted
	IF  dbo.spr_telefon(@telefon)=0
	BEGIN 
		RAISERROR('Nie mozna edytowac, bo zly format numeru telefonu!',1,2)
		ROLLBACK
	END
END;
GO 

--test: edytujemy numer telefonu dla klient�w o id=1,8 je�li numer telefonu ma nieproprwany format, wy�wietlamy napis i zabraniamy edycji
UPDATE klient SET telefon='111-111-111' where id_klient=1;
GO
UPDATE klient SET email='trolo@wp.pl' where id_klient=8;
GO
UPDATE klient SET telefon='111-111-111s' where id_klient=1;
GO
SELECT * FROM klient;
GO
