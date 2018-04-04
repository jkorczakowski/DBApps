#include<stdlib.h>
#include<stdio.h>
#include<libpq-fe.h>

int main()
{
PGconn *myconnection = PQconnectdb("host=localhost port=5432 dbname=BookShelfProject user=postgres password=psql9719");
if(PQstatus(myconnection) == CONNECTION_OK){
 printf("Connection made\n");
 printf("PGDBNAME = %s\n",PQdb(myconnection));
 printf("PGUSER = %s\n",PQuser(myconnection));
 printf("PGPASSWORD = %s\n",PQpass(myconnection));
 printf("PGHOST = %s\n",PQhost(myconnection));
 printf("PGDPORT = %s\n",PQport(myconnection));
 printf("OPTIONS = %s\n",PQoptions(myconnection));
}
else
 printf("Connection failed: %s\n", PQerrorMessage(myconnection));
PQfinish(myconnection);
return EXIT_SUCCESS;
}
