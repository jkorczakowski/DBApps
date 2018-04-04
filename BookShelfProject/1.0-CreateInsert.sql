DROP TABLE IF EXISTS BOOK;

CREATE TABLE IF NOT EXISTS BOOK(
  ID SERIAL PRIMARY KEY,
  TITLE VARCHAR(64) NOT NULL,
  AUTHOR VARCHAR(64) NOT NULL,
  ISBN CHAR(13) UNIQUE,
  RATING INT CHECK(RATING>=0 AND RATING<=10),
  RELEASE_DATE DATE,
  PUBLISHER VARCHAR(64)
);

INSERT INTO BOOK (TITLE,AUTHOR,ISBN,RATING,RELEASE_DATE,PUBLISHER) VALUES
('Pisma ascetyczne. T.1','Ewagriusz z Pontu','9788373541795',10,'2012-08-17','Wydawnictwo Benedyktynów Tyniec'),
('Ksiazka 2','Autor2','1111222233456',9,'2011-09-11','Wydawnictwo2'),
('Ksiazka 3','Autor3','2111567233456',8,'2012-08-22','Wydawnictwo3'),
('Ksiazka 4','Autor4','3111222233456',7,'2013-03-12','Wydawnictwo5'),
('Ksiazka 5','Autor5','4111222233456',6,'2014-02-23','Wydawnictwo4'),
('Ksiazka 6','Autor6','5111222233456',5,'2015-01-14','Wydawnictwo6'),
('Ksiazka 7','Autor7','7111222233456',4,'2016-05-26','Wydawnictwo7'),
('Ksiazka 8','Autor8','8111222233456',3,'2017-01-17','Wydawnictwo8'),
('Ksiazka 9','Autor9','9111222233456',2,'2018-05-12','Wydawnictwo9'),
('Ksiazka 0','Autor0','6111222233456',1,'2019-07-10','Wydawnictwo0');
