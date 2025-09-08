@ECHO OFF

call "%~dp0environment.bat" %0 %*

REM Display Ruby version
ruby.exe -v
