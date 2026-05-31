@echo off
title AMBC — Testes de Integração
cd /d C:\ambc

echo.
echo  ========================================
echo   AMBC V2 — Testes de Integração
echo  ========================================
echo.
echo  PRE-REQUISITO: backend deve estar rodando
echo  Execute "iniciar-backend.bat" antes.
echo.
echo  Rodando testes...
echo.

php tests\executar.php

echo.
if %ERRORLEVEL% EQU 0 (
    echo  Todos os testes passaram.
) else (
    echo  Alguns testes falharam. Veja o detalhe acima.
)
echo.
pause
