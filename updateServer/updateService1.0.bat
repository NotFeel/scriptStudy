@echo off
setlocal enabledelayedexpansion
echo "==========================UPDATE SERVICE SCRIPT START=========================="
echo "%~dp0%"
set "SCRIPT_PATH=%~dp0%"

@REM nginx注册服务名
set "nginxServiceName=Ruhlasmart Nginx"
@REM planning注册服务名
set "planningServiceName=Ruhlasmart Planning"
@REM mdo注册服务名
set "mdoServiceName=Ruhlasmart Mdo"
@REM linemescache注册服务名
set "linemescacheServiceName=Ruhlasmart LineMes Cache"
@REM traceability注册服务名
set "traceabilityServiceName=Ruhlasmart Traceability"
@REM downtime注册服务名
set "downtimeServiceName=Ruhlasmart Downtime"
@REM eapa注册服务名
set "eapaServiceName=Ruhlasmart {sublineNumber} EAPA"
set "sublineNumber=Example"
@REM 时间戳
set "timestamp=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%"

@REM LMS绝对路径
set /p LMS_PATH="------------------------->Please enter the absolute path of the LMS package: "
set "LMS_PATH=!LMS_PATH: =!"
if not exist "!LMS_PATH!\" (
    echo "Invalid LMS path. The specified directory does not exist. ERROR !LMS_PATH!"
    pause
    goto :eof
) else (
    echo "This is the LMS path you entered:!LMS_PATH!"
)

echo.

@REM LMSEAPA绝对路径
set /p LMSEAPA_PATH="------------------------->Please enter the absolute path of the LMSEAPA package: "
set "LMSEAPA_PATH=!LMSEAPA_PATH: =!"
if not exist "!LMSEAPA_PATH!\" (
    echo "Invalid LMSEAPA path. The specified directory does not exist. ERROR !LMSEAPA_PATH!"
    pause
    goto :eof
) else (
    echo "This is the LMSEAPA path you entered:!LMSEAPA_PATH!"
)


@REM pg新增表
if exist "%SCRIPT_PATH%\pgElement\database" (
   "%LMS_PATH%\python\python.exe" "%SCRIPT_PATH%\pgElement\database\updateElement_add(pg).py"
)

echo.

@REM pg的增删改操作
set "psql_host=127.0.0.1"
set "psql_port=5432"
set "psql_db=emgda"
set "psql_user=emgda"
set "PGPASSWORD=Entrib^!23"
set "modifySQLFilePath=%SCRIPT_PATH%\PGSQL\modifyPGSQL.sql"
if exist "%modifySQLFilePath%" (
    for %%A in ("%modifySQLFilePath%") do (
        if %%~zA equ 0 (
            echo "modifySQLFilePath is empty, skipping logic."
        ) else (
            echo "modifying PostgreSQL table."
            !LMS_PATH!\postgresql\bin\psql.exe -h !psql_host! -p !psql_port! -U !psql_user! -d !psql_db! -f "!modifySQLFilePath!"
            set PGPASSWORD=
            echo "modified PostgreSQL table."
        )
    )
)

echo.

@REM mdo更新服务
if exist "%SCRIPT_PATH%\backend\mdo" (
    echo ">>>>>>>>>>>>Updating `%mdoServiceName%` service."
    if exist "%SCRIPT_PATH%\backend\mdo\mdo.jar" (
        @REM 停服务
        net stop "%planningServiceName%"
        net stop "%traceabilityServiceName%"
        net stop "%linemescacheServiceName%"
        net stop "%downtimeServiceName%"
        for /d %%i in ("%LMSEAPA_PATH%\eapa\*") do (
            set sublineNumberFileName=%%~nxi
            set "formattedEapaServiceName=%eapaServiceName:{sublineNumber}=!sublineNumberFileName!%"
            net stop "!formattedEapaServiceName!"
        )
        net stop "%mdoServiceName%"
        for %%F in (%LMS_PATH%\mdo\mdo.jar) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!%!extension!"
        )
        copy "%SCRIPT_PATH%\backend\mdo\mdo.jar" "%LMS_PATH%\mdo\"
        @REM 启服务
        net start "%planningServiceName%"
        net start "%traceabilityServiceName%"
        net start "%linemescacheServiceName%"
        net start "%downtimeServiceName%"
        net start "%mdoServiceName%"
        for /d %%i in ("%LMSEAPA_PATH%\eapa\*") do (
            set sublineNumberFileName=%%~nxi
            set "formattedEapaServiceName=%eapaServiceName:{sublineNumber}=!sublineNumberFileName!%"
            net start "!formattedEapaServiceName!"
        )
        echo "<<<<<<<<<<<<Updated `%mdoServiceName%` service."
    ) else (
        echo "mdo.jar file not found"
    )
    @REM 若有配置文件复制配置文件
    if exist "%SCRIPT_PATH%\backend\mdo\application.yml" (
        set "serviceYmlPath=%SCRIPT_PATH%\application_mdo_temp.yml"
        (for /f "usebackq delims=" %%i in (`type "%LMS_PATH%\mdo\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) > "!serviceYmlPath!"
        echo. >> "!serviceYmlPath!"
        (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\mdo\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) >> "!serviceYmlPath!"
        for %%F in (%LMS_PATH%\mdo\application.yml) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "!serviceYmlPath!" "%LMS_PATH%\mdo\application.yml"
        del !serviceYmlPath!
    )
)

echo.

@REM planning更新服务
if exist "%SCRIPT_PATH%\backend\planning" (
    echo ">>>>>>>>>>>>Updating `%planningServiceName%` service."
    if exist "%SCRIPT_PATH%\backend\planning\planning.jar" (
        net stop "%planningServiceName%"
        for %%F in (%LMSEAPA_PATH%\planning\planning.jar) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "%SCRIPT_PATH%\backend\planning\planning.jar" "%LMSEAPA_PATH%\planning\"
        net start "%planningServiceName%"
        echo "<<<<<<<<<<<<Updated `%planningServiceName%` service."
    ) else (
        echo "planning.jar file not found"
    )
    @REM 若有配置文件复制配置文件
    if exist "%SCRIPT_PATH%\backend\planning\application.yml" (
        set "serviceYmlPath=%SCRIPT_PATH%\application_planning_temp.yml"
        (for /f "usebackq delims=" %%i in (`type "%LMSEAPA_PATH%\planning\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) > "!serviceYmlPath!"
        echo. >> "!serviceYmlPath!"
        (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\planning\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) >> "!serviceYmlPath!"
        for %%F in (%LMSEAPA_PATH%\planning\application.yml) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "!serviceYmlPath!" "%LMSEAPA_PATH%\planning\application.yml"
        del !serviceYmlPath!
    )
)

echo.

@REM traceability更新服务
if exist "%SCRIPT_PATH%\backend\traceability" (
    echo ">>>>>>>>>>>>Updating `%traceabilityServiceName%` service."
    if exist "%SCRIPT_PATH%\backend\traceability\traceability.jar" (
        net stop "%traceabilityServiceName%"
        for %%F in (%LMSEAPA_PATH%\traceability\traceability.jar) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "%SCRIPT_PATH%\backend\traceability\traceability.jar" "%LMSEAPA_PATH%\traceability\"
        net start "%traceabilityServiceName%"
        echo "<<<<<<<<<<<<Updated `%traceabilityServiceName%` service."
    ) else (
        echo "traceability.jar file not found."
    )
    @REM 若有配置文件复制配置文件
    if exist "%SCRIPT_PATH%\backend\traceability\application.yml" (
        set "serviceYmlPath=%SCRIPT_PATH%\application_traceability_temp.yml"
        (for /f "usebackq delims=" %%i in (`type "%LMSEAPA_PATH%\traceability\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) > "!serviceYmlPath!"
        echo. >> "!serviceYmlPath!"
        (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\traceability\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) >> "!serviceYmlPath!"
        for %%F in (%LMSEAPA_PATH%\traceability\application.yml) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "!serviceYmlPath!" "%LMSEAPA_PATH%\traceability\application.yml"
        del !serviceYmlPath!
    )
)

echo.

@REM linemescache更新服务
if exist "%SCRIPT_PATH%\backend\linemescache" (
    echo ">>>>>>>>>>>>Updating `%linemescacheServiceName%` service."
    if exist "%SCRIPT_PATH%\backend\linemescache\linemescache.jar" (
        net stop "%linemescacheServiceName%"
        for %%F in (%LMSEAPA_PATH%\linemescache\linemescache.jar) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "%SCRIPT_PATH%\backend\linemescache\linemescache.jar" "%LMSEAPA_PATH%\linemescache\"
        net start "%linemescacheServiceName%"
        echo "<<<<<<<<<<<<Updated `%linemescacheServiceName%` service."
    ) else (
        echo "linemescache.jar file not found."
    )
    @REM 若有配置文件复制配置文件
    if exist "%SCRIPT_PATH%\backend\linemescache\application.yml" (
        set "serviceYmlPath=%SCRIPT_PATH%\application_linemescache_temp.yml"
        (for /f "usebackq delims=" %%i in (`type "%LMSEAPA_PATH%\linemescache\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) > "!serviceYmlPath!"
        echo. >> "!serviceYmlPath!"
        (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\linemescache\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) >> "!serviceYmlPath!"
        for %%F in (%LMSEAPA_PATH%\linemescache\application.yml) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "!serviceYmlPath!" "%LMSEAPA_PATH%\linemescache\application.yml"
        del !serviceYmlPath!
    )
)

echo.

@REM downtime更新服务
if exist "%SCRIPT_PATH%\backend\downtime" (
    echo ">>>>>>>>>>>>Updating `%downtimeServiceName%` service."
    if exist "%SCRIPT_PATH%\backend\downtime\downtime.jar" (
        net stop "%downtimeServiceName%"
        for %%F in (%LMSEAPA_PATH%\downtime\downtime.jar) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "%SCRIPT_PATH%\backend\downtime\downtime.jar" "%LMSEAPA_PATH%\downtime\"
        net start "%downtimeServiceName%"
        echo "<<<<<<<<<<<<Updated `%downtimeServiceName%` service"
    ) else (
        echo "downtime.jar file not found."
    )
    @REM 若有配置文件复制配置文件
    if exist "%SCRIPT_PATH%\backend\downtime\application.yml" (
        set "serviceYmlPath=%SCRIPT_PATH%\application_downtime_temp.yml"
        (for /f "usebackq delims=" %%i in (`type "%LMSEAPA_PATH%\downtime\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) > "!serviceYmlPath!"
        echo. >> "!serviceYmlPath!"
        (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\downtime\application.yml" ^| findstr /N ".*"`) do (
            set "line=%%i"
            set "line=!line:*:=!"
            echo.!line!
        )) >> "!serviceYmlPath!"
        for %%F in (%LMSEAPA_PATH%\downtime\application.yml) do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "!serviceYmlPath!" "%LMSEAPA_PATH%\downtime\application.yml"
        del !serviceYmlPath!
    )
)

echo.

@REM eapa更新服务
if exist "%SCRIPT_PATH%\backend\eapa" (
    echo ">>>>>>>>>>>>Updating `EAPA` Service"
    @REM 检查到eapa jar包有
    if exist "%SCRIPT_PATH%\backend\eapa\eapa.jar" (

        for /d %%i in ("%LMSEAPA_PATH%\eapa\*") do (
            set sublineNumber=%%~nxi
            choice /c YN /M "----------------==============>Do you want to update sublineNumber `!sublineNumber!` service?"
            set "choice=!errorlevel!"
            if !choice! == 1 (
                @REM 替换eapa 注册服务名
                set "formattedEapaServiceName=%eapaServiceName:{sublineNumber}=!sublineNumber!%"
                echo ">>>>>>>>>>>>>>>>>>>> Updating `!formattedEapaServiceName!` service. <<<<<<<<<<<<<<<<<<<"
                echo.
                @REM 停止对应 eapa服务
                net stop "!formattedEapaServiceName!"
                @REM 开始copy jar包
                for %%F in (%LMSEAPA_PATH%\eapa\!sublineNumber!\eapa.jar) do (
                    set "filename=%%~nF"
                    set "extension=%%~xF"
                    ren "%%F" "!filename!_%timestamp%!extension!"
                )
                copy "%SCRIPT_PATH%\backend\eapa\eapa.jar" "%LMSEAPA_PATH%\eapa\!sublineNumber!\"
                net start "!formattedEapaServiceName!"
                echo "<<<<<<<<<<<<<<<<<<< Updated `!formattedEapaServiceName!` service. >>>>>>>>>>>>>>>>>>>>"
                echo.
                @REM 若有配置文件复制配置文件
                if exist "%SCRIPT_PATH%\backend\eapa\application.yml" (
                    set "serviceYmlPath=%SCRIPT_PATH%\application_eapa_temp.yml"
                    (for /f "usebackq delims=" %%i in (`type "%LMSEAPA_PATH%\eapa\application.yml" ^| findstr /N ".*"`) do (
                        set "line=%%i"
                        set "line=!line:*:=!"
                        echo.!line!
                    )) > "!serviceYmlPath!"
                    echo. >> "!serviceYmlPath!"
                    (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\eapa\application.yml" ^| findstr /N ".*"`) do (
                        set "line=%%i"
                        set "line=!line:*:=!"
                        echo.!line!
                    )) >> "!serviceYmlPath!"
                    for %%F in (%LMSEAPA_PATH%\eapa\!sublineNumber!\application.yml) do (
                        set "filename=%%~nF"
                        set "extension=%%~xF"
                        ren "%%F" "!filename!_%timestamp%!extension!"
                    )
                    copy "!serviceYmlPath!" "%LMSEAPA_PATH%\eapa\!sublineNumber!\application.yml"
                    del !serviceYmlPath!
                ) else (
                    echo "no !sublineNumber! eapa application.yml"
                )
            ) else if !choice! == 2 (
               echo Skipping folder "!sublineNumber!"
            )
        )
        @REM 更新外面的jar包
        for %%F in ("%LMSEAPA_PATH%\eapa\eapa.jar") do (
            set "filename=%%~nF"
            set "extension=%%~xF"
            ren "%%F" "!filename!_%timestamp%!extension!"
        )
        copy "%SCRIPT_PATH%\backend\eapa\eapa.jar" "%LMSEAPA_PATH%\eapa\"
        @REM 更新外面的配置文件
        if exist "%SCRIPT_PATH%\backend\eapa\application.yml" (
            set "serviceYmlPath=%SCRIPT_PATH%\application_eapa_temp.yml"
            (for /f "usebackq delims=" %%i in (`type "%LMSEAPA_PATH%\eapa\application.yml" ^| findstr /N ".*"`) do (
                set "line=%%i"
                set "line=!line:*:=!"
                echo.!line!
            )) > "!serviceYmlPath!"
            echo.>> "!serviceYmlPath!"
            (for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\backend\eapa\application.yml" ^| findstr /N ".*"`) do (
                set "line=%%i"
                set "line=!line:*:=!"
                echo.!line!
            )) >> "!serviceYmlPath!"
            for %%F in (%LMSEAPA_PATH%\eapa\application.yml) do (
                set "filename=%%~nF"
                set "extension=%%~xF"
                ren "%%F" "!filename!_%timestamp%!extension!"
            )
            copy "!serviceYmlPath!" "%LMSEAPA_PATH%\eapa\application.yml"
            del !serviceYmlPath!
        ) else (
            echo "no eapa application.yml"
        )
    ) else (
        echo "eapa.jar file not found."
    )
)

echo.

@REM 更新前端infinity
if exist "%SCRIPT_PATH%\frontend\infinity" (
    echo ">>>>>>>>>>>>Updating Front-end infinity dist."
    if exist "%SCRIPT_PATH%\frontend\infinity\dist" (
        rename "%LMS_PATH%\nginx\html\infinity\dist" "dist_"%timestamp%
        xcopy "%SCRIPT_PATH%\frontend\infinity\dist" "%LMS_PATH%\nginx\html\infinity\dist" /E /I /Y
        echo "<<<<<<<<<<<<Updated Front-end infinity dist."
    ) else (
        echo "infinity dist file not found."
    )
)

echo.

@REM 新增前端看板
if exist "%SCRIPT_PATH%\frontend\dashboard" (
    echo ">>>>>>>>>>>>>>>Add dashboard"
    if exist "%SCRIPT_PATH%\frontend\dashboard\*" (
        for /d %%i in ("%SCRIPT_PATH%\frontend\dashboard\*") do (
            set dashboardName=%%~nxi
            @REM 复制到nginx的html目录下
            xcopy "%SCRIPT_PATH%\frontend\dashboard\!dashboardName!" "%LMS_PATH%\nginx\html\!dashboardName!" /E /I /Y
            @REM 若有配置文件，追加内容
            if exist "%SCRIPT_PATH%\frontend\dashboard\!dashboardName!\nginx.conf" (
                net stop "%nginxServiceName%"
                set "dashboardTempFilePath=%SCRIPT_PATH%\dashboardTemp.conf"
                @REM nginx配置文件，最后需要跳过的行数
                set "nginxConfSkipLine=9"
                @REM 获取nginx配置文件全部行数
                for /f %%c in ('type %LMS_PATH%\nginx\conf\nginx.conf ^| find /c /v ""') do set "totalLines=%%c"
                @REM nginx配置文件插入追加的位置
                set /a "startLine=totalLines - nginxConfSkipLine + 1"
                @REM nginx配置文件和看板配置融合
                (for /f "usebackq delims=" %%i in (`type "%LMS_PATH%\nginx\conf\nginx.conf" ^| findstr /N ".*"`) do (
                    set /a "currentLine+=1"
                    set "line=%%i"
                    set "line=!line:*:=!"
                    if !currentLine! equ !startLine! (
                        @REM 在这里执行与目标行相等时的逻辑
                        echo.
                        for /f "usebackq delims=" %%i in (`type "%SCRIPT_PATH%\frontend\dashboard\!dashboardName!\nginx.conf" ^| findstr /N ".*"`) do (
                            set "line=%%i"
                            set "line=!line:*:=!"
                            echo.!line!
                        )
                        echo.
                    ) else (
                        @REM 在这里执行与目标行不相等时的逻辑
                        echo.!line!
                    )
                )) > "!dashboardTempFilePath!" 
                @REM 开始copy nginx.conf 文件
                for %%F in (%LMS_PATH%\nginx\conf\nginx.conf) do (
                    set "filename=%%~nF"
                    set "extension=%%~xF"
                    ren "%%F" "!filename!_%timestamp%!extension!"
                )
                copy "!dashboardTempFilePath!" "%LMS_PATH%\nginx\conf\nginx.conf"
                net start "%nginxServiceName%"
                del !dashboardTempFilePath!
            )
        )
    )
)

echo.

echo "==========================UPDATE SERVICE SCRIPT END=========================="
endlocal
pause
