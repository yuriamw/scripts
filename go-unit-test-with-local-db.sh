#! /bin/bash -e

UNIT_TESTS_MSSQL_DB=${UNIT_TESTS_MSSQL_DB:-"TestSuiteDB"}
UNIT_TESTS_MSSQL_PASSWD=${UNIT_TESTS_MSSQL_PASSWD:-"ThisIs!Password"}

connection_string_mssql=""
connection_string_mssql="${connection_string_mssql}azuresqlcreatedb=${UNIT_TESTS_MSSQL_DB};"
connection_string_mssql="${connection_string_mssql}Server=tcp:localhost,1433;"
connection_string_mssql="${connection_string_mssql}Initial Catalog=master;"
connection_string_mssql="${connection_string_mssql}Persist Security Info=False;"
connection_string_mssql="${connection_string_mssql}User ID=sa;"
connection_string_mssql="${connection_string_mssql}Password=${UNIT_TESTS_MSSQL_PASSWD};"
connection_string_mssql="${connection_string_mssql}MultipleActiveResultSets=False;"
connection_string_mssql="${connection_string_mssql}TrustServerCertificate=False;"
connection_string_mssql="${connection_string_mssql}Connection Timeout=30;"

export UNIT_TESTS_MSSQL_CONNECTION_STRING="${connection_string_mssql}"

connection_string_mongodb="mongodb://localhost:27017/"
export UNIT_TESTS_COSMOSDB_CONNECTION_STRING=${UNIT_TESTS_COSMOSDB_CONNECTION_STRING:-"$connection_string_mongodb"}

go-unit-test.sh "$@"
