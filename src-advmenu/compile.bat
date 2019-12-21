@echo off
copy Makefile.usr Makefile
path ..\bin
mingw32-make.exe
pause