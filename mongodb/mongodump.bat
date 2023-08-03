@echo off
echo "%~dp0%"
echo "%cd%"

set file_path=%~dp0%

if not exist %file_path%backup\zipFile\ md %file_path%backup\zipFile\

set zip_path=%file_path%backup\zipFile

set temporary_path=%~dp0%backup\temporaryFile

set "sevenZipPath=C:\Program Files\7-Zip\7z.exe"

REM 压缩昨天文件

echo Start Compressing Yesterday MongoDB Data...


REM 使用 for /D 循环遍历 temporaryFile 文件夹中的子目录
set "isEmptyFolder=true"
for /D %%I in ("%temporary_path%\*") do set "isEmptyFolder=false" & goto :break

:break

REM 判断是否为空文件夹
if "%isEmptyFolder%"=="true" (
  echo %temporary_path%: is empty. Skipping the loop.
  goto :end
)

for /D %%D in ("%temporary_path%\*") do set yesterday_name=%%~nxD

REM 使用 7-Zip 压缩文件（需要先安装 7-Zip 并将其添加到环境变量）
"%sevenZipPath%" a -r -tzip "%zip_path%\%yesterday_name%.zip" "%temporary_path%\*"

echo End Compressing Yesterday MongoDB Data

REM 删除昨天文件
echo Start Remove Yesterday MongoDB Data...

rd /S /Q "%temporary_path%"

echo End Remove Yesterday MongoDB Data

:end

REM 备份今天数据
echo Start Backup Today Mongodb Data...

REM 获取当前日期
for /F "tokens=2 delims==." %%A in ('wmic OS Get localdatetime /value') do (
    set "datetime=%%A"
)
REM 提取日期部分
set "current_date=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%"

%file_path%\mongodb\bin\mongodump.exe --gzip -h 10.50.15.54:27017 -d emgda --username emgda --password ShopWorx110T --out %temporary_path%\%current_date%\

echo End Backup Today Mongodb Data

pause
