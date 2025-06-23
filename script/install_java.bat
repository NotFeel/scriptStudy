@echo off
echo "%~dp0%"
echo "%cd%"

set file_path=%~dp0%

echo "start install mysql"

%file_path%mysql\bin\mysqld.exe --initialize-insecure --user=mysql --console

%file_path%mysql\bin\mysqld.exe --install

net start mysql

%file_path%mysql\bin\mysql.exe -u root < %file_path%mysql\init\ruhlamat.sql

%file_path%mysql\bin\mysql.exe -u root < %file_path%mysql\init\init_account.sql

echo "end install Ruhlasmart Mysql"

echo "start install Ruhlasmart Redis"

%file_path%\redis\redis-server.exe --service-install %file_path%\redis\redis.windows.conf --service-name "Ruhlasmart Redis" --port 6379

net start "Ruhlasmart Redis"

echo "end install Ruhlasmart Redis"

echo "start install nginx"

%file_path%\nssm\win64\nssm.exe install "Ruhlasmart Nginx" %file_path%\nginx\nginx.exe

net start "Ruhlasmart Nginx"

echo "end install nginx"

echo "start install admin"

%file_path%\nssm\win64\nssm.exe install "Ruhlasmart Admin" %file_path%\java\jdk\bin\java
%file_path%\nssm\win64\nssm.exe set "Ruhlasmart Admin" AppParameters  -jar "-Xms1024M" "-Xmx2048M" "-Dfile.encoding=UTF-8" "-Duser.timezone=Asia/Shanghai" "-XX:MetaspaceSize=256m" "-XX:MaxMetaspaceSize=512m" "-XX:+HeapDumpOnOutOfMemoryError" "-XX:HeapDumpPath=%file_path%\admin\hprof\dump_%t_%p.hprof" "-XX:OnOutOfMemoryError=cmd /c taskkill /pid %p /t /f" "%file_path%\admin\minions-admin.jar" "--spring.config.location=%file_path%\admin\application.yml"
%file_path%\nssm\win64\nssm.exe set "Ruhlasmart Admin" AppDirectory %file_path%\admin
%file_path%\nssm\win64\nssm.exe set "Ruhlasmart Admin" AppStderr %file_path%\admin\daemon\error.log

net start "Ruhlasmart Admin"

echo "end install Admin"

pause