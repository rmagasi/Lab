@echo off
:: =======================================================
::
:: (Robo-)Copy PVS Store from mgmt-pvs-01 -> mgmt-pvs-02
::
:: Purpose: Copy data from \\mgmt-pvs-01\d$\vDisks to \\mgmt-pvs-02\d$\vDisks 
:: Bin:	robocopy.exe
::
:: Remarks: robocopy.exe must be stored in script directory
::
:: =======================================================

rem ----------------------------
rem set var
rem ----------------------------
set logdrive=%~dp0logs
set logfile=%logdrive%\%~n0.log

:: specify source path
:: -> use either UNC path or map network drive
set src1="\\mgmt-pvs-01\e$\vDisks"
:: set src2="\\mgmt-pvs-01\e$\vDisks"

:: specifiy destination path
:: -> use either UNC path or map network drive
set dst1="\\mgmt-pvs-02\d$\vDisks"
:: set dst2="\\mgmt-pvs-02\d$\vDisks"

rem ----------------------------
rem tidy up log dir
rem ----------------------------
if not exist %logdrive% md %logdrive%
if exist %logfile% del /q %logfile%

rem ----------------------------
rem robocopy
rem ----------------------------
echo ...rcopy %src%
robocopy %src1% %dst1% /COPY:DT /PURGE /XD WriteCache /XF *.lok /E /R:3 /W:3 /V /TEE /LOG+:%logfile%
:: robocopy %src2% %dst2% /COPY:DT /PURGE /XD WriteCache /XF *.lok /E /R:3 /W:3 /V /TEE /LOG+:%logfile%
:end
echo done!