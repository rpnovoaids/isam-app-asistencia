@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

set "OUTPUT_FILE=_TODO_CONSOLIDADO.txt"

:: Borrar el archivo consolidado si ya existía de una ejecución anterior
if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"

echo Procesando archivos en la raiz y subcarpetas...
echo Por favor, espera a que la ventana se cierre sola.
echo.

:: Recorrer todos los archivos de la carpeta actual y subcarpetas
for /r %%i in (*) do (
    :: Verificar que no procese el propio script ni el archivo de salida
    if "%%~nxi" NEQ "%~nx0" (
        if "%%~nxi" NEQ "%OUTPUT_FILE%" (
            echo Combinando: %%~nxi
            echo ============================================================================== >> "%OUTPUT_FILE%"
            echo ARCHIVO: %%~nxi >> "%OUTPUT_FILE%"
            echo RUTA: %%~pi >> "%OUTPUT_FILE%"
            echo ============================================================================== >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            
            :: Copiar el contenido del archivo
            type "%%i" >> "%OUTPUT_FILE%"
            
            echo. >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
        )
    )
)

echo.
echo ¡Proceso terminado con exito! El resultado esta en %OUTPUT_FILE%
pause