#!/usr/bin/env bash
# Mecool KM9 Pro -> console Steam Link. Uso:
#   ./mecool.sh install [IP[:5555]] [--aggressive] [--autostart pacote]
#   ./mecool.sh restore [IP[:5555]]
set -u
cd "$(dirname "$0")"
STEAMLINK=com.valvesoftware.steamlink

cmd=${1:-}; shift || true
ip=""; aggressive=0; autostart=""
while [ $# -gt 0 ]; do
  case $1 in
    --aggressive) aggressive=1 ;;
    --autostart) autostart=${2:-}; shift ;;
    *) ip=$1 ;;
  esac
  shift
done

command -v adb >/dev/null || { echo "adb não encontrado (instale platform-tools)"; exit 1; }
[ -n "$ip" ] && { case $ip in *:*) ;; *) ip=$ip:5555;; esac; adb connect "$ip"; }
n=$(adb devices | awk 'NR>1 && $2=="device"' | wc -l)
[ "$n" -eq 1 ] || { echo "Esperado 1 dispositivo autorizado, achei $n. Aceite o prompt de depuração na TV."; adb devices; exit 1; }

sh() { adb shell "$@" </dev/null; }
pkgs() { grep -hvE "^\s*(#|\$)" "$@" | awk '{print $1}'; }

debloat_files=(config/debloat-safe.txt)
[ $aggressive -eq 1 ] && debloat_files+=(config/debloat-aggressive.txt)

case $cmd in
install)
  echo "== Dispositivo: $(sh getprop ro.product.model | tr -d '\r') / Android $(sh getprop ro.build.version.release | tr -d '\r') / $(sh getprop ro.board.platform | tr -d '\r')"
  mkdir -p backup
  b=backup/$(date +%Y%m%d-%H%M%S); mkdir -p "$b"
  sh pm list packages -d > "$b/disabled.txt"
  sh pm list packages > "$b/packages.txt"
  for ns in global system secure; do sh settings list $ns > "$b/settings-$ns.txt"; done
  echo "== Backup em $b"

  echo "== Instalando APKs de apks/"
  for f in apks/*.apk; do [ -e "$f" ] || continue; echo "  $f"; adb install -r -g "$f" </dev/null; done
  if ! sh pm list packages $STEAMLINK | grep -q "$STEAMLINK"; then
    echo "!! Steam Link não instalado. Ponha o APK em apks/ ou instale pela Play Store (abrindo agora)."
    sh am start -a android.intent.action.VIEW -d "market://details?id=$STEAMLINK" >/dev/null
  fi

  echo "== Settings"
  while read -r ns key val; do
    sh settings put "$ns" "$key" "$val" || echo "  falhou: $ns $key"
  done < <(grep -vE '^\s*(#|$)' config/settings.txt)

  echo "== Debloat"
  for p in $(pkgs "${debloat_files[@]}"); do
    if sh pm list packages "$p" | grep -q "package:$p\$"; then
      sh pm uninstall -k --user 0 "$p" | tr -d '\r' | sed "s|^|  $p: |"
    fi
  done

  echo "== Performance"
  sh dumpsys deviceidle disable >/dev/null     # não persiste após reboot
  sh cmd wifi force-hi-perf-mode enabled >/dev/null 2>&1
  sh cmd wifi force-low-latency-mode enabled >/dev/null 2>&1
  sh cmd package compile -m speed -f $STEAMLINK 2>&1 | tr -d '\r'
  sh pm trim-caches 999G >/dev/null 2>&1

  if [ -n "$autostart" ]; then
    echo "== Autostart: $autostart"
    sh appops set "$autostart" SYSTEM_ALERT_WINDOW allow
    sh appops set "$autostart" RUN_IN_BACKGROUND allow
    sh dumpsys deviceidle whitelist +"$autostart" >/dev/null
  fi
  sh dumpsys deviceidle whitelist +$STEAMLINK >/dev/null
  sh appops set $STEAMLINK RUN_IN_BACKGROUND allow

  echo "== Abrindo Steam Link"
  sh monkey -p $STEAMLINK -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  echo "Pronto. Reinicie a box (adb reboot) e veja README.md (passos manuais)."
  ;;
restore)
  for p in $(pkgs config/debloat-safe.txt config/debloat-aggressive.txt); do
    sh cmd package install-existing "$p" 2>&1 | tr -d '\r' | grep -v 'not found' | sed "s|^|  |"
  done
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do sh settings put global $k 1; done
  sh settings put global stay_on_while_plugged_in 0
  sh settings put system screen_off_timeout 600000
  sh settings put secure screensaver_enabled 1
  sh settings put global package_verifier_enable 1
  sh settings put global verifier_verify_adb_installs 1
  sh dumpsys deviceidle enable >/dev/null
  echo "Restaurado (settings voltaram ao padrão Android; backups completos em backup/)."
  ;;
*) sed -n '2,5p' "$0"; exit 1 ;;
esac
