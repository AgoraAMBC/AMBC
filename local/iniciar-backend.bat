@echo off
title AMBC — Backend PHP (dev)
cd /d C:\Projetos\AMBCV3\ambc\ambc
echo.
echo  ========================================
echo   AMBC V2 — Backend rodando em :8081
echo  ========================================
echo.
echo   Live Server: http://localhost:5500
echo   Login:       http://localhost:5500/login.html
echo.
php -S localhost:8081 router.php
pause
