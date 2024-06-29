@echo off
setlocal enabledelayedexpansion

set LDC_ARGS=-mcpu=native -O3 -release -enable-inlining=1 --boundscheck=off --flto=full

if "%~1"=="" (
    call :regular_build
) else (
    call :pgo_build %*
)
goto :eof

:regular_build
ldc2 %LDC_ARGS% crackNames.d
echo Built regular build
goto :eof

:pgo_build
ldc2 --fprofile-generate=%TEMP%\crackNames.profraw -of=crackNames-profile %LDC_ARGS% crackNames.d
crackNames-profile %* > nul 2>&1
ldc-profdata merge %TEMP%\crackNames.profraw -output %TEMP%\crackNames.profdata
if exist %TEMP%\crackNames.profraw del %TEMP%\crackNames.profraw
if exist crackNames-profile.exe del crackNames-profile.exe
if exist crackNames-profile.obj del crackNames-profile.obj
ldc2 -fprofile-use=%TEMP%\crackNames.profdata %LDC_ARGS% crackNames.d
echo Built Profile-Guided Optimized (PGO) build
goto :eof