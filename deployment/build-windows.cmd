@echo off
REM Jellyfin Windows Build Script Wrapper
REM This is a simple wrapper for build-windows.ps1
REM
REM Usage:
REM   build-windows.cmd                         - Basic build
REM   build-windows.cmd -SelfContained          - Self-contained build
REM   build-windows.cmd -SelfContained -SingleFile  - Single-file build

PowerShell -ExecutionPolicy Bypass -File "%~dp0build-windows.ps1" %*
