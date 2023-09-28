@echo off

set file_path=%~dp0%

@REM REM PostgreSQL连接信息
set psql_host=10.50.15.54
set psql_port=5432
set psql_db=emgda
set psql_user=emgda
set psql_password=Entrib!23

@REM REM 连接PostgreSQL数据库并执行SQL语句
%file_path%\postgresql\bin\psql.exe -h %psql_host% -p %psql_port% -d %psql_db% -U %psql_user% -W %psql_password% -c "UPDATE element SET collection_name = element_name"

@REM REM 输出提示信息
echo "Collection names updated in emgda database."
