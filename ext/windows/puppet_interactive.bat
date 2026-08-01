@echo off
SETLOCAL
echo Running OpenVox agent on demand ...
cd "%~dp0"
call puppet.bat agent --test %*
PAUSE
