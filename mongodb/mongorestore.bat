@echo off
echo "%~dp0%"
echo "%cd%"

set file_path=%~dp0%

set temporary_path=%~dp0%backup\temporaryFile

echo Start MongoDB Data Restore...

REM 获取当前日期
for /F "tokens=2 delims==." %%A in ('wmic OS Get localdatetime /value') do (
    set "datetime=%%A"
)
REM 提取日期部分
set "current_date=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%"

echo Current Date: %current_date%

REM 检查备份文件路径是否正确
if not exist "%temporary_path%\%current_date%" (
    echo Backup file path not found: "%temporary_path%\%current_date%"
    echo Exiting the script...
    pause
    exit /b 1
)

start /wait %file_path%\mongodb\bin\mongorestore.exe --gzip --host 10.50.15.54 --port 27020 --username emgda --password ShopWorx110T -d emgda --drop "%temporary_path%\%current_date%\emgda"

echo Restore MongoDB Data END

echo Start Restart MongoDB Server

net stop "My MongoDB"

timeout /t 5 >null

net start "My MongoDB"

echo End Restart MongoDB Server

pause
