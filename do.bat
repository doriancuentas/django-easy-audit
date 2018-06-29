@echo off
rem dorian cuentas
rem this script should be executed on venvironmbet cause python and pip are referenced directly

IF "%1%"=="help" (
    call :help %~f0
    GOTO:EOF
)

call %~dp0\importDefaultVariables.bat
set SCRIPT_PARAMS='%*'

FOR %%A IN (%*) DO (
    IF "%%A"=="" (
        echo end params procesing...
    GOTO _continue
    ) else (
        echo executing "%%A" function...
        echo calling : %%A with params : %*
        call :%%A '%*' && goto :_end || goto :_error
    )
)
:_continue

cd %PROJECT_DIR%
CALL :setencoding || call :_error setencoding
CALL :recreatedb || call :_error recreatedb
CALL :migrations || call :_error migrations
CALL :restoredb  || call :_error restoredb
CALL :diffmodels || call :_error diffmodels
CALL :_end

:setencoding
set PGCLIENTENCODING=utf-8
set client_encoding="UTF-8"
chcp 65001
echo.
EXIT /B 0

:backupdb
echo backingup...
CALL %DB_SCRIPT_DIR%\backup_db.bat
EXIT /B 0

:recreatedb
echo.
echo recreatedb...
call :venv || goto :_error
echo droping and creating...
CALL %DB_SCRIPT_DIR%\drop_and_create_db.bat || call :_error
cd %PROJECT_DIR% >nul 2>&1
python caladmi\manage.py check || call :_error
python caladmi\manage.py makemigrations
python caladmi\manage.py migrate
EXIT /B 0

:restoredb
echo.
echo restoredb...
echo working dir before run heavy restore : %PROJECT_DIR%
call %DB_SCRIPT_DIR%\restore_backup.bat %DB_SCRIPT_DIR%\121insert_instance_data.sql
call %DB_SCRIPT_DIR%\restore_backup.bat %DB_SCRIPT_DIR%\201cal_backup.sql
start %DB_SCRIPT_DIR%\restore_backup.bat %DB_SCRIPT_DIR%\202cal_backup.sql
start %DB_SCRIPT_DIR%\restore_backup.bat %DB_SCRIPT_DIR%\210update_sequences.sql
rem start python %PROJECT_DIR%\caladmi\manage.py consolidar_acopios
EXIT /B 0

:restoredbwith
echo.
echo restoredbwith...
call %DB_SCRIPT_DIR%\restore_backup.bat %*
EXIT /B 0

:diffmodels
echo.
echo diffmodels...
call :venv || goto :_error
rem python caladmi\manage.py createsuperuser
cd %PROJECT_DIR% >nul 2>&1
python caladmi\manage.py inspectdb > models.py.__back
start %DIFFTOOL%  caladmi\mainapp\models.py models.py.__back  || call :_errornobin difftool
echo done...
EXIT /B 0

:packexe
echo.
echo packexe...
call :_pack_common
%SEVEN_ZIP%  a %IGNORES% -mx9 -sfx %FILE_NAME_EXE% %SCRIPT_DIR%
echo done...
EXIT /B 0

:pack
echo.
echo pack...
call :_pack_common
%SEVEN_ZIP% a %IGNORES% -mx9 %FILE_NAME% %SCRIPT_DIR%
echo done...
echo done...
EXIT /B 0

:_pack_common
echo deleting previous
set FILE_NAME=%APP_NAME%_%GIT_IGNORE_CARD%.7z
set FILE_NAME_EXE=%APP_NAME%_%GIT_IGNORE_CARD%.7z.exe
set IGNORES=-xr!^%APP_NAME%\installers* -xr!^%APP_NAME%\caladmi\venv* -xr!^%APP_NAME%\.git* -xr!*pleaseignoremeingit* -x!^%APP_NAME%\doc* -x!^%APP_NAME%\res* -xr!%APP_NAME%\db\vp*
del %FILE_NAME% 2>nul
del %FILE_NAME_EXE% 2>nul
echo. 
echo creating new package
EXIT /B 

:runserver
echo.
echo runserver...
echo starting server
call :venv || goto :_error
%POSTGRES_HOME%\bin\pg_ctl -D %PGDATADIR% status && (
    echo db already started
) || (
    echo db not started, executing : "start /B "" sudo pg_ctl.exe -D %PGDATADIR% start"
    rem start cmd.exe /c start /B "" sudo pg_ctl.exe -D %PGDATADIR% start
    call start sudo %POSTGRES_HOME%\bin\pg_ctl.exe -D %PGDATADIR% start
)
echo.
python caladmi\manage.py runserver
EXIT /B 0

:configpg
echo.
echo configpg...
%POSTGRES_HOME%\initdb.exe -D %POSTGRES_HOME%\datadir --encoding=UTF-8 --no-locale --username=postgres --pwprompt
mkdir ..\logs
EXIT /B 0

:clearmigrations
echo.
echo clearmigrations...
call :venv || goto :_error
echo deleting migration files
call :venv || goto :_error
echo working dir : %DJANGO_ROOT_DIR%
echo current migrations...
python %DJANGO_ROOT_DIR%\manage.py showmigrations
%SCOOP_SHIMS%\gfind %DJANGO_ROOT_DIR% -path "*/migrations/*.py" -not -name "__init__.py" || call :_errornobin linux_find
%SCOOP_SHIMS%\gfind %DJANGO_ROOT_DIR% -path "*/migrations/*.py" -not -name "__init__.py" -delete || call :_errornobin linux_find
%SCOOP_SHIMS%\gfind %DJANGO_ROOT_DIR% -path "*/migrations/*.pyc" || call :_errornobin linux_find
%SCOOP_SHIMS%\gfind %DJANGO_ROOT_DIR% -path "*/migrations/*.pyc"  -delete  || call :_errornobin linux_find
echo cleared migrations...
python %DJANGO_ROOT_DIR%\manage.py showmigrations
EXIT /B 0

:dropdb
echo.
echo dropdb...
echo droping and creating...
CALL %DB_SCRIPT_DIR%\drop_db.bat || call :_error
cd %PROJECT_DIR%  >nul 2>&1
EXIT /B 0

:createdb
echo.
echo createdb...
echo droping and creating...
CALL %DB_SCRIPT_DIR%\create_db.bat || call :_error
cd %PROJECT_DIR% >nul 2>&1
EXIT /B 0

:dacdb
call :dropdb || call :_error
call :createdb || call :_error
EXIT /B 0

:createvenv
echo.
echo createvenv...
echo creating virtual environment if not exist...
call :venv || (
echo dropping previous...
cd %PROJECT_DIR% >nul 2>&1
if exist .\%VENVNAME%\ rmdir /s /q .\%VENVNAME%\ || call :_errornobin rmdir
echo creating new venev...
virtualenv.exe %VENVNAME% || call :_errornobin virtualenv.exe
echo installing requirements_dev...
call :venv || goto :_error
call :requirements || goto :_error
)
cd %PROJECT_DIR% >nul 2>&1
EXIT /B 0

:requirements
echo.
echo requirements...
call :venv || goto :_error
echo PROJECT_DIR : %PROJECT_DIR%
rem should prevent requirements install on system's python 
%SCRIPT_DIR%%VENVNAME%\Scripts\python.exe -m pip install --upgrade -r %DJANGO_ROOT_DIR%\requirements_dev.txt --ignore-installed || call :_errornobin python.exe
call :_buildandinstall_libs %DJANGO_ROOT_DIR%\hardlibs.txt
EXIT /B 0

:migrations
echo.
echo migrations...
echo run necesary migrations...
call :venv || goto _error"virtual env error"
call python %DJANGO_ROOT_DIR%\manage.py makemigrations || call :_errornobin 'python.exe missing or makemigrations fail'
rem call python %DJANGO_ROOT_DIR%\manage.py migrate easyaudit || call :_errornobin 'python.exe missing or migrate fail'
call python %DJANGO_ROOT_DIR%\manage.py migrate || call :_errornobin 'python.exe missing or migrate fail'
cd %PROJECT_DIR% >nul 2>&1
EXIT /B 0

:venv
echo.
echo virtual environment acitvation...
rem set CHECKVENV=%SCRIPT_DIR%%VENVNAME%\Scripts\python.exe -V
where python | grep %VENVNAME% >nul 2>&1 && (
    goto _venvalreadystarted
) || (
    goto _venvnotstarted
)
:_venvnotstarted
echo environment not active
echo changing virtual environment : %SCRIPT_DIR%%VENVNAME%\Scripts\activate.bat
echo %SCRIPT_DIR%%VENVNAME%\Scripts\activate.bat
call %SCRIPT_DIR%%VENVNAME%\Scripts\activate.bat && goto :_venvalreadystarted || goto :_venacterror
:_venvalreadystarted
echo virtual environment started...
call %~dp0\importDefaultVariables.bat
EXIT /B 0
:_venacterror
EXIT /B 5

:exitvenv
echo.
echo virtual environment deacitvation...
set CHECKVENV=%SCRIPT_DIR%%VENVNAME%\Scripts\python2.exe 
%CHECKVENV% >nul 2>&1 && (
    goto _venvalreadystarted
) || (
    goto _venvnotstarted
)
:_venvalreadystarted_exit
echo virtual environment started exiting...
call %SCRIPT_DIR%%VENVNAME%\Scripts\deactivate.bat && goto :_venvnotstarted_exit || goto :_venacterror_exit
:_venvnotstarted_exit
echo environment not active
call %~dp0\importDefaultVariables.bat
EXIT /B 0
:_venacterror_exit
EXIT /B 5

:installhardlibs
call :_buildandinstall_libs %DJANGO_ROOT_DIR%\hardlibs.txt
EXIT /B 0

rem TODO fixme not isntalling on venv
:_inshardlibs
set projects_rootdir=%PROJECT_PARENTDIR%
set projectname=%~1
set pythonbin=%SCRIPT_DIR%%VENVNAME%\Scripts\python.exe
call :venv || goto _error"virtual env error"
echo.
echo installing : %projectname%
echo    %pythonbin% %projects_rootdir%\%projectname%\setup.py build --force
echo    %pythonbin% %projects_rootdir%\%projectname%\setup.py install_lib --force
%pythonbin% %projects_rootdir%\%projectname%\setup.py build --force || call :_errornobin python.exe
%pythonbin% %projects_rootdir%\%projectname%\setup.py install --force || call :_errornobin python.exe
EXIT /B 0

:_buildandinstall_libs
@set local
@setlocal enableextensions enabledelayedexpansion
call :venv || goto _error"virtual env error"
echo.
set customList=%~f1
echo reading list from %customList%
if exist %customList% (
    echo installing packages from %customList%
    for /F "tokens=* delims=" %%P in (%customList%) do (
        set str1=%%P
        rem consider packages only if not start with #
        if "!str1:#=!"=="!str1!" (
            set libNameLine=%%P
            set variable1=
            set variable2=
            set /a count=0
            for %%i in (!libNameLine!) do (
                set /a count+=1
                set "variable!count!=%%i"
            )
                echo procesing %%P
                call :_inshardlibs !variable1!
            ) else (
                echo comment : !libNameLine! 
        )
    )
) else (
    echo file : %customList% missing
)
@endlocal
EXIT /B 0

:zerostart
echo.
echo starting project environment from zero...
call prepare_dev_environment.bat
echo project's dir %SCRIPT_DIR%
CALL :exitvenv      || call :_error exitvenv
CALL :createvenv    || call :_error createvenv
CALL :venv          || call :_error venv
CALL :setencoding   || call :_error setencoding
CALL :clearmigrations   || call :_error clearmigrations
CALL :dropdb        || call :_error dropdb
CALL :createdb      || call :_error createdb
CALL :migrations    || call :_error migrations
CALL :restoredb     || call :_error restoredb
CALL :_end
EXIT /B 0


:_end
EXIT /B 0

:_error
echo .
echo .
echo ERROR : general error params : %* 
echo .
echo VARIABLES :
call %~dp0\importDefaultVariables.bat debug
echo.
echo SCRIPT PARAMS : %SCRIPT_PARAMS%
cd %PROJECT_DIR% >nul 2>&1
set ERRORLEVEL=5
GOTO:EOF

:_errornobin
echo .
echo .
echo ERROR : exe not found or return error code : %~1 %~2 
echo did you run "prepare_dev_environment.bat", or reload environment?
echo VARIABLES :
call %~dp0\importDefaultVariables.bat debug
echo.
echo SCRIPT PARAMS : %SCRIPT_PARAMS%
cd %PROJECT_DIR% >nul 2>&1
set ERRORLEVEL=5
GOTO:EOF

:help 
echo "%~1 %~2"
for /f "delims=" %%a in ('findstr /r /b /c:":[a-z].*" "%~1"') do echo %%a
EXIT /B 0

