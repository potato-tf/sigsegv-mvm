@echo off
setlocal enabledelayedexpansion
title Sigmod WSL build tool

( echo wsl ./configureandbuild.sh ) > "BuildSigsegvAfterBoot.bat"

if not exist "%windir%\System32\bash.exe" (
    echo !ESC![92m
    echo -----------------
    echo Installing WSL...
    echo -----------------
    echo !ESC![0m
    winget install wsl
    wsl --install -d Ubuntu-22.04 --root
    echo [wsl2] > %USERPROFILE%/.wslconfig
    echo memory=2GB >> %USERPROFILE%/.wslconfig

    reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /f /v "WslInstallContinue" /t REG_SZ /d "%COMSPEC% /c """%cd%\SetupSigsegvAfterBoot.bat"""
    echo !ESC![96m
    echo Reboot system to continue installation
    choice /C YN /M "Do you want to reboot now?"

    if errorlevel 2 (
        echo Reboot the system later to continue
    ) else (
        shutdown -r -t 0
    )
    pause
) else (
    cls
    echo !ESC![92mUpdating WSL...!ESC![0m
    wsl --update > nul 2>&1
   BuildSigsegvAfterBoot.bat
)