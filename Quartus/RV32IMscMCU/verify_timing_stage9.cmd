@echo off
setlocal

rem Use the same short-path workaround as compile_stage9.cmd, but reuse the
rem post-fit database when only SDC constraints need to be rechecked.
subst V: "%~dp0..\.."
if errorlevel 1 exit /b 1

pushd V:\Quartus\RV32IMscMCU
"C:\intelFPGA_lite\21.1\quartus\bin64\quartus_sta.exe" RV32IMscMCU -c RV32IMscMCU
set "stage9_result=%ERRORLEVEL%"
popd

subst V: /D
exit /b %stage9_result%
