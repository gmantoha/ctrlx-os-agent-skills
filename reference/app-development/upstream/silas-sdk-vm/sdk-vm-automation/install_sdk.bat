:: Source information
:: Source: Gemini 3.6
:: Edited by Silas Kuschke

@echo off

chcp 65001 >nul

:: Generate the ESC character for reliable ANSI color output

for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: Define ANSI color codes

set "BLUE=%ESC%[94m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "RESET=%ESC%[0m"

cd /d "%~dp0"
set "PROJEKT_PFAD=%~dp0"

:: Reset the installation log
if exist "install_debug.log" del "install_debug.log" >nul 2>&1

:: =======================================================================
:: Workflow control
:: =======================================================================

:: Continue directly when the script is running with administrator rights
if "%~1"=="-install" goto :INSTALL_DEPS

:: Check dependencies and request administrator rights when needed
set "INSTALL_QEMU_FLAG="
set "INSTALL_VSCODE_FLAG="
set "INSTALL_EXT_FLAG="
set "MISSING_DEPS="
call :CHECK_ALL_DEPS

if defined MISSING_DEPS (
    goto :REQUEST_ADMIN
) else (
    goto :MAIN_MENU
)

:: =======================================================================
:: Phase 1: request administrator rights
:: =======================================================================
:REQUEST_ADMIN
cls
echo %BLUE%=======================================================================%RESET%
echo %YELLOW%         REQUIRED COMPONENTS ARE BEING SET UP%RESET%
echo %BLUE%=======================================================================%RESET%
echo.
echo %YELLOW%[Check] The following system dependencies are missing on your system:%RESET%
echo %RED%  * %MISSING_DEPS%%RESET%
echo.
echo %YELLOW%Administrator rights are required for the automatic installation.%RESET%
echo.
echo %GREEN%The script will now close and restart in a new window with%RESET%
echo %GREEN%administrator rights to complete the installation.%RESET%
echo.
echo Press any key to start the installation as administrator...
pause >nul

:: Build the argument string for the elevated process
set "PS_ARGS=-install"
if defined INSTALL_QEMU_FLAG set "PS_ARGS=%PS_ARGS% -install-qemu"
if defined INSTALL_VSCODE_FLAG set "PS_ARGS=%PS_ARGS% -install-vscode"
if defined INSTALL_EXT_FLAG set "PS_ARGS=%PS_ARGS% -install-extensions"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%PS_ARGS%' -Verb RunAs"
exit

:: =======================================================================
:: Phase 2: install dependencies with administrator rights
:: =======================================================================
:INSTALL_DEPS
@echo off
cls
echo %BLUE%=======================================================================%RESET%
echo %GREEN%     INSTALLING SYSTEM DEPENDENCIES (ADMIN MODE) %RESET%
echo %BLUE%=======================================================================%RESET%
echo(

:: Store all arguments for simple option matching
set "ARG_STRING=%*"

:: 1. Install VS Code
echo %ARG_STRING% | findstr /i /c:"-install-vscode" >nul
if %errorlevel% == 0 (
    echo %YELLOW%[VS Code] Downloading Visual Studio Code...%RESET%
    curl.exe -k -L -# -o ".\\vscode_setup.exe" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    if exist ".\\vscode_setup.exe" (
        echo %YELLOW%[VS Code] Running installation...%RESET%
        start /wait "" ".\\vscode_setup.exe" /verysilent /mergetasks
        del ".\\vscode_setup.exe" >nul 2>&1
        echo %GREEN%VS Code installation successful.%RESET% & pause >nul
    ) else (
        echo %RED%[ERROR] Download of VS Code failed!%RESET% & pause
    )
)

:: 2. Install host extensions
echo %ARG_STRING% | findstr /i /c:"-install-extensions" >nul
if %errorlevel% == 0 (
    call :CHECK_VSCODE_PATH_ROBUST
    if defined CODE_EXE (
        echo.
        echo %YELLOW%[VS Code] Installing missing extensions...%RESET%
        for %%e in (golang.go ms-dotnettools.csharp ms-python.python ms-vscode-remote.remote-ssh ms-vscode.cmake-tools ms-vscode.cpptools vscjava.vscode-java-pack twxs.cmake) do (
             "%CODE_EXE%" --list-extensions 2>nul | findstr /i /b /e /c:"%%e" >nul
             if errorlevel 1 (
                echo %BLUE%  * Installing %%e...%RESET%
                "%CODE_EXE%" --install-extension %%e --force >> "install_debug.log" 2>&1
             )
        )
        echo %GREEN%Installation of extensions completed.%RESET% & pause >nul
    )
)

:: 3. Install QEMU
echo %ARG_STRING% | findstr /i /c:"-install-qemu" >nul
if %errorlevel% == 0 (
    echo.
    echo %YELLOW%[QEMU] IMPORTANT NOTE: In the next step, install it into the project folder.%RESET%
    echo %GREEN%Target: %PROJEKT_PFAD%qemu%RESET%
    echo.
    echo %YELLOW%[QEMU] Downloading QEMU...%RESET%
    curl.exe -k -L -# -o ".\\qemu_setup.exe" "https://qemu.weilnetz.de/w64/2024/qemu-w64-setup-20241220.exe"
    if exist ".\\qemu_setup.exe" (
        echo %YELLOW%[QEMU] Starting installation...%RESET%
        start /wait "" ".\\qemu_setup.exe" /DIR="%PROJEKT_PFAD%qemu"
        del ".\\qemu_setup.exe" >nul 2>&1
        if exist "%PROJEKT_PFAD%qemu\qemu-system-x86_64.exe" (
            echo %GREEN%Local QEMU successfully configured.%RESET%
        ) else (
            echo %RED%[ERROR] QEMU was not installed in the expected directory.%RESET%
        )
        pause >nul
    ) else (
        echo %RED%[ERROR] Download of QEMU failed!%RESET% & pause
    )
)

echo.
echo %GREEN%All necessary installations were completed.%RESET%
echo %YELLOW%The main menu is starting...%RESET%
timeout /t 2 /nobreak >nul
goto :MAIN_MENU

:: =======================================================================

:: Main menu for an already configured installation

:: =======================================================================

:MAIN_MENU

cls

echo %BLUE%=======================================================================%RESET%

echo     ctrlX OS SDK App Build-Environment Console %RESET%

echo %BLUE%=======================================================================%RESET%

echo(

echo This setup manages and starts your ctrlX app build VMs.

echo.

echo %BLUE%[STATUS] Existing VMs in the 'instances' directory:%RESET%

if not exist "instances" (

    echo    %YELLOW%The 'instances' directory has not been created yet.%RESET%

    set "VM22_TEXT=%RED%Not available%RESET%"

    set "VM24_TEXT=%RED%Not available%RESET%"

    goto :DISPLAY_VM_STATUS

)

set "VM22_STATUS=No"

set "VM24_STATUS=No"

if exist "instances\ubuntu-build-env-core22.qcow2" set "VM22_STATUS=Yes"

if exist "instances\ubuntu-build-env-core24.qcow2" set "VM24_STATUS=Yes"

set "VM22_TEXT=%RED%Not available%RESET%"

if "%VM22_STATUS%"=="Yes" set "VM22_TEXT=%GREEN%Available%RESET%"

set "VM24_TEXT=%RED%Not available%RESET%"

if "%VM24_STATUS%"=="Yes" set "VM24_TEXT=%GREEN%Available%RESET%"

:DISPLAY_VM_STATUS

:: Avoid the "->" sequence because CMD may interpret it as redirection

echo   - Ubuntu Core 22 (for ctrlX OS 1.x/2.x/3.x) : %VM22_TEXT%

echo   - Ubuntu Core 24 (for ctrlX OS 4.x)       : %VM24_TEXT%

:QEMU_STATUS
echo(
echo %BLUE%[QEMU Runtime Environment]%RESET%
if not exist "qemu\qemu-system-x86_64.exe" (
    set "QEMU_SOURCE=Not installed"
    set "QEMU_EXE=N/A"
) else (
    set "QEMU_EXE=%PROJEKT_PFAD%qemu\qemu-system-x86_64.exe"
    set "QEMU_SOURCE=Local project installation"
)
echo   - Mode: %GREEN%%QEMU_SOURCE%%RESET%
echo   - Path:  %YELLOW%%QEMU_EXE%%RESET%

echo(

echo %BLUE%=======================================================================%RESET%

echo Please choose an action:

echo 1) Start an existing VM

echo 2) Download and configure a new VM (select ctrlX OS version)

echo 3) Exit

echo(

set /p MAIN_CHOICE="%YELLOW%Choose an option (1, 2 or 3): %RESET%"

if "%MAIN_CHOICE%"=="1" goto :CHOOSE_START_VM

if "%MAIN_CHOICE%"=="2" goto :CHOOSE_DOWNLOAD_VERSION

if "%MAIN_CHOICE%"=="3" exit

goto :MAIN_MENU

:: =======================================================================

:: Menu option 1: start an existing VM

:: =======================================================================

:CHOOSE_START_VM

cls

echo %BLUE%=======================================================================%RESET%

echo %GREEN%                    START AN EXISTING VM%RESET%

echo %BLUE%=======================================================================%RESET%

echo(

echo Which VM would you like to start?

echo 1) Ubuntu Core 22 (for ctrlX OS 1.x / 2.x / 3.x) [%VM22_TEXT%]

echo 2) Ubuntu Core 24 (for ctrlX OS 4.x)             [%VM24_TEXT%]

echo 3) Back to main menu

echo(

set /p START_CHOICE="%YELLOW%Choose an option (1, 2 or 3): %RESET%"

if "%START_CHOICE%"=="1" goto :PREPARE_START_VM22

if "%START_CHOICE%"=="2" goto :PREPARE_START_VM24

if "%START_CHOICE%"=="3" goto :MAIN_MENU

goto :CHOOSE_START_VM

:PREPARE_START_VM22

if not exist "instances\ubuntu-build-env-core22.qcow2" (

    echo %RED%[ERROR] The VM for Ubuntu Core 22 does not exist!%RESET%

    echo Please download it first using option 2.

    pause

    goto :MAIN_MENU

)

set "CORE_VER=22"

goto :START_QEMU_VM

:PREPARE_START_VM24

if not exist "instances\ubuntu-build-env-core24.qcow2" (

    echo %RED%[ERROR] The VM for Ubuntu Core 24 does not exist!%RESET%

    echo Please download it first using option 2.

    pause

    goto :MAIN_MENU

)

set "CORE_VER=24"

goto :START_QEMU_VM

:: =======================================================================

:: Menu option 2: select a VM version

:: =======================================================================

:CHOOSE_DOWNLOAD_VERSION

cls

echo %BLUE%=======================================================================%RESET%

echo %GREEN%               DOWNLOAD AND SET UP A NEW VM%RESET%

echo %BLUE%=======================================================================%RESET%

echo(

echo Please choose the desired ctrlX OS target version:

echo.

echo 1) ctrlX OS 1.xx %YELLOW%(Uses Core 20 by default; uses Core 22 as fallback)%RESET%

echo 2) ctrlX OS 2.xx %GREEN%(Based on Ubuntu Core 22)%RESET%

echo 3) ctrlX OS 3.xx %GREEN%(Based on Ubuntu Core 22)%RESET%

echo 4) ctrlX OS 4.xx %GREEN%(Based on Ubuntu Core 24)%RESET%

echo 5) Back to main menu

echo(

set /p OS_CHOICE="%YELLOW%Choose an option (1, 2, 3, 4 or 5): %RESET%"

if "%OS_CHOICE%"=="1" (

    set "CORE_VER=22"

    set "DOWNLOAD_TARGET=VM"

    echo %YELLOW%[Info] ctrlX OS 1.xx uses Core 20 by default. Core 22 will be configured.%RESET%

    pause

    goto :NET_PROXY_CHECK

)

if "%OS_CHOICE%"=="2" (

    set "CORE_VER=22"

    set "DOWNLOAD_TARGET=VM"

    goto :NET_PROXY_CHECK

)

if "%OS_CHOICE%"=="3" (

    set "CORE_VER=22"

    set "DOWNLOAD_TARGET=VM"

    goto :NET_PROXY_CHECK

)

if "%OS_CHOICE%"=="4" (

    set "CORE_VER=24"

    set "DOWNLOAD_TARGET=VM"

    goto :NET_PROXY_CHECK

)

if "%OS_CHOICE%"=="5" goto :MAIN_MENU

goto :CHOOSE_DOWNLOAD_VERSION

:: =======================================================================

:: Check the proxy configuration before downloading files

:: =======================================================================

:NET_PROXY_CHECK

cls

echo %BLUE%=======================================================================%RESET%

echo %GREEN%                 NETWORK AND PROXY CHECK%RESET%

echo %BLUE%=======================================================================%RESET%

echo(

echo [Network] %YELLOW%Determining environment...%RESET%

echo Please choose your working environment:

echo 1) I am a Bosch employee %BLUE%(RB Local Proxy Manager)%RESET%

echo 2) I am a partner WITH a %BLUE%company proxy%RESET%

echo 3) I am a partner %BLUE%WITHOUT a proxy (direct connection)%RESET%

echo(

set /p NET_CHOICE="%YELLOW%Choose an option (1, 2 or 3): %RESET%"

set USE_PROXY=false
set "BOSCH_NT_USER="
set "BOSCH_PASSWORD_B64="

if "%NET_CHOICE%"=="1" goto :BOSCH_PROXY

if "%NET_CHOICE%"=="2" goto :EXT_PROXY

goto :NO_PROXY

:BOSCH_PROXY

set USE_PROXY=true

set PROXY_URL=http://127.0.0.1:3128

echo.
set /p "BOSCH_NT_USER=%YELLOW%Enter your Bosch NT user: %RESET%"
if not defined BOSCH_NT_USER (
    echo %RED%[ERROR] A Bosch NT user is required.%RESET%
    pause
    goto :NET_PROXY_CHECK
)
for /f "delims=" %%P in ('powershell.exe -NoProfile -Command "$oldColor = $Host.UI.RawUI.ForegroundColor; try { $Host.UI.RawUI.ForegroundColor = 'Yellow'; $secure = Read-Host -Prompt 'Enter your Bosch password' -AsSecureString; $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure); try { [Console]::WriteLine([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)))) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) } } finally { $Host.UI.RawUI.ForegroundColor = $oldColor }"') do set "BOSCH_PASSWORD_B64=%%P"
if not defined BOSCH_PASSWORD_B64 (
    echo %RED%[ERROR] A Bosch password is required.%RESET%
    pause
    goto :NET_PROXY_CHECK
)

echo.

echo %BLUE%=======================================================================%RESET%

echo %RED%IMPORTANT BOSCH PROXY NOTICE BEFORE STARTING:%RESET%

echo %BLUE%=======================================================================%RESET%

echo Please open the %GREEN%"RB Local Proxy Manager"%RESET% on your PC.

echo You must click the green %GREEN%"Execute"%RESET% button there.

echo.

echo The port 3128 will only open for the setup once the Bosch tool is active.

echo %BLUE%=======================================================================%RESET%

echo.

echo %YELLOW%Press Enter when you have started the Bosch tool...%RESET%

pause >nul

echo [Proxy] Starting with proxy %PROXY_URL% >> "install_debug.log" 2>&1

goto :ROUTE_DOWNLOAD

:EXT_PROXY

set USE_PROXY=true

if not exist "proxy.env" (

    echo CUSTOMER_PROXY_URL=http://your-proxy-server.de:8080 > proxy.env

    echo.

    echo %RED%[ERROR] Please add your proxy data to the 'proxy.env' file and restart the setup!%RESET%

    pause

    goto :MAIN_MENU

)

for /f "delims=" %%a in (proxy.env) do set %%a

set PROXY_URL=%CUSTOMER_PROXY_URL%

goto :ROUTE_DOWNLOAD

:: Shared dispatch for both proxy variants - a missing label aborts the batch.
:ROUTE_DOWNLOAD

if "%DOWNLOAD_TARGET%"=="VM" goto :DOWNLOAD_VM

goto :MAIN_MENU

:NO_PROXY

echo.

echo - %GREEN%Direct internet connection%RESET% active.

if "%DOWNLOAD_TARGET%"=="VM" goto :DOWNLOAD_VM

goto :MAIN_MENU

:: =======================================================================

:: Download and install QEMU silently

:: =======================================================================

:DOWNLOAD_QEMU_INST

cls

echo %BLUE%=======================================================================%RESET%

echo %GREEN%               DOWNLOAD AND INSTALL LOCAL QEMU%RESET%

echo %BLUE%=======================================================================%RESET%

echo(

:: Use the stable 64-bit QEMU release

set "QEMU_INSTALLER_URL=https://qemu.weilnetz.de/w64/2024/qemu-w64-setup-20241220.exe"

set "QEMU_TEMP_FILE=.\\qemu_temp_setup.exe"

echo %BLUE%[Download]%RESET% Downloading the official QEMU Windows package...

echo %YELLOW%(Duration: approx. 1-2 minutes - the progress bar shows the status)%RESET%

echo URL: %QEMU_INSTALLER_URL%

echo(

if "%USE_PROXY%"=="true" (

    curl.exe -k -x %PROXY_URL% -L -# -o "%QEMU_TEMP_FILE%" "%QEMU_INSTALLER_URL%"

) else (

    curl.exe -k -L -# -o "%QEMU_TEMP_FILE%" "%QEMU_INSTALLER_URL%"

)

if not exist "%QEMU_TEMP_FILE%" (

    echo.

    echo %RED%[ERROR] Download failed! Please check the network and proxy settings.%RESET%

    pause

    goto :MAIN_MENU

)

echo.

echo %BLUE%[Installation]%RESET% Installing QEMU in the project folder '.\\qemu\\'...

echo Please wait, this will only take a moment...

:: Run the installer silently without a user interface

start /wait "" "%QEMU_TEMP_FILE%" /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /DIR="%PROJEKT_PFAD%qemu" /LANG=en

:: Remove the downloaded installer

del "%QEMU_TEMP_FILE%" >nul 2>&1

if exist "qemu\qemu-system-x86_64.exe" (

    set "QEMU_EXE=%PROJEKT_PFAD%qemu\qemu-system-x86_64.exe"

    set "QEMU_SOURCE=Lokal im Projekt"

    echo.

    echo %GREEN%Local QEMU successfully configured!%RESET%

    pause

    goto :MAIN_MENU

) else (

    echo.

    echo %RED%[ERROR] The installation appears to have failed.%RESET%

    echo 'qemu-system-x86_64.exe' was not found in the '.\\qemu\\' folder.

    pause

    exit

)

:: =======================================================================

:: Download the VM and configure SSH access

:: =======================================================================

:DOWNLOAD_VM

cls

echo %BLUE%=======================================================================%RESET%

echo %GREEN%                      DOWNLOAD THE SDK BUILD VM%RESET%

echo %BLUE%=======================================================================%RESET%

echo(

if not exist "%PROJEKT_PFAD%instances" mkdir "%PROJEKT_PFAD%instances" >nul 2>&1

set "VM_FILE=%PROJEKT_PFAD%instances\ubuntu-build-env-core%CORE_VER%.qcow2"

if exist "%VM_FILE%" del /f /q "%VM_FILE%" >nul 2>&1

:: Select the download URL for the requested core version

if "%CORE_VER%"=="22" (

    set "DOWNLOAD_URL=https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img"

) else (

    set "DOWNLOAD_URL=https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"

)

echo %BLUE%[Download]%RESET% Downloading the original Bosch-Rexroth app build VM (Core %CORE_VER%)...

echo %YELLOW%(Duration: approx. 2-3 minutes - the progress bar shows the status)%RESET%

echo URL: %DOWNLOAD_URL%

echo(

if "%USE_PROXY%"=="true" (

    curl.exe -k -f -x %PROXY_URL% -L -# -o "%VM_FILE%" "%DOWNLOAD_URL%"

) else (

    curl.exe -k -f -L -# -o "%VM_FILE%" "%DOWNLOAD_URL%"

)

:: Generate the SSH key when it does not exist

set "SSH_DIR=%USERPROFILE%\.ssh"

if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

set "KEY_FILE=%SSH_DIR%\id_rsa_ctrlx"

if not exist "%KEY_FILE%" (

    echo %BLUE%[SSH]%RESET% Generating the SSH key for the VS Code remote connection...

    ssh-keygen -t rsa -b 4096 -N "" -f "%KEY_FILE%" >> "install_debug.log" 2>&1

)

:: Configure the Windows SSH alias for the isolated port 11022

set "CONFIG_FILE=%SSH_DIR%\config"

echo %BLUE%[SSH]%RESET% Adding the connection to the Windows SSH config...

findstr /I "Host ctrlx-sdk-vm" "%CONFIG_FILE%" >nul 2>&1

if %errorLevel% neq 0 (

    (

    echo.

    echo Host ctrlx-sdk-vm

    echo     HostName 127.0.0.1

    echo     User boschrexroth

    echo     Port 11022

    echo     IdentityFile %KEY_FILE:\\=/%

    echo     StrictHostKeyChecking no

    echo     UserKnownHostsFile /dev/null

    ) >> "%CONFIG_FILE%"

)

copy /Y "%KEY_FILE%.pub" "%PROJEKT_PFAD%id_rsa_ctrlx.pub" >nul 2>&1

:: Convert the host proxy address to the QEMU gateway address

set "VM_PROXY_URL="

if "%USE_PROXY%"=="true" set "VM_PROXY_URL=%PROXY_URL:127.0.0.1=10.0.2.2%"

if "%USE_PROXY%"=="true" set "VM_PROXY_URL=%VM_PROXY_URL:localhost=10.0.2.2%"

set "VM_EFFECTIVE_PROXY_URL=%VM_PROXY_URL%"

if "%NET_CHOICE%"=="1" set "VM_EFFECTIVE_PROXY_URL=http://127.0.0.1:3128"

:: =======================================================================
:: Configure Cloud-Init and the CIDATA directory
:: =======================================================================
echo %BLUE%[Cloud-Init]%RESET% Generating configuration files in the CIDATA folder...
:: Ensure that the CIDATA directory exists
if not exist "%PROJEKT_PFAD%instances\cidata" mkdir "%PROJEKT_PFAD%instances\cidata" >nul 2>&1
:: Create the required meta-data file
set "CLOUD_INIT_INSTANCE_ID=ctrlx-build-env-%CORE_VER%-%RANDOM%-%RANDOM%"
echo instance-id: %CLOUD_INIT_INSTANCE_ID% > "%PROJEKT_PFAD%instances\cidata\meta-data"
echo local-hostname: ctrlx-sdk-vm >> "%PROJEKT_PFAD%instances\cidata\meta-data"
:: Create user-data with credentials and the SSH public key
echo #cloud-config> "%PROJEKT_PFAD%instances\cidata\user-data"
:: Add proxy settings so Cloud-Init can download packages
if "%USE_PROXY%"=="true" echo proxy: %VM_PROXY_URL%>> "%PROJEKT_PFAD%instances\cidata\user-data"
if "%USE_PROXY%"=="true" echo apt:>> "%PROJEKT_PFAD%instances\cidata\user-data"
if "%USE_PROXY%"=="true" echo   proxy: %VM_PROXY_URL%>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo users:>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - default>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - name: boschrexroth>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     groups: sudo>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     shell: /bin/bash>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     sudo: ALL=^(ALL^) NOPASSWD:ALL>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     ssh_authorized_keys:>> "%PROJEKT_PFAD%instances\cidata\user-data"
:: Add the generated public key to the Cloud-Init configuration
for /f "usebackq delims=" %%i in ("%PROJEKT_PFAD%id_rsa_ctrlx.pub") do (
    echo       - %%i>> "%PROJEKT_PFAD%instances\cidata\user-data"
)
echo chpasswd:>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   list: ^|>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     boschrexroth:boschrexroth>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   expire: False>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo ssh_pwauth: True>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo disable_root: False>> "%PROJEKT_PFAD%instances\cidata\user-data"
:: Define the default Ubuntu packages
echo packages:>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - git>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - curl>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - wget>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - make>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - rsync>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - unzip>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - squashfs-tools>> "%PROJEKT_PFAD%instances\cidata\user-data"
:: Generate the SDK provisioning script
set "SDK_SH=%PROJEKT_PFAD%instances\cidata\setup-sdk.sh"
if exist "%SDK_SH%" del "%SDK_SH%" >nul 2>&1
> "%SDK_SH%" echo #!/bin/bash
>> "%SDK_SH%" echo install -d -m 755 -o boschrexroth -g boschrexroth /home/boschrexroth
>> "%SDK_SH%" echo install -d -m 700 -o boschrexroth -g boschrexroth /home/boschrexroth/.vscode-server
>> "%SDK_SH%" echo chown -R boschrexroth:boschrexroth /home/boschrexroth
:: Generate the serial console autologin configuration
>> "%SDK_SH%" echo mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
>> "%SDK_SH%" echo echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin boschrexroth --noclear %%I ^\$TERM" ^| tee /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf
>> "%SDK_SH%" echo systemctl daemon-reload
>> "%SDK_SH%" echo systemctl restart serial-getty@ttyS0.service
:: Add the provisioning status indicator to the user's Bash profile
>> "%SDK_SH%" echo cat ^<^< 'EOF' ^| tee -a /home/boschrexroth/.bashrc
>> "%SDK_SH%" echo.
>> "%SDK_SH%" echo if [ -f /var/lib/cloud/instance/boot-finished ]; then
>> "%SDK_SH%" echo     echo -e "\n\e[92m✔ ctrlX SDK setup is complete and ready to use!\e[0m"
>> "%SDK_SH%" echo else
>> "%SDK_SH%" echo     echo -e "\n\e[93m⏳ The ctrlX SDK setup is still running in the background. Please wait...\e[0m"
>> "%SDK_SH%" echo     echo -e "You can monitor progress with the following command:"
>> "%SDK_SH%" echo     echo -e "   \e[94mtail -f /var/log/cloud-init-output.log\e[0m\n"
>> "%SDK_SH%" echo fi
>> "%SDK_SH%" echo EOF
:: Configure the proxy when proxy mode is enabled
if "%USE_PROXY%" neq "true" goto :SKIP_PROXY_CONFIG
>> "%SDK_SH%" echo # Proxy configuration for VM background processes
:: Persist proxy environment variables for system processes
>> "%SDK_SH%" echo echo "http_proxy=\"%VM_PROXY_URL%\"" ^| tee -a /etc/environment
>> "%SDK_SH%" echo echo "https_proxy=\"%VM_PROXY_URL%\"" ^| tee -a /etc/environment
>> "%SDK_SH%" echo echo "HTTP_PROXY=\"%VM_PROXY_URL%\"" ^| tee -a /etc/environment
>> "%SDK_SH%" echo echo "HTTPS_PROXY=\"%VM_PROXY_URL%\"" ^| tee -a /etc/environment
>> "%SDK_SH%" echo echo "no_proxy=\"localhost,127.0.0.1,10.0.2.2,.bosch.com\"" ^| tee -a /etc/environment
>> "%SDK_SH%" echo echo "NO_PROXY=\"localhost,127.0.0.1,10.0.2.2,.bosch.com\"" ^| tee -a /etc/environment
>> "%SDK_SH%" echo echo "TMPDIR=\"/tmp\"" ^| tee -a /etc/environment
:: Configure the proxy for login shells
>> "%SDK_SH%" echo echo "export http_proxy=\"%VM_PROXY_URL%\"" ^| tee /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo echo "export https_proxy=\"%VM_PROXY_URL%\"" ^| tee -a /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo echo "export HTTP_PROXY=\"%VM_PROXY_URL%\"" ^| tee -a /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo echo "export HTTPS_PROXY=\"%VM_PROXY_URL%\"" ^| tee -a /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo echo "export no_proxy=\"localhost,127.0.0.1,10.0.2.2,.bosch.com\"" ^| tee -a /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo echo "export NO_PROXY=\"localhost,127.0.0.1,10.0.2.2,.bosch.com\"" ^| tee -a /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo echo "export TMPDIR=\"/tmp\"" ^| tee -a /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo chmod +x /etc/profile.d/proxy.sh
>> "%SDK_SH%" echo export http_proxy="%VM_PROXY_URL%" https_proxy="%VM_PROXY_URL%" HTTP_PROXY="%VM_PROXY_URL%" HTTPS_PROXY="%VM_PROXY_URL%"
:: Configure the proxy for interactive and non-interactive Bash sessions
>> "%SDK_SH%" echo echo "export http_proxy=\"%VM_PROXY_URL%\"" ^| tee -a /etc/bash.bashrc
>> "%SDK_SH%" echo echo "export https_proxy=\"%VM_PROXY_URL%\"" ^| tee -a /etc/bash.bashrc
>> "%SDK_SH%" echo echo "export HTTP_PROXY=\"%VM_PROXY_URL%\"" ^| tee -a /etc/bash.bashrc
>> "%SDK_SH%" echo echo "export HTTPS_PROXY=\"%VM_PROXY_URL%\"" ^| tee -a /etc/bash.bashrc
>> "%SDK_SH%" echo echo "export no_proxy=\"localhost,127.0.0.1,10.0.2.2,.bosch.com\"" ^| tee -a /etc/bash.bashrc
>> "%SDK_SH%" echo echo "export NO_PROXY=\"localhost,127.0.0.1,10.0.2.2,.bosch.com\"" ^| tee -a /etc/bash.bashrc
>> "%SDK_SH%" echo echo "export TMPDIR=\"/tmp\"" ^| tee -a /etc/bash.bashrc
:: Configure the APT proxy permanently
>> "%SDK_SH%" echo echo "Acquire::http::Proxy \"%VM_PROXY_URL%\";" ^| tee /etc/apt/apt.conf.d/99proxy
>> "%SDK_SH%" echo echo "Acquire::https::Proxy \"%VM_PROXY_URL%\";" ^| tee -a /etc/apt/apt.conf.d/99proxy
:: Preserve proxy variables when using sudo with APT
>> "%SDK_SH%" echo echo "Defaults env_keep += \"http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY TMPDIR\"" ^| tee /etc/sudoers.d/proxy
>> "%SDK_SH%" echo chmod 0440 /etc/sudoers.d/proxy
:: Configure the Snap daemon proxy
>> "%SDK_SH%" echo systemctl restart snapd.socket snapd.service
>> "%SDK_SH%" echo sleep 5
>> "%SDK_SH%" echo snap set system proxy.http="%VM_PROXY_URL%"
>> "%SDK_SH%" echo snap set system proxy.https="%VM_PROXY_URL%"
:SKIP_PROXY_CONFIG
:: LXD remains the isolated environment for Snapcraft packing
>> "%SDK_SH%" echo snap install lxd ^|^| snap refresh lxd
>> "%SDK_SH%" echo if getent group lxd ^> /dev/null; then usermod -aG lxd boschrexroth; fi
>> "%SDK_SH%" echo lxd init --auto --storage-backend=dir ^|^| true
if "%USE_PROXY%"=="true" >> "%SDK_SH%" echo lxc config set core.proxy_http "%VM_EFFECTIVE_PROXY_URL%" ^|^| true
if "%USE_PROXY%"=="true" >> "%SDK_SH%" echo lxc config set core.proxy_https "%VM_EFFECTIVE_PROXY_URL%" ^|^| true
if "%USE_PROXY%"=="true" >> "%SDK_SH%" echo lxc config set core.proxy_ignore_hosts "localhost,127.0.0.1,10.0.2.2" ^|^| true
>> "%SDK_SH%" echo # Patch APT sources for arm64 cross-compilation (prevents 404 errors)
>> "%SDK_SH%" echo if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
>> "%SDK_SH%" echo     if ! grep -q "Architectures:" /etc/apt/sources.list.d/ubuntu.sources; then
>> "%SDK_SH%" echo         cat ^<^< 'EOF' ^| tee /etc/apt/sources.list.d/ubuntu.sources
>> "%SDK_SH%" echo Types: deb
>> "%SDK_SH%" echo URIs: http://archive.ubuntu.com/ubuntu/
>> "%SDK_SH%" echo Suites: noble noble-updates noble-backports
>> "%SDK_SH%" echo Components: main restricted universe multiverse
>> "%SDK_SH%" echo Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
>> "%SDK_SH%" echo Architectures: amd64
>> "%SDK_SH%" echo.
>> "%SDK_SH%" echo Types: deb
>> "%SDK_SH%" echo URIs: http://security.ubuntu.com/ubuntu/
>> "%SDK_SH%" echo Suites: noble-security
>> "%SDK_SH%" echo Components: main restricted universe multiverse
>> "%SDK_SH%" echo Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
>> "%SDK_SH%" echo Architectures: amd64
>> "%SDK_SH%" echo.
>> "%SDK_SH%" echo Types: deb
>> "%SDK_SH%" echo URIs: http://ports.ubuntu.com/ubuntu-ports/
>> "%SDK_SH%" echo Suites: noble noble-updates noble-security noble-backports
>> "%SDK_SH%" echo Components: main restricted universe multiverse
>> "%SDK_SH%" echo Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
>> "%SDK_SH%" echo Architectures: arm64
>> "%SDK_SH%" echo EOF
>> "%SDK_SH%" echo     fi
>> "%SDK_SH%" echo elif [ -f /etc/apt/sources.list ]; then
>> "%SDK_SH%" echo     if ! grep -q "arch=" /etc/apt/sources.list; then
>> "%SDK_SH%" echo         sed -i -e 's/deb http/deb [arch=amd64,i386] http/g' -e 's/deb-src http/deb-src [arch=amd64,i386] http/g' /etc/apt/sources.list
>> "%SDK_SH%" echo         cat ^<^< 'EOF' ^| tee -a /etc/apt/sources.list
>> "%SDK_SH%" echo deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse
>> "%SDK_SH%" echo deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse
>> "%SDK_SH%" echo deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse
>> "%SDK_SH%" echo EOF
>> "%SDK_SH%" echo     fi
>> "%SDK_SH%" echo fi
>> "%SDK_SH%" echo # Klonen des SDK und Ausfuehren der Setup-Skripte im User-Kontext
>> "%SDK_SH%" echo su - boschrexroth -c "git config --global http.sslVerify false"
>> "%SDK_SH%" echo su - boschrexroth -c "wget --no-check-certificate https://raw.githubusercontent.com/boschrexroth/ctrlx-automation-sdk/main/scripts/clone-install-sdk.sh"
>> "%SDK_SH%" echo su - boschrexroth -c "chmod a+x clone-install-sdk.sh"
>> "%SDK_SH%" echo su - boschrexroth -c "./clone-install-sdk.sh"
>> "%SDK_SH%" echo su - boschrexroth -c "/home/boschrexroth/ctrlx-automation-sdk/scripts/install-required-packages.sh"
>> "%SDK_SH%" echo su - boschrexroth -c "/home/boschrexroth/ctrlx-automation-sdk/scripts/install-snapcraft.sh"
:: Install the ctrlX OS Agent Skill and configure VS Code Agent Skills before CNTLM.
>> "%SDK_SH%" echo echo "Installing ctrlX OS Agent Skill for GitHub Copilot..."
>> "%SDK_SH%" echo SKILL_REPO_DIR=/home/boschrexroth/.repo_anton
>> "%SDK_SH%" echo SKILL_LOG=/var/log/ctrlx-agent-skills-install.log
>> "%SDK_SH%" echo NODE_VERSION=22.20.0
>> "%SDK_SH%" echo NODE_DIR=/opt/node-v$NODE_VERSION-linux-x64
>> "%SDK_SH%" echo NODE_ARCHIVE=/tmp/node-v$NODE_VERSION-linux-x64.tar.xz
>> "%SDK_SH%" echo NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
>> "%SDK_SH%" echo NODE_PROXY="${https_proxy:-${HTTPS_PROXY:-}}"
>> "%SDK_SH%" echo if [ ! -x "$NODE_DIR/bin/npx" ]; then
>> "%SDK_SH%" echo     if curl -fsSL --retry 3 --proxy "$NODE_PROXY" -o "$NODE_ARCHIVE" "$NODE_URL"; then
>> "%SDK_SH%" echo         rm -rf "$NODE_DIR"
>> "%SDK_SH%" echo         if tar -xJf "$NODE_ARCHIVE" -C /opt; then
>> "%SDK_SH%" echo             rm -f "$NODE_ARCHIVE"
>> "%SDK_SH%" echo         else
>> "%SDK_SH%" echo             echo "Node.js archive extraction failed." ^>^&2
>> "%SDK_SH%" echo         fi
>> "%SDK_SH%" echo     else
>> "%SDK_SH%" echo         echo "Node.js download failed; check proxy connectivity." ^>^&2
>> "%SDK_SH%" echo     fi
>> "%SDK_SH%" echo fi
>> "%SDK_SH%" echo SKILLS_NPX="$NODE_DIR/bin/npx"
>> "%SDK_SH%" echo if command -v git ^> /dev/null ^&^& [ -x "$SKILLS_NPX" ]; then
>> "%SDK_SH%" echo     if [ -d "$SKILL_REPO_DIR/.git" ]; then
>> "%SDK_SH%" echo         git -C "$SKILL_REPO_DIR" pull --ff-only ^>^> "$SKILL_LOG" 2^>^&1 ^|^| true
>> "%SDK_SH%" echo     else
>> "%SDK_SH%" echo         rm -rf "$SKILL_REPO_DIR"
>> "%SDK_SH%" echo         git clone --depth 1 https://github.com/gmantoha/ctrlx-os-agent-skills.git "$SKILL_REPO_DIR" ^> "$SKILL_LOG" 2^>^&1
>> "%SDK_SH%" echo     fi
>> "%SDK_SH%" echo     chown -R boschrexroth:boschrexroth "$SKILL_REPO_DIR"
>> "%SDK_SH%" echo     su - boschrexroth -c "$SKILLS_NPX --yes skills add gmantoha/ctrlx-os-agent-skills --skill ctrlx --agent github-copilot --global --copy --yes" ^>^> "$SKILL_LOG" 2^>^&1
>> "%SDK_SH%" echo     VSCODE_SETTINGS=/home/boschrexroth/.vscode-server/data/Machine/settings.json
>> "%SDK_SH%" echo     install -d -m 700 -o boschrexroth -g boschrexroth "$(dirname "$VSCODE_SETTINGS")"
>> "%SDK_SH%" echo     cat ^> /tmp/merge-vscode-settings.js ^<^< 'EOF'
>> "%SDK_SH%" echo const fs = require("fs");
>> "%SDK_SH%" echo const settingsPath = process.argv[2];
>> "%SDK_SH%" echo const settings = fs.existsSync(settingsPath) ? fs.readFileSync(settingsPath, "utf8") : "{}";
if "%NET_CHOICE%"=="1" (
>> "%SDK_SH%" echo const skillLocations = '"chat.agentSkillsLocations": {\n        "~/.repo_anton": true,\n        "~/.copilot/skills": true,\n        "~/.agents/skills": true\n    },\n    "http.proxy": "http://127.0.0.1:3128",\n    "http.proxySupport": "override"';
) else (
>> "%SDK_SH%" echo const skillLocations = '"chat.agentSkillsLocations": {\n        "~/.repo_anton": true,\n        "~/.copilot/skills": true,\n        "~/.agents/skills": true\n    }';
)
>> "%SDK_SH%" echo const locationPattern = /"chat\.agentSkillsLocations"\s*:\s*\{[^{}]*\}/s;
>> "%SDK_SH%" echo let updatedSettings;
>> "%SDK_SH%" echo if (locationPattern.test(settings)) {
>> "%SDK_SH%" echo     updatedSettings = settings.replace(locationPattern, skillLocations);
>> "%SDK_SH%" echo } else {
>> "%SDK_SH%" echo     const closingBrace = settings.lastIndexOf("}");
>> "%SDK_SH%" echo     if (closingBrace ^< 0) throw new Error("VS Code settings are not a JSON object");
>> "%SDK_SH%" echo     const prefix = settings.slice(0, closingBrace).trimEnd();
>> "%SDK_SH%" echo     const suffix = settings.slice(closingBrace + 1);
>> "%SDK_SH%" echo     const separator = prefix.endsWith("{") ? "" : ",";
>> "%SDK_SH%" echo     updatedSettings = prefix + separator + "\n    " + skillLocations + "\n}" + suffix;
>> "%SDK_SH%" echo }
>> "%SDK_SH%" echo fs.writeFileSync(settingsPath, updatedSettings);
>> "%SDK_SH%" echo EOF
>> "%SDK_SH%" echo     "$NODE_DIR/bin/node" /tmp/merge-vscode-settings.js "$VSCODE_SETTINGS" ^>^> "$SKILL_LOG" 2^>^&1
>> "%SDK_SH%" echo     rm -f /tmp/merge-vscode-settings.js
>> "%SDK_SH%" echo     chown boschrexroth:boschrexroth "$VSCODE_SETTINGS"
>> "%SDK_SH%" echo     chmod 600 "$VSCODE_SETTINGS"
>> "%SDK_SH%" echo     echo "ctrlX OS Agent Skill and VS Code configuration installed."
>> "%SDK_SH%" echo else
>> "%SDK_SH%" echo     echo "ctrlX OS Agent Skill installation skipped: git or npx is unavailable." ^>^&2
>> "%SDK_SH%" echo fi
if "%NET_CHOICE%"=="1" (
>> "%SDK_SH%" echo # Install and configure CNTLM after all SDK, Snapcraft, and Agent Skill downloads.
>> "%SDK_SH%" echo # The SDK multiarch setup may leave only arm64 package indexes; restore an amd64 universe source for CNTLM.
>> "%SDK_SH%" echo echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble main universe" ^> /etc/apt/sources.list.d/cntlm-amd64.list
>> "%SDK_SH%" echo if apt-get update ^&^& DEBIAN_FRONTEND=noninteractive apt-get install -y cntlm:amd64; then
>> "%SDK_SH%" echo     CNTLM_PASSWORD="$(printf '%%s' '%BOSCH_PASSWORD_B64%' | base64 -d)"
>> "%SDK_SH%" echo     CNTLM_HASH="$(cntlm -u '%BOSCH_NT_USER%' -d DE -p "$CNTLM_PASSWORD" -H 2>/tmp/cntlm-hash-error | awk '/^PassNTLMv2/{print $2}')"
>> "%SDK_SH%" echo     unset CNTLM_PASSWORD
>> "%SDK_SH%" echo     if [ -n "$CNTLM_HASH" ]; then
>> "%SDK_SH%" echo         rm -f /tmp/cntlm-hash-error
>> "%SDK_SH%" echo         cat ^<^< EOF ^> /etc/cntlm.conf
>> "%SDK_SH%" echo Username        %BOSCH_NT_USER%
>> "%SDK_SH%" echo Domain          DE
>> "%SDK_SH%" echo PassNTLMv2      $CNTLM_HASH
>> "%SDK_SH%" echo.
>> "%SDK_SH%" echo Proxy           rb-proxy-de.bosch.com:8080
>> "%SDK_SH%" echo Proxy           rb-proxy-special.bosch.com:8080
>> "%SDK_SH%" echo NoProxy         localhost, 127.0.0.*, 10.*, 192.168.*, *.bosch.com
>> "%SDK_SH%" echo Listen          3128
>> "%SDK_SH%" echo EOF
>> "%SDK_SH%" echo         chmod 600 /etc/cntlm.conf
>> "%SDK_SH%" echo         systemctl enable cntlm
>> "%SDK_SH%" echo         systemctl restart cntlm
>> "%SDK_SH%" echo         if systemctl is-active --quiet cntlm; then
>> "%SDK_SH%" echo             echo "CNTLM service started successfully"
>> "%SDK_SH%" echo             CNTLM_PROXY_URL=http://127.0.0.1:3128
>> "%SDK_SH%" echo             export http_proxy="$CNTLM_PROXY_URL" https_proxy="$CNTLM_PROXY_URL" HTTP_PROXY="$CNTLM_PROXY_URL" HTTPS_PROXY="$CNTLM_PROXY_URL"
>> "%SDK_SH%" echo             sed -i 's#http://10\.0\.2\.2:3128#http://127.0.0.1:3128#g' /etc/environment /etc/profile.d/proxy.sh /etc/bash.bashrc /etc/apt/apt.conf.d/99proxy
>> "%SDK_SH%" echo             snap set system proxy.http="$CNTLM_PROXY_URL"
>> "%SDK_SH%" echo             snap set system proxy.https="$CNTLM_PROXY_URL"
>> "%SDK_SH%" echo         else
>> "%SDK_SH%" echo             echo "CNTLM service failed to start; continuing without switching the proxy" ^>^&2
>> "%SDK_SH%" echo             systemctl status cntlm --no-pager ^>^&2
>> "%SDK_SH%" echo         fi
>> "%SDK_SH%" echo     else
>> "%SDK_SH%" echo         echo "CNTLM hash generation failed; continuing without CNTLM" ^>^&2
>> "%SDK_SH%" echo         cat /tmp/cntlm-hash-error ^>^&2
>> "%SDK_SH%" echo     fi
>> "%SDK_SH%" echo else
>> "%SDK_SH%" echo     echo "CNTLM installation failed; continuing without CNTLM" ^>^&2
>> "%SDK_SH%" echo fi
)
:: Embed the provisioning script in user-data
echo write_files:>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - path: /root/setup-sdk.sh>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     permissions: '0755'>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo     content: ^|>> "%PROJEKT_PFAD%instances\cidata\user-data"
:: Copy the provisioning script into user-data with indentation
for /f "usebackq delims=" %%G in ("%SDK_SH%") do echo       %%G>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo runcmd:>> "%PROJEKT_PFAD%instances\cidata\user-data"
echo   - /root/setup-sdk.sh>> "%PROJEKT_PFAD%instances\cidata\user-data"

:: Generate the network configuration
> "%PROJEKT_PFAD%instances\cidata\network-config" echo version: 2
>> "%PROJEKT_PFAD%instances\cidata\network-config" echo ethernets:
>> "%PROJEKT_PFAD%instances\cidata\network-config" echo   all:
>> "%PROJEKT_PFAD%instances\cidata\network-config" echo     match:
>> "%PROJEKT_PFAD%instances\cidata\network-config" echo       name: 'en*'
>> "%PROJEKT_PFAD%instances\cidata\network-config" echo     dhcp4: true

:: =======================================================================

:: Step 3: download a portable ISO creation tool

:: =======================================================================

if exist "%PROJEKT_PFAD%instances\mkisofs.exe" goto :GENERATE_ISO

echo %BLUE%[Setup]%RESET% Downloading the compact ISO compilation tool 'mkisofs.exe' (approx. 380 KB)...

:: Download the verified Windows binary from the official source

if "%USE_PROXY%"=="true" (

    curl.exe -k -x %PROXY_URL% -L -# -o "%PROJEKT_PFAD%instances\mkisofs.exe" "https://github.com/cloudbase/cloudbase-init-test-resources/raw/master/bin/mkisofs.exe"

) else (

    curl.exe -k -L -# -o "%PROJEKT_PFAD%instances\mkisofs.exe" "https://github.com/cloudbase/cloudbase-init-test-resources/raw/master/bin/mkisofs.exe"

)

:GENERATE_ISO

echo %BLUE%[ISO]%RESET% Generating a real NoCloud configuration ISO (seed.iso)...

if exist "%PROJEKT_PFAD%instances\seed.iso" del "%PROJEKT_PFAD%instances\seed.iso" >nul 2>&1

:: Create the ISO using the local command-line tool

:: Joliet and Rock Ridge options preserve compatible file naming

"%PROJEKT_PFAD%instances\mkisofs.exe" -o "%PROJEKT_PFAD%instances\seed.iso" -J -r -V "CIDATA" "%PROJEKT_PFAD%instances\cidata" 2>nul

:: Verify that the ISO was created successfully

for %%F in ("%PROJEKT_PFAD%instances\seed.iso") do (

    if %%~zF LSS 1 (

        echo.

        echo %RED%[ERROR] ISO creation with mkisofs.exe failed. seed.iso could not be generated!%RESET%

        pause

        goto :MAIN_MENU

    )
)

:: =======================================================================

:: Step 4: validate the generated ISO

:: =======================================================================

set "SEED_SIZE=0"

if exist "%PROJEKT_PFAD%instances\seed.iso" (

    for %%A in ("%PROJEKT_PFAD%instances\seed.iso") do set "SEED_SIZE=%%~zA"

)

set "USER_DATA_SIZE=Missing!"

if exist "%PROJEKT_PFAD%instances\cidata\user-data" (

    for %%B in ("%PROJEKT_PFAD%instances\cidata\user-data") do set "USER_DATA_SIZE=Available (%%~zB Bytes)"

)

set "META_DATA_SIZE=Missing!"

if exist "%PROJEKT_PFAD%instances\cidata\meta-data" (

    for %%C in ("%PROJEKT_PFAD%instances\cidata\meta-data") do set "META_DATA_SIZE=Available (%%~zC Bytes)"

)

set "NET_CONFIG_SIZE=Missing!"

if exist "%PROJEKT_PFAD%instances\cidata\network-config" (

    for %%D in ("%PROJEKT_PFAD%instances\cidata\network-config") do set "NET_CONFIG_SIZE=Available (%%~zD Bytes)"

)

echo %GREEN%[Check] Verifying the contents of the created ISO interface...%RESET%

echo   - Instances folder: %GREEN%OK%RESET%

echo   - seed.iso size:   %GREEN%%SEED_SIZE% Bytes%RESET%

echo   - user-data:        %GREEN%%USER_DATA_SIZE%%RESET%

echo   - meta-data:        %GREEN%%META_DATA_SIZE%%RESET%

echo   - network-config:   %GREEN%%NET_CONFIG_SIZE%%RESET%

echo.

echo.

echo %GREEN%=======================================================================%RESET%

echo %GREEN%Setup completed successfully!%RESET%

echo %GREEN%=======================================================================%RESET%

echo The VM is ready to use (Ubuntu Core %CORE_VER%).

echo.

if defined SEED_REBUILD_FOR_START (
    set "SEED_REBUILD_FOR_START="
    goto :START_QEMU_NOW
)

goto :START_QEMU_VM

:: =======================================================================

:: Start the VM with the local QEMU installation

:: =======================================================================

:START_QEMU_VM

cls

echo %BLUE%=======================================================================%RESET%

echo       START ctrlX SDK BUILD-ENVIRONMENT (Core %CORE_VER%)

echo %BLUE%=======================================================================%RESET%

echo(

echo Port 11022 on the Windows host forwards to the VM.

echo.

echo \* SSH connection via VS Code Remote-SSH: %YELLOW%ctrlx-sdk-vm%RESET%

echo \* To shut down the VM manually, run %YELLOW%sudo shutdown -h now%RESET% inside the VM.

echo %BLUE%=======================================================================%RESET%

echo(

:: Always rebuild seed.iso from the current Cloud-Init files.
if exist "%PROJEKT_PFAD%instances\cidata\user-data" (
    echo %BLUE%[Cloud-Init]%RESET% Rebuilding seed.iso from the current CIDATA files...
    set "SEED_REBUILD_FOR_START=1"
    goto :GENERATE_ISO
)

echo %RED%[ERROR] The Cloud-Init configuration is missing! Please download the VM again (option 2).%RESET%

pause

goto :MAIN_MENU

:START_QEMU_NOW

set "VM_IMAGE=%PROJEKT_PFAD%instances\ubuntu-build-env-core%CORE_VER%.qcow2"
if exist "%PROJEKT_PFAD%qemu\qemu-img.exe" (
    echo %BLUE%[Storage]%RESET% Ensuring at least 60 GB virtual disk space for the VM...
    "%PROJEKT_PFAD%qemu\qemu-img.exe" resize "%VM_IMAGE%" 60G >nul 2>&1
    if errorlevel 1 echo %YELLOW%[Storage] Could not resize the VM image automatically.%RESET%
)

:: Start QEMU with boot output in a dedicated terminal
:: whpx: Hardware acceleration via Windows Hypervisor Platform (works alongside VBS/Hyper-V).
:: cache=writeback,aio=threads speeds up the IO heavy snap builds noticeably.
start "ctrlx-sdk-vm-core%CORE_VER% boot console" cmd /c ""%QEMU_EXE%" -M q35 -accel whpx,kernel-irqchip=off -m 16G -smp 12 -drive ""file=%VM_IMAGE%,format=qcow2,if=virtio,file.locking=off,cache=writeback,aio=threads,discard=unmap"" -drive ""driver=raw,file=%PROJEKT_PFAD%instances\seed.iso,if=virtio,readonly=on"" -net nic,model=virtio -net user,hostfwd=tcp::11022-:22 -serial mon:stdio -display none 2> ""%PROJEKT_PFAD%qemu_error.log"""

if errorlevel 1 (
    echo %RED%[ERROR] QEMU could not be started.%RESET%
    echo Please check %PROJEKT_PFAD%qemu_error.log for details.
    pause
    goto :MAIN_MENU
)

echo %GREEN%[Start]%RESET% VM process started. The boot output is visible in the QEMU console window.
call :WAIT_FOR_VM_AND_OPEN_VSCODE

if errorlevel 1 (
    echo %RED%[WARNING] QEMU exited unexpectedly. The error log was not opened automatically.%RESET%
    echo %YELLOW%Please inspect %PROJEKT_PFAD%qemu_error.log manually if troubleshooting is needed.%RESET%
)

call :WAIT_FOR_VM_SHUTDOWN

echo(
echo %GREEN%VM process ended. Returning to the main menu.%RESET%
timeout /t 2 /nobreak >nul
goto :MAIN_MENU

:: =======================================================================
:: Helper subroutines
:: =======================================================================
:WAIT_FOR_VM_SHUTDOWN
    echo.
    echo %BLUE%[VM Monitor]%RESET% VM is running. Waiting for shutdown before returning to the main menu...

:VM_SHUTDOWN_LOOP
    ssh -o BatchMode=yes -o ConnectTimeout=5 ctrlx-sdk-vm "true" >nul 2>&1
    if not errorlevel 1 (
        timeout /t 5 /nobreak >nul
        goto :VM_SHUTDOWN_LOOP
    )
    echo %GREEN%[VM Monitor]%RESET% SSH connection closed. VM shutdown detected.
goto :EOF

:CHECK_ALL_DEPS
    if not exist "qemu\qemu-system-x86_64.exe" (
        call :ADD_MISSING "Local QEMU"
        set "INSTALL_QEMU_FLAG=1"
    )
    
    call :CHECK_VSCODE_PATH_ROBUST
    if "%VSCODE_OK%"=="No" (
        call :ADD_MISSING "VS Code & extensions"
        set "INSTALL_VSCODE_FLAG=1"
        set "INSTALL_EXT_FLAG=1"
    ) else (
        call :CHECK_EXTENSIONS
        if "%EXTENSIONS_OK%"=="No" (
            call :ADD_MISSING "one or more VS Code extensions"
            set "INSTALL_EXT_FLAG=1"
        )
    )
goto :EOF

:CHECK_VSCODE_PATH_ROBUST
    set "VSCODE_OK=No"
    set "CODE_EXE="
    for /f "tokens=*" %%p in ('where code 2^>nul') do (
        if not defined CODE_EXE (
           set "CODE_EXE=%%p"
           set "VSCODE_OK=Yes"
        )
    )
    if defined CODE_EXE goto :EOF

    for /d %%u in (C:\Users\*) do (
        if exist "%%u\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd" (
            set "CODE_EXE=%%u\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd"
            set "VSCODE_OK=Yes"
            goto :EOF
        )
    )
goto :EOF

:CHECK_EXTENSIONS
    set "EXTENSIONS_OK=Yes"
    for %%e in (golang.go ms-dotnettools.csharp ms-python.python ms-vscode-remote.remote-ssh ms-vscode.cmake-tools ms-vscode.cpptools vscjava.vscode-java-pack twxs.cmake) do (
        "%CODE_EXE%" --list-extensions --show-versions 2>nul | findstr /i /r /b /c:"%%e$" /c:"%%e@" >nul
        if errorlevel 1 (
            set "EXTENSIONS_OK=No"
        )
    )
goto :EOF

:ADD_MISSING
    if defined MISSING_DEPS (
        set "MISSING_DEPS=%MISSING_DEPS%, %~1"
    ) else (
        set "MISSING_DEPS=%~1"
    )
goto :EOF

:WAIT_FOR_VM_AND_OPEN_VSCODE
    echo.
    echo %BLUE%[Auto Connect]%RESET% Waiting until the VM is ready for SSH...
    echo %YELLOW%This can take several minutes on the first start.%RESET%

    where ssh >nul 2>&1
    if errorlevel 1 (
        echo %RED%[WARNING]%RESET% OpenSSH client was not found. Auto-connect skipped.
        exit /b 1
    )

    set /a WAIT_COUNT=0
    set /a WAIT_MAX=360

:WAIT_FOR_VM_LOOP
    set /a WAIT_COUNT+=1
    ssh -o BatchMode=yes -o ConnectTimeout=5 ctrlx-sdk-vm "test -f /var/lib/cloud/instance/boot-finished" >nul 2>&1
    if %errorlevel%==0 goto :VM_READY_FOR_VSCODE

    if %WAIT_COUNT% GEQ %WAIT_MAX% (
        echo %RED%[WARNING]%RESET% Timeout while waiting for VM provisioning.
        echo You can connect manually later with host %YELLOW%ctrlx-sdk-vm%RESET%.
        exit /b 1
    )

    if %WAIT_COUNT% EQU 1 echo %YELLOW%[Auto Connect] VM is booting and provisioning. Please wait...%RESET%
    timeout /t 10 /nobreak >nul
    goto :WAIT_FOR_VM_LOOP

:VM_READY_FOR_VSCODE
    call :OPEN_VSCODE_REMOTE
    exit /b %errorlevel%

:INSTALL_VM_EXTENSIONS
    goto :INSTALL_VM_EXTENSIONS_IMPL

:OPEN_VSCODE_REMOTE
    call :CHECK_VSCODE_PATH_ROBUST
    if "%VSCODE_OK%"=="No" (
        echo %RED%[WARNING]%RESET% VS Code was not found. Auto-connect skipped.
        exit /b 1
    )

    "%CODE_EXE%" --list-extensions --show-versions 2>nul | findstr /i /r /b /c:"ms-vscode-remote\.remote-ssh$" /c:"ms-vscode-remote\.remote-ssh@" >nul
    if errorlevel 1 (
        echo %RED%[WARNING]%RESET% Remote-SSH extension is missing. Auto-connect skipped.
        exit /b 1
    )

    tasklist /FI "IMAGENAME eq Code.exe" 2>nul | findstr /i /c:"Code.exe" >nul
    if errorlevel 1 (
        echo %YELLOW%[Auto Connect]%RESET% VS Code is not running. Starting a new window...
    ) else (
        echo %GREEN%[Auto Connect]%RESET% VS Code is already running. Starting a second Remote-SSH window...
    )

    call "%CODE_EXE%" --new-window --remote "ssh-remote+ctrlx-sdk-vm" "/home/boschrexroth"
    if errorlevel 1 (
        echo %RED%[WARNING]%RESET% VS Code could not be started with Remote-SSH.
        exit /b 1
    )

    call :INSTALL_VM_EXTENSIONS
    echo %GREEN%[Auto Connect]%RESET% VS Code started and connecting to ctrlx-sdk-vm.
    exit /b 0

:INSTALL_VM_EXTENSIONS_IMPL
    echo %BLUE%[VM Extensions]%RESET% Waiting for the Remote-SSH server to initialize...
    echo %YELLOW%[VM Extensions]%RESET% These extensions are installed in the VM's Remote Extension Host, not on Windows.
    set /a EXTENSION_WAIT_COUNT=0
:WAIT_FOR_CODE_SERVER
    set /a EXTENSION_WAIT_COUNT+=1
    ssh -o BatchMode=yes -o ConnectTimeout=10 ctrlx-sdk-vm "code_server=$(find /home/boschrexroth/.vscode-server -type f -name code-server -perm -u+x -print -quit 2>/dev/null); test -n \"$code_server\"" >nul 2>&1
    if %errorlevel%==0 goto :CODE_SERVER_READY
    if %EXTENSION_WAIT_COUNT% GEQ 60 (
        echo %YELLOW%[VM Extensions] The VS Code Server did not become ready in time. Open the VM in VS Code once and run the script again.%RESET%
        exit /b 1
    )
    timeout /t 5 /nobreak >nul
    goto :WAIT_FOR_CODE_SERVER

:CODE_SERVER_READY
    echo %BLUE%[Storage]%RESET% Expanding the VM root filesystem...
    ssh -o BatchMode=yes -o ConnectTimeout=10 ctrlx-sdk-vm "sudo growpart /dev/vda 1 >/tmp/ctrlx-growpart.log 2>&1"
    if errorlevel 1 (
        ssh -o BatchMode=yes -o ConnectTimeout=10 ctrlx-sdk-vm "grep -q NOCHANGE /tmp/ctrlx-growpart.log"
        if errorlevel 1 (
            echo %YELLOW%[Storage] Root filesystem could not be expanded. Extension installation may fail due to low disk space.%RESET%
        ) else (
            echo %GREEN%[Storage] Root filesystem is already fully expanded.%RESET%
        )
    )
    ssh -o BatchMode=yes -o ConnectTimeout=10 ctrlx-sdk-vm "sudo resize2fs /dev/vda1 >/dev/null 2>&1"
    if errorlevel 1 echo %YELLOW%[Storage] Filesystem resize could not be completed.%RESET%
    echo %BLUE%[VM Extensions]%RESET% Installing extensions in the VM sequentially...
    ssh -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 ctrlx-sdk-vm "set -eu; code_server=$(find /home/boschrexroth/.vscode-server -type f -name code-server -perm -u+x -print -quit 2>/dev/null); test -n \"$code_server\"; test -x \"$code_server\"; export VSCODE_AGENT_FOLDER=/home/boschrexroth/.vscode-server; extension_dir=/home/boschrexroth/.vscode-server/extensions; mkdir -p \"$extension_dir\"; echo Using VS Code Server: \"$code_server\"; for extension in Angular.ng-template golang.go ms-dotnettools.csharp ms-python.python ms-vscode.cmake-tools ms-vscode.cpptools vscjava.vscode-java-pack twxs.cmake; do echo Installing \"$extension\"; \"$code_server\" --install-extension \"$extension\" --extensions-dir \"$extension_dir\" --force; done; echo Installed VM extensions:; \"$code_server\" --list-extensions --extensions-dir \"$extension_dir\"" >> "install_debug.log" 2>&1
    if errorlevel 1 (
        echo %YELLOW%[VM Extensions] Installation failed. See install_debug.log for details.%RESET%
        exit /b 1
    )
    echo %GREEN%[VM Extensions] Remote extensions installed and verified in the VM.%RESET%
    exit /b 0
