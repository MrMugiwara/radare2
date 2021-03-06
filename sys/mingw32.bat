@echo off
setlocal enabledelayedexpansion

rem Allow to choose paths
rem but set to default - if not

rem -----------------------------------------------------------------------------------

if not [%MINGW_PATH%] NEQ [] (
	set "MINGW_PATH=C:\MinGW"
)
set "MSYS_VER=1.0"
set "MINGW_MSYS_PATH=%MINGW_PATH%\msys\%MSYS_VER%\bin"
set "MINGW_BIN_PATH=%MINGW_PATH%\bin"

rem -----------------------------------------------------------------------------------

if not [%GIT_PATH%] NEQ [] (
	set "GIT_PATH=C:\Program Files (x86)\Git"
)
set "GIT_BIN_PATH=%GIT_PATH%\bin"

rem -----------------------------------------------------------------------------------

SET PATH=%MINGW_BIN_PATH%;%GIT_BIN_PATH%;%PATH%

echo Using PATH = %PATH% ...

rem Read configure.acr and find a version string
for /F "tokens=1,2" %%i in (configure.acr) do (
	set VAR1=%%i
	set VAR2=%%j
	if "!VAR1!" == "VERSION" (
		echo "Read version from configure.acr: !VAR2!"
		set ENV_R2_VER=!VAR2!
		goto :start_build
	)
)

:start_build

call :convert_mingw MINGW_BIN_PATH
call :convert_mingw MINGW_MSYS_PATH
call :convert_mingw GIT_BIN_PATH

set EXPAND_PATH=export PATH="${MINGW_BIN_PATH}:${MINGW_MSYS_PATH}:${GIT_BIN_PATH}:${PATH}"
sh.exe -c "%EXPAND_PATH% ; gcc -v"
sh.exe -c "uname | tr 'A-Z' 'a-z'"
sh.exe -c "echo CC=${CC}"
sh.exe -c "sed -i '/xtensa/d' plugins.def.cfg"
sh.exe -c "%EXPAND_PATH% ; ./configure --with-ostype=mingw32 --build=i686-unknown-windows-gnu && make -j1 CC='gcc -static-libgcc'"

if NOT "%APPVEYOR%" == "True" (
	sh.exe -c "%EXPAND_PATH% ; make w32dist USE_ZIP=NO"
)

rem if "%APPVEYOR%" == "True" (
rem     appveyor DownloadFile https://raw.githubusercontent.com/radare/radare2-win-installer/master/radare2.iss
rem     appveyor DownloadFile https://raw.githubusercontent.com/radare/radare2-win-installer/master/radare2.ico
rem     dir %APPVEYOR_BUILD_FOLDER%\radare2-w32-%ENV_R2_VER%
rem     7z.exe a -tzip %APPVEYOR_BUILD_FOLDER%\radare2-w32-%ENV_R2_VER%.zip %APPVEYOR_BUILD_FOLDER%\radare2-w32-%ENV_R2_VER%
rem     iscc -DRadare2Location=%APPVEYOR_BUILD_FOLDER%\radare2-w32-%ENV_R2_VER%\* -DLicenseLocation=%APPVEYOR_BUILD_FOLDER%\COPYING.LESSER -DIcoLocation=%APPVEYOR_BUILD_FOLDER%\radare2.ico radare2.iss
rem )

goto :end

rem --------------------------------------------------------------------------------------

rem Convert to MinGW paths:
rem 1. reverse slashes
rem 2. remove colon
rem 3. escape spaces
rem 4. escape brackets
:convert_mingw var
set "%1=/!%1:\=/!"
set "%1=!%1::=!"
set "%1=!%1: =\ !"
set "%1=!%1:(=\(!"
set "%1=!%1:)=\)!"
exit /B

:end
