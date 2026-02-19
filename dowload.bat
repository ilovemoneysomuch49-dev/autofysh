@echo off
setlocal

if not exist .venv (
  py -3 -m venv .venv
)

call .venv\Scripts\activate
python -m pip install --upgrade pip
pip install -r requirements.txt

pyinstaller --noconfirm --onefile --name autofysh_bot autofysh_bot.py

echo.
echo EXE gerado em: dist\autofysh_bot.exe
pause
