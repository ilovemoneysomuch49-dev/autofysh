# autofysh
# autofysh

Bot simples para automatizar a pescaria no Roblox (AutoFysh), baseado em detecção de cores da interface.

## O que ele faz
- Procura e foca na janela do Roblox (quando possível).
- Envia `F11` para entrar em tela cheia.
- Clica automaticamente no alvo **verde** durante o minigame.
- Clica no ícone/vermelho da vara para iniciar ação quando necessário.
- Para sozinho após capturar **15 peixes** (padrão).

## Avisos importantes
- Pode parar de funcionar se o jogo mudar UI, resolução ou cores.
- Use em sua conta por sua conta e risco (automação pode violar regras do jogo).
- Para interromper instantaneamente, mova o mouse para o canto superior esquerdo (failsafe do `pyautogui`).

## Como gerar o `.exe` (Windows)
1. Instale Python 3.10+ no Windows.
2. Abra `cmd` na pasta do projeto.
3. Rode:
   ```bat
   build_exe.bat
   ```
4. O executável será criado em:
   ```
   dist\autofysh_bot.exe
   ```

## Como usar
Com EXE:
```bat
dist\autofysh_bot.exe --max-fish 15 --fps 20
```

Com Python direto:
```bat
python autofysh_bot.py --max-fish 15 --fps 20
```

### Parâmetros
- `--max-fish`: limite de peixes (padrão: `15`).
- `--fps`: taxa de leitura de tela (padrão: `20`).
