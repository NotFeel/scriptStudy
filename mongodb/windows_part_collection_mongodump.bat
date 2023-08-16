@echo off
setlocal enabledelayedexpansion

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

REM 清空 emgda 数据库
%file_path%\mongodb\bin\mongo.exe --host %mongo_host% --port %mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% %source_db% --eval "db.getSiblingDB('%source_db%').dropDatabase()"
%file_path%\mongodb\bin\mongo.exe --host %mongo_host% --port %mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% %source_db% --eval "db.dropDatabase()"


set "collection_array=default order features provisioing provisioning traceability orders"

for %%A in (%collection_array%) do (
    set "mongo_group_command=db.%%A.aggregate([{$group: {_id: \"\$elementName\"}}])"
    echo !mongo_group_command!

    for /f "usebackq delims=" %%B in (`%file_path%\mongodb\bin\mongo.exe --host %mongo_host% --port %mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% %target_db% --eval "!mongo_group_command!" ^| findstr "_id"`) do (
        set "line=%%B"
        for /f "tokens=2 delims=:\}" %%C in ("!line!") do (
            set "value=%%C"
            set "value=!value: =!"
            set "value=!value:"=!"
            echo Processing value: !value!
            set "backup_folder=%file_path%\collection\!value!"
            %file_path%\mongodb\bin\mongodump.exe --gzip -h %mongo_host%:%mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% --db %target_db% -c %%A --query "{ 'elementName': '!value!' }" --out "!backup_folder!"
        )
    )
)

endlocal
