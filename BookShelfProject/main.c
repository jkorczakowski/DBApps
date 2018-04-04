#include<unistd.h>
#include<stdlib.h>
#include<stdio.h>
#include<libpq-fe.h>


void toHTML()
{
FILE *f = fopen("BSP.html","w");
if (f==NULL)
{
	perror("Cannot open file");
	return;
}

//fprintf(f,"<!DOCTYPE html>\n<html lang=\"pl\">\n<head>\n <meta charset=\"tf-8\"/>\n <title>BookShelfProject</title>\n/</head>\n<body>\n<header><h1>Your Books</h1></header>\n);

fprintf(f,"<!DOCTYPE html>\n<html lang=\"pl\">\n<head>\n<meta charset=\"tf-8\">\n<title>BookShelfProject</title>\n</head>\n<body>\n<header><h1>Your Books</h1></header>\n");


fclose(f);
}









void doSQL(PGconn *conn, char *command)
{
  PGresult *result;


  result = PQexec(conn, command);

  switch(PQresultStatus(result)) {
  case PGRES_TUPLES_OK:
    {
      int m, n;
      int nrows = PQntuples(result);
      int nfields = PQnfields(result);
      printf("number of rows returned = %d\n", nrows);
      printf("number of fields returned = %d\n", nfields);
      for(m = 0; m < nrows; m++) {
	for(n = 0; n < nfields; n++)
	  printf(" %s = %s(%d),", 
		 PQfname(result, n), 
		 PQgetvalue(result, m, n),
		 // rozmiar pola w bajtach
		 PQgetlength(result, m, n));
	printf("\n");
      }
    }
  }
  PQclear(result);
}


int main()
{

char host[] = "host=localhost";
char port[] = "port=5432";
char dbname[] = "dbname=";
char user[] = "user=";
char pass[] = "password=";
char dbname1[20];
char user1[20];
char *pass1;
char delete1[] = "DELETE FROM BOOK WHERE id=";
char delete2[50] = {0};
char modTitlePre[] = "UPDATE BOOK SET title='";
char modTitle[20];
char modAuthorPre[] = "', author='";
char modAuthor[30];
char modISBNPre[] = "', isbn='";
char modISBN[13];
char modRatingPre[] = "', rating=";
int modRating = 0;
char modRelDatePre[] = ", release_date='";
char modRelDate[12];
char modPublisherPre[] = "', publisher='";
char modPublisher[30];
char where[] = "' WHERE id=";
char update[150] = {0};





printf("Enter dbname: \n");
scanf("%s",dbname1);
printf("Enter user name: \n");
scanf("%s",user1);
pass1 = getpass("Enter password: \n");
//printf("Enter password: \n");
//scanf("%s",pass1);

int opt = -1;
int record;

char data[1024] = {0};
snprintf(data,sizeof(data),"%s %s %s%s %s%s %s%s",host,port,dbname,dbname1,user,user1,pass,pass1);

printf("%s\n",data);

PGconn *conn = PQconnectdb(data);

if(PQstatus(conn) == CONNECTION_OK)
{
printf("Connection made!\n");
printf("PGDBNAME = %s\n", PQdb(conn));
printf("PGUSER = %s\n", PQuser(conn));
printf("PGDPASSWORD = %s\n", PQpass(conn));
printf("PGDHOST = %s\n", PQhost(conn));
printf("PGDPORT = %s\n", PQport(conn));

while(1){


printf("1)Display records\n");
printf("2)Delete\n");
printf("3)Modify\n");
printf("4)To HTML\n");
printf("0)Exit\n");
scanf("%d",&opt);

switch(opt)
{
  case 1:
  doSQL(conn,"SELECT * FROM book");
  break;

  case 2:
  printf("Enter record ID to delete\n");
  scanf("%d",&record);
  snprintf(delete2,sizeof(delete2),"%s%d",delete1,record);
  doSQL(conn,delete2);
  break;

  case 3:
  printf("Enter record ID to modify\n");
  scanf("%d",&record);
  printf("Set new title: \n");
  scanf("%s",modTitle);
  printf("Set new author: \n");
  scanf("%s",modAuthor);
  printf("Set new isbn: \n");
  scanf("%s",modISBN);
  printf("Set new rating: \n");
  scanf("%d",&modRating);
  printf("Set new release date (format eg. \'2012-01-01\'): \n");
  scanf("%s",modRelDate);
  printf("Set new publisher: \n");
  scanf("%s",modPublisher);
  snprintf(update,sizeof(update),"%s%s%s%s%s%s%s%d%s%s%s%s%s%d%s",modTitlePre,modTitle,modAuthorPre,modAuthor,modISBNPre,modISBN,modRatingPre,modRating,modRelDatePre,modRelDate,modPublisherPre,modPublisher,where,record,";");
  printf("%s\n",update);
  doSQL(conn,update);
  break;

  case 4:
  toHTML();
  break;

  
  case 0:
  exit(0);
  break;

  default:
  printf("Wrong option\n");
  break;


}
}

}

else
 printf("Connection failed: %s\n", PQerrorMessage(conn));
PQfinish(conn);
return EXIT_SUCCESS;

return 0;
}
