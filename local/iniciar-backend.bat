@echo off
title AMBC — Backend PHP
cd /d C:\Projetos\AMBCV3\ambc\ambc
echo.
echo  ========================================
echo   AMBC V2 — Backend rodando em :8080
echo  ========================================
echo.
php -S localhost:8080 router.php
pause
