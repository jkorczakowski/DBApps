#include<stdlib.h>
#include<stdio.h>
#include<libpq-fe.h>

void doSQL(PGconn *conn, char *command)
{
  PGresult *result;

//  printf("%s\n", command);

  result = PQexec(conn, command);
//  printf("status is %s\n", PQresStatus(PQresultStatus(result)));
//  printf("#rows affected %s\n", PQcmdTuples(result));
//  printf("result message: %s\n", PQresultErrorMessage(result));

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
char pass1[20];

printf("Enter dbname: \n");
scanf("%s",dbname1);
printf("Enter user name: \n");
scanf("%s",user1);
printf("Enter password: \n");
scanf("%s",pass1);

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
doSQL(conn, "SELECT * from book");
}

else
 printf("Connection failed: %s\n", PQerrorMessage(conn));
PQfinish(conn);
return EXIT_SUCCESS;

return 0;
}
