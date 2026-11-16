#!/bin/bash
# ==============================================================================
# Script      : clean.sh
# Auteur      : Rachid Aberkan
# Date        : 2026-11-16
# Version     : 1.0
# Description : (FR) Supprime de façon sécurisée les fichiers sensibles (.env)
#                    et propose de nettoyer hosts.txt et deploy.log.
#               (EN) Securely removes sensitive files (.env) and offers to
#                    clean up hosts.txt and deploy.log.
# Usage       : chmod +x clean.sh && ./clean.sh
# ==============================================================================

FICHIER_ENV=".env"
FICHIER_HOSTS="hosts.txt"
FICHIER_LOG="deploy.log"

echo "=================================================================="
echo " Nettoyage de l'environnement / Environment Cleanup"
echo "=================================================================="

# 1. Suppression sécurisée du fichier .env / Secure removal of .env
if [ -f "$FICHIER_ENV" ]; then
    if command -v shred &> /dev/null; then
        shred -u "$FICHIER_ENV"
    else
        rm -f "$FICHIER_ENV"
    fi
    echo "[OK] Fichier sensible $FICHIER_ENV supprimé / Sensitive file removed."
else
    echo "[INFO] Aucun fichier $FICHIER_ENV trouvé / No $FICHIER_ENV file found."
fi

# 2. Demander si on supprime hosts.txt / Ask to remove hosts.txt
if [ -f "$FICHIER_HOSTS" ]; then
    read -r -p "Supprimer $FICHIER_HOSTS ? / Remove $FICHIER_HOSTS? (o/y/N) : " REP_HOSTS
    if [[ "$REP_HOSTS" =~ ^[oOyY]$ ]]; then
        rm -f "$FICHIER_HOSTS"
        echo "[OK] $FICHIER_HOSTS supprimé / removed."
    else
        echo "[INFO] $FICHIER_HOSTS conservé / kept."
    fi
fi

# 3. Demander si on supprime deploy.log / Ask to remove deploy.log
if [ -f "$FICHIER_LOG" ]; then
    read -r -p "Supprimer $FICHIER_LOG ? / Remove $FICHIER_LOG? (o/y/N) : " REP_LOG
    if [[ "$REP_LOG" =~ ^[oOyY]$ ]]; then
        rm -f "$FICHIER_LOG"
        echo "[OK] $FICHIER_LOG supprimé / removed."
    else
        echo "[INFO] $FICHIER_LOG conservé / kept."
    fi
fi

echo "=== Nettoyage terminé / Cleanup complete ==="
