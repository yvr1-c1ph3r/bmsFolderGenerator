@echo off
rem ============================================================
rem  beatoraja カスタムフォルダ作成ツール  exe ビルド用
rem  このファイルをダブルクリックすると exe を作ります。
rem ============================================================
setlocal
cd /d "%~dp0"

set "SRC=beatoraja_folder_maker.py"
set "NAME=beatoraja_folder_maker"

if not exist "%SRC%" (
    echo [エラー] %SRC% が見つかりません。
    echo このバッチと同じフォルダに置いてください。
    goto END
)

rem --- Python を探す ---
set "PY="
where py >nul 2>&1
if not errorlevel 1 set "PY=py -3"
if defined PY goto FOUND
where python >nul 2>&1
if not errorlevel 1 set "PY=python"
if defined PY goto FOUND

echo [エラー] Python が見つかりません。
echo https://www.python.org/downloads/ からインストールしてください。
echo インストール時は "Add python.exe to PATH" にチェックを入れてください。
goto END

:FOUND
echo 使う Python:
%PY% -c "import sys; print('  ' + sys.version)"
if errorlevel 1 (
    echo [エラー] Python の実行に失敗しました。
    goto END
)

echo.
echo PyInstaller を用意します（初回は数分かかります）...
%PY% -m pip install --upgrade --quiet pyinstaller
if errorlevel 1 (
    echo [エラー] PyInstaller のインストールに失敗しました。
    echo ネットワークにつながっているか確認してください。
    goto END
)

echo.
echo exe を作ります...
%PY% -m PyInstaller --noconfirm --clean --onefile --windowed --name "%NAME%" "%SRC%"
if errorlevel 1 (
    echo [エラー] ビルドに失敗しました。上の表示を確認してください。
    goto END
)

if not exist "dist\%NAME%.exe" (
    echo [エラー] exe が作られませんでした。
    goto END
)

if not exist "..\配布用" mkdir "..\配布用"
move /y "dist\%NAME%.exe" "..\配布用\%NAME%.exe" >nul
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del /q "%NAME%.spec" 2>nul

echo.
echo ============================================================
echo  完了しました： %NAME%.exe
echo  配布用フォルダにできています。ダブルクリックで起動します。
echo ============================================================

:END
echo.
pause
endlocal
