@echo off
set LIBRARY_PATH="%~dp0.."

call node "%LIBRARY_PATH%/bundler" create "%LIBRARY_PATH%" %*
