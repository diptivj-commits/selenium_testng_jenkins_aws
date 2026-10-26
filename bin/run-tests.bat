@echo off
cd /d "%~dp0"
call mvn -B -ntp clean test
exit /b %ERRORLEVEL%
