@echo off
set BUNDLER_PATH="%~dp0../bundler"

set directory="%cd%"
cd %BUNDLER_PATH%
call npm i
cd "%directory%"
