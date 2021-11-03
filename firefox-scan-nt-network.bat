@echo off
cls
:start
echo ###################################################
echo # Verify Firefox on computers - by quintaninha.sh #
echo ###################################################
pause



for /f "tokens=1" %%i in (all-ips.txt) do (    
    if EXIST "\\%%i\c$\Program Files\Mozilla Firefox" (
        echo "\\%%i\c$\Program Files\Mozilla Firefox"
        echo # EXISTS #
        echo #######################################################
    )
)

pause
