@echo on
setlocal EnableDelayedExpansion

:: prepare vcvarsall
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
)
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
)

call %VC_DIR% amd64 || exit /B 1

set tDir=C:\Qt\%QT_VER%\static
mkdir -p %tDir% || exit /B 1

cd C:\Qt\%QT_VER%\Src

for %%m in (qtbase;%STATIC_QT_MODS%) do (
	cd %%m
	if "%%m" == "qtbase" (
		call .\configure -prefix %tDir% -platform win32-msvc -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets || exit /B 1
	) else (
		%tDir%\bin\qmake -r
	)
	nmake > nul || exit /B 1
	nmake install > nul || exit /B 1
	cd ..
)
