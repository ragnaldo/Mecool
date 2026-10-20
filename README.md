# Mecool KM9 Pro → console Steam Link

Kit ADB. Sem root, sem flash de firmware (risco de brick, sem imagem oficial segura). Tudo reversível.

## Faz
- Animações off, sem sleep/screensaver, Wi-Fi em alta performance/baixa latência
- Remove apps inúteis (Netflix, YouTube etc.) só p/ usuário 0
- Compila Steam Link em modo `speed`, libera de economia de bateria/doze
- Backup de settings/pacotes em `backup/` antes de mexer

## Passos
1. Box: Config → Sobre → toque 7x em "Build" → Opções do desenvolvedor → **Depuração USB** (e **Depuração por rede**).
2. PC: instale [platform-tools](https://developer.android.com/tools/releases/platform-tools). Windows: use Git Bash ou WSL.
3. Steam Link APK: coloque em `apks/` (ou deixe instalar pela Play Store).
4. Cabo USB macho-macho na porta de dados da box, **ou** rede: `./mecool.sh install 192.168.0.X`
5. Rode:
   ```
   ./mecool.sh install                 # seguro
   ./mecool.sh install --aggressive    # + remove Assistant/Cast/recomendações
   ./mecool.sh restore                 # desfaz
   ```
6. Aceite o prompt "Permitir depuração" na TV.

## Manual (adb não faz)
- **Ethernet** (cabo) > Wi-Fi. Se Wi-Fi: 5 GHz, roteador perto.
- Boot direto no Steam Link: instale um launcher/autostart leve (ex.: Projectivy, "Launch on Boot") apontando p/ Steam Link, e rode com `--autostart <pacote>` p/ liberar permissões.
- Display: Config → Tela → 1080p 60 Hz (ou 4K se a rede aguentar). Desligue "Auto Frame Rate" se der stutter.
- Steam Link app: Config → Streaming → Bandwidth "Automatic"/limit ~30–50 Mbps, Hardware decoding on, HEVC se a GPU do PC suportar.
- Controle: pareie via Bluetooth antes; Steam Link aceita XInput/DS4/DS5.
- Após reboot: `adb shell dumpsys deviceidle disable` não persiste; o script reaplica se rodar de novo.

## Limites
- Firmware customizado Amlogic exigiria imagem do KM9 Pro + ferramenta USB Burning Tool; não incluído (risco de brick).
- Nomes de pacotes variam por versão do firmware; inexistentes são ignorados. Edite `config/*.txt`.
- Não testado em hardware real.
