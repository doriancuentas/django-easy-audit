@echo off
rem default variable paths and other common script values
rem dorian cuentas
rem

rem echo %%~dp0 is "%~dp0"
rem echo %%0 is "%0"
rem echo %%~dpnx0 is "%~dpnx0"
rem echo %%~f1 is "%~f1"
rem echo %%~dp0%%~1 is "%~dp0%~1"

IF "%1%"=="debug" (
    call :debug 
    goto :_finish
)

for %%* in (.) do set APP_NAME=%%~nx*

set SCRIPT_DIR=%~dp0
IF %SCRIPT_DIR:~-1%==\ SET PROJECT_DIR=%SCRIPT_DIR:~0,-1%
set PROJECT_PARENTDIR=%PROJECT_DIR%\..

set DB_SCRIPT_DIR=%SCRIPT_DIR%db
set DJANGO_ROOT_DIR=%SCRIPT_DIR%easyaudit
set WORKING_DIR=%cd%
set POSTGRES_HOME=%UserProfile%\scoop\apps\postgresql\current
set POSTGRES_PGDATA=%POSTGRES_HOME%\datadir
set GIT_IGNORE_CARD=pleaseignoremeingit

set PSQL=psql.exe
set DIFFTOOL=C:\usr\local\Meld\meld\meld.exe
set UNIX_FIND=%UserProfile%\scoop\apps\cygwin\current\root\bin\find.exe
set SCOOP_SHIMS=%UserProfile%\scoop\shims
set SYSTEMPYTHONBIN=%SCOOP_SHIMS%\python
set VENVNAME=venv

set SEVEN_ZIP=7z.exe

IF "%1%"=="print" (
    call :debug 
    goto :_finish
)

goto :_finish

:debug
echo APP_NAME           :  %APP_NAME%
echo SCRIPT_DIR         :  %SCRIPT_DIR%
echo PROJECT_PARENTDIR  :  %PROJECT_PARENTDIR%
echo DB_SCRIPT_DIR      :  %DB_SCRIPT_DIR%
echo DJANGO_ROOT_DIR    :  %DJANGO_ROOT_DIR%
echo WORKING_DIR        :  %WORKING_DIR%
echo POSTGRES_HOME      :  %POSTGRES_HOME%
echo POSTGRES_PGDATA    :  %POSTGRES_PGDATA%
echo GIT_IGNORE_CARD    :  %GIT_IGNORE_CARD%
echo VENVNAME           :  %VENVNAME%
echo SCOOP_SHIMS        :  %SCOOP_SHIMS%
echo SYSTEMPYTHONBIN    :  %SYSTEMPYTHONBIN%
echo UNIX_FIND          :  %UNIX_FIND%
echo PSQL               :  %PSQL%
echo DIFFTOOL           :  %DIFFTOOL%
goto :_finish
EXIT /B 0

:_finish
EXIT /B 0

:_exit_error
EXIT /B 5


