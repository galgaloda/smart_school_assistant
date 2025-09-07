@echo off
echo ============================================
echo  Smart School Assistant - Clear App Data
echo ============================================
echo.

echo This will clear all user data for Smart School Assistant
echo including Hive databases, settings, and cached files.
echo.

pause

echo.
echo Clearing app data directories...
echo.

REM Clear main app data directory
if exist "%APPDATA%\smart_school_assistant" (
    echo Clearing %APPDATA%\smart_school_assistant
    rmdir /s /q "%APPDATA%\smart_school_assistant"
    echo ✓ Cleared main app data
) else (
    echo ⚠ Main app data directory not found
)

REM Clear local app data directory
if exist "%LOCALAPPDATA%\smart_school_assistant" (
    echo Clearing %LOCALAPPDATA%\smart_school_assistant
    rmdir /s /q "%LOCALAPPDATA%\smart_school_assistant"
    echo ✓ Cleared local app data
) else (
    echo ⚠ Local app data directory not found
)

REM Clear documents directory
if exist "%USERPROFILE%\Documents\smart_school_assistant" (
    echo Clearing %USERPROFILE%\Documents\smart_school_assistant
    rmdir /s /q "%USERPROFILE%\Documents\smart_school_assistant"
    echo ✓ Cleared documents data
) else (
    echo ⚠ Documents data directory not found
)

REM Clear temp flutter data
if exist "%TEMP%\flutter_app_data" (
    echo Clearing %TEMP%\flutter_app_data
    rmdir /s /q "%TEMP%\flutter_app_data"
    echo ✓ Cleared temp flutter data
) else (
    echo ⚠ Temp flutter data directory not found
)

REM Clear any Hive boxes in current directory
if exist "*.hive" (
    echo Clearing local Hive database files
    del /q "*.hive"
    echo ✓ Cleared local Hive files
)

echo.
echo ============================================
echo  App data clearing completed!
echo ============================================
echo.
echo All user data has been cleared. The app will start fresh
echo with no previous data when you run it next time.
echo.
echo Press any key to exit...
pause >nul