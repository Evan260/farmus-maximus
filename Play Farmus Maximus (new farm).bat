@echo off
rem Starts a brand-new farm, with the first-day welcome, without touching the real save or settings; nothing is saved.
start "" "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --path "%~dp0game" -- --new-farm
