@echo off

setlocal
set file_path=%~dp0%

set mongo_host=10.50.15.54
set mongo_port=27017
set mongo_username=emgda-root
set mongo_password=ShopWorx110T

set source_db=emgda
set target_db=emgda1

set "dump_path=%file_path%\mongodbDump\"

if not exist %dump_path% md %dump_path%

%file_path%\mongodb\bin\mongodump.exe --gzip -h %mongo_host%:%mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% --db %source_db% --out %dump_path%

%file_path%\mongodb\bin\mongorestore.exe --gzip -h %mongo_host%:%mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% --db %target_db% --dir %dump_path%/%source_db% --drop

rd /s /q %dump_path%

endlocal
