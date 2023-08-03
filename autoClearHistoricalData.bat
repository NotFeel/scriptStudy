@echo off
setlocal enabledelayedexpansion

set "zipFilePath=%~dp0%backup\zipFile"
set "DaysToKeep=7"

REM 获取当前日期
for /F "tokens=2 delims==." %%A in ('wmic OS Get localdatetime /value') do (
    set "datetime=%%A"
)
REM 提取日期部分（格式为 yyyy-MM-dd）
set "current_date=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%"

REM 计算 7 天前的日期
for /F "tokens=1-3 delims=-" %%B in ("%current_date%") do (
    set /A "year=%%B", "month=1%%C-100", "day=1%%D-100", "DaysToKeep=%DaysToKeep%"
    set /A "totalDays=year*365+month*30+day"
    set /A "targetDays=totalDays-DaysToKeep+1"
)
REM 枚举指定目录下的所有压缩包文件
for %%F in ("%zipFilePath%\*.zip") do (
    set "fileName=%%~nxF"
    set "fileDate=%%~nF"

    REM 获取文件的日期
    for /F "tokens=1-3 delims=-" %%B in ("!fileDate!") do (
        set /A "fileYear=%%B", "fileMonth=1%%C-100", "fileDay=1%%D-100"
        set /A "fileTotalDays=fileYear*365+fileMonth*30+fileDay"

        REM 检查文件是否是 7 天前的文件，如果是则删除文件
        if !fileTotalDays! lss !targetDays! (
            echo Deleting file: %%F
            del /F /Q "%%F"
        )
    )
)

echo Deletion of old zip files completed.

pause
