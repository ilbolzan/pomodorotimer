@echo off
rem This is needed for machines that have other Ruby interpreters installed.
set rubyopt=

:Build
cls
"..\tools\Rake\bin\ruby.exe" "..\tools\Rake\bin\rake" %*

rem Bail if we're running a TeamCity build.
if defined TEAMCITY_PROJECT_NAME goto Quit

rem Loop the build script.
set CHOICE=nothing
echo (Q)uit, (Enter) runs the build again
set /P CHOICE= 
if /i "%CHOICE%"=="Q" goto :Quit

GOTO Build

:Quit