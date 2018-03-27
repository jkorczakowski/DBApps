CREATE TABLE IF NOT EXISTS BOOK(
  ID_BOOK SERIAL PRIMARY KEY,
  TITLE VARCHAR(64) NOT NULL,
  AUTHOR VARCHAR(64) NOT NULL,
  ISBN CHAR(13) NOT NULL UNIQUE CHECK(char_length(ISBN)=13),
  READ BOOLEAN NOT NULL,
  DESCRIPTION TEXT,
  COMMENTS TEXT,
  PRICE REAL CHECK(PRICE>0),
  REALASE_DATE DATE,
  BOOKMARK TEXT,
  GENRE VARCHAR(64),
  PUBLISHER VARCHAR(64)
);