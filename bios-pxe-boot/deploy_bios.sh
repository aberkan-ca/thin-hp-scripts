#!/bin/bash
# ==============================================================================
# Script      : deploy_bios.sh
# Auteur      : Rachid Aberkan
# Date        : 2026-11-16
# Version     : 1.1
# Description : (FR) Déploie l'ordre de démarrage réseau (PXE) en première
#                    position sur plusieurs clients légers HP ThinPro via SSH,
#                    enregistre un journal (deploy.log) et gère le redémarrage.
#               (EN) Deploys Network (PXE) boot order as first priority across
#                    multiple HP ThinPro thin clients over SSH, logs results
#                    (deploy.log), and supports optional reboot.
# Prérequis   : sshpass, fichier .env et fichier hosts.txt (via init.sh)
# Usage       : ./deploy_bios.sh             (sans redémarrage / no reboot)
#               ./deploy_bios.sh --reboot    (avec redémarrage / with reboot)
# ==============================================================================

FICHIER_ENV=".env"
FICHIER_HOSTS="hosts.txt"
FICHIER_LOG="deploy.log"
AUTO_REBOOT=0

# Vérifier l'argument --reboot / Check for --reboot flag
if [[ "$1" == "--reboot" ]]; then
    AUTO_REBOOT=1
fi

# Fonction d'écriture simultanée à l'écran et dans le log / Log & console output
log_msg() {
    local MESSAGE="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$MESSAGE" | tee -a "$FICHIER_LOG"
}

# Vérifier et charger .env / Check and load .env
if [ ! -f "$FICHIER_ENV" ]; then
    echo "[ERREUR / ERROR] Fichier $FICHIER_ENV introuvable / file not found. Lancez / Run ./init.sh"
    exit 1
fi

set -a
source "$FICHIER_ENV"
set +a

# Vérifier hosts.txt / Check hosts.txt
if [ ! -f "$FICHIER_HOSTS" ]; then
    echo "[ERREUR / ERROR] Fichier $FICHIER_HOSTS introuvable / file not found."
    exit 1
fi

# Fichier temporaire sécurisé pour sshpass / Secured temporary file for sshpass
PASS_FILE=$(mktemp)
chmod 600 "$PASS_FILE"
trap 'rm -f "$PASS_FILE"' EXIT

log_msg "=================================================================="
log_msg "Démarrage du déploiement / Starting deployment (Auto-Reboot: $AUTO_REBOOT)"
log_msg "=================================================================="

OK_COUNT=0
FAIL_COUNT=0

while read -r IP GROUPE_PASS || [ -n "$IP" ]; do
    # Ignorer commentaires et lignes vides / Skip comments and empty lines
    [[ -z "$IP" || "$IP" =~ ^# ]] && continue

    # Nettoyer le symbole '$' si présent / Strip '$' symbol if present
    NOM_VAR="${GROUPE_PASS#\$}"
    
    # Récupérer la valeur du mot de passe / Get password value
    MOT_DE_PASSE="${!NOM_VAR}"

    if [ -z "$MOT_DE_PASSE" ]; then
        log_msg "[ATTENTION / WARNING] $IP : Mot de passe introuvable / Password not found ($GROUPE_PASS)."
        ((FAIL_COUNT++))
        continue
    fi

    log_msg "--- Connexion / Connecting to $IP ($NOM_VAR) ---"
    printf "%s" "$MOT_DE_PASSE" > "$PASS_FILE"

    if sshpass -f "$PASS_FILE" ssh -n -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$IP" '
        /usr/sbin/hptc-bios-cfg -G /tmp/bios.txt || exit 1
        cp /tmp/bios.txt /tmp/bios_backup.txt

        awk '\''
        BEGIN { in_legacy=0 }
        /^LegacyBootOrder/ { in_legacy=1; print; next }
        in_legacy && /^L\[[0-9]+\]/ {
            sub(/\r$/, "")
            val = $0
            sub(/^L\[[0-9]+\] = /, "", val)
            if (val ~ /Network|PXE|NIC/) net[++n] = val
            else other[++o] = val
            next
        }
        in_legacy && !/^L\[[0-9]+\]/ {
            idx = 1
            for (i=1; i<=n; i++) printf "L[%02d] = %s\r\n", idx++, net[i]
            for (i=1; i<=o; i++) printf "L[%02d] = %s\r\n", idx++, other[i]
            in_legacy = 0
        }
        { print }
        '\'' /tmp/bios_backup.txt > /tmp/bios_new.txt

        /usr/sbin/hptc-bios-cfg -S /tmp/bios_new.txt
    '; then
        log_msg "[SUCCÈS / SUCCESS] $IP : Boot réseau appliqué / Network boot set."
        ((OK_COUNT++))

        # Redémarrage conditionnel / Conditional reboot
        if [ "$AUTO_REBOOT" -eq 1 ]; then
            log_msg "[REBOOT] $IP : Envoi de la commande de redémarrage / Sending reboot command..."
            sshpass -f "$PASS_FILE" ssh -n -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$IP" 'reboot' 2>/dev/null
        fi
    else
        log_msg "[ERREUR / ERROR] $IP : Échec / Failed (mauvais mot de passe ou hors ligne / wrong password or offline)."
        ((FAIL_COUNT++))
    fi

done < "$FICHIER_HOSTS"

log_msg "=================================================================="
log_msg "Résumé / Summary : $OK_COUNT Succès (Success) | $FAIL_COUNT Échecs (Failed)"
log_msg "Journal complet / Full log : $FICHIER_LOG"
log_msg "=================================================================="
