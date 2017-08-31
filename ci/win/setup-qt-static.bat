exit /B 1

:: prepare vcvarsall
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
)
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
)
	
set tDir=C:\Qt-Static
mkdir -p %tDir% || exit /B 1

for /D %%G in (.) do (
	echo "qtbase %STATIC_QT_MODS%" | findstr /C:"%%G" > nul && (
		set skipPart=-skip %%G %skipPart%
	)
)

call %VC_DIR% amd64 || exit /B 1

.\configure -prefix %tDir% -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets %skipPart% || exit /B 1
nmake > /dev/null || exit /B 1
nmake install > /dev/null || exit /B 1