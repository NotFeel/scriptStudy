@echo off
setlocal enabledelayedexpansion

set file_path=%~dp0%

set mongo_host=10.50.15.54
set mongo_port=27017
set mongo_username=emgda-root
set mongo_password=ShopWorx110T

set source_db=emgda
set target_db=emgda1

set "collection_array=default order features provisioing provisioning traceability orders"

for %%A in (%collection_array%) do (
    set "mongo_group_command=db.%%A.aggregate([{$group: {_id: \"\$elementName\"}}])"

    for /f "usebackq delims=" %%B in (`%file_path%\mongodb\bin\mongo.exe --host %mongo_host% --port %mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% %target_db% --eval "DBQuery.shellBatchSize=1000;!mongo_group_command!" ^| findstr "_id"`) do (
        set "line=%%B"
        for /f "tokens=2 delims=:\}" %%C in ("!line!") do (
            set "value=%%C"
            set "value=!value: =!"
            set "value=!value:"=!"
            echo Processing value: !value!

            set "create_collection_command=db.createCollection(\"!value!\")"
            %file_path%\mongodb\bin\mongo.exe --host %mongo_host% --port %mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% %source_db% --eval "!create_collection_command!" > null

            set backup_folder=%file_path%\collection\!value!\%target_db%
            %file_path%\mongodb\bin\mongorestore.exe --gzip -h %mongo_host%:%mongo_port% --authenticationDatabase admin -u %mongo_username% -p %mongo_password% -d %target_db% --dir "!backup_folder!" --nsFrom="%target_db%.%%A" --nsTo="%source_db%.!value!" --drop > null
        )
    )
)

endlocal
