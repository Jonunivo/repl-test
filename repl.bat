@echo off
setlocal

REM ===========================================
REM Replikationsskript
REM Verwendung:
REM   repl.bat test MM
REM   repl.bat prod MM
REM ===========================================

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set TARGET=%~1
set MA=%~2

if /I "%TARGET%"=="test" (
    set BRANCH=repl-test
) else if /I "%TARGET%"=="prod" (
    set BRANCH=repl-prod
) else (
    echo.
    echo Fehler: Erster Parameter muss "test" oder "prod" sein.
    goto :usage
)

echo.
echo ===========================================
echo Replikationsbranch: %BRANCH%
echo Mitarbeiter: %MA%
echo ===========================================
echo.

REM Aktuelles Datum YYYY-MM-DD erzeugen
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%i

echo Hole aktuelle Branches...
git fetch origin

REM Prüfen ob Branch lokal existiert
git show-ref --verify --quiet refs/heads/%BRANCH%
if errorlevel 1 (

    REM Existiert er remote?
    git ls-remote --exit-code --heads origin %BRANCH% >nul 2>&1

    if errorlevel 1 (
        echo Branch existiert nicht - wird erstellt.
        git checkout -b %BRANCH%
        git push -u origin %BRANCH%
    ) else (
        echo Branch existiert remote - wird ausgecheckt.
        git checkout -b %BRANCH% origin/%BRANCH%
    )
) else (
    git checkout %BRANCH%
)

echo.
echo Merge von main...
git merge --no-ff -m "Replikation %TODAY%-%MA%" main

if errorlevel 1 (
    echo.
    echo ***************************************
    echo Merge fehlgeschlagen!
    echo Bitte Konflikte beheben.
    echo ***************************************
    pause
    exit /b 1
)

echo.
echo Push...
git push origin %BRANCH%

if errorlevel 1 (
    echo Push fehlgeschlagen.
    pause
    exit /b 1
)

echo.
echo Zurueck zu main...
git checkout main

pause
exit /b 0

:usage
echo.
echo Verwendung:
echo   repl.bat test MA-Kuerzel
echo   repl.bat prod MA-Kuerzel
echo.
echo Beispiele:
echo   repl.bat test MM
echo   repl.bat prod AB
pause
exit /b 1