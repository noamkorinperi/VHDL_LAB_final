@echo off
setlocal

rem Quartus 21.1 drops the Desktop component from this workspace path when
rem --flow receives it directly.  A temporary drive gives Quartus a short,
rem space-free project path while all relative QSF source paths still resolve.
subst V: "%~dp0..\.."
if errorlevel 1 exit /b 1

pushd V:\Quartus\RV32IMscMCU
"C:\intelFPGA_lite\21.1\quartus\bin64\quartus_sh.exe" --flow compile RV32IMscMCU
set "stage9_result=%ERRORLEVEL%"
popd

subst V: /D
exit /b %stage9_result%
