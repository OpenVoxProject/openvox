@echo off
SETLOCAL

call "%~dp0environment.bat" %0 %*

ruby -S -- facter %*
