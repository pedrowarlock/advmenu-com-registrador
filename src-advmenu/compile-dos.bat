@echo off

copy Makefile.usr Makefile

set DJGPP=c:\DJGPP\DJGPP.ENV
PATH C:\DJGPP\BIN;%PATH%

stubedit c:\djgpp\bin\gcc.exe bufsize=32k
stubedit c:\djgpp\bin\gpp.exe bufsize=32k
stubedit c:\djgpp\bin\ld.exe bufsize=32k
stubedit c:\djgpp\bin\make.exe bufsize=32k
stubedit c:\djgpp\lib\gcc-lib\djgpp\3.23\collect2.exe bufsize=32k

make

pause