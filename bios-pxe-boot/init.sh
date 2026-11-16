#!/bin/bash
# ==============================================================================
# Script      : init.sh
# Auteur      : Rachid Aberkan
# Date        : 2026-11-16
# Version     : 1.0
# Description : (FR) Initialise les mots de passe dans .env, crée le modèle
#                    hosts.txt et applique les permissions sécurisées (chmod).
#               (EN) Initializes passwords in .env, creates the hosts.txt
#                    template, and sets secure file permissions (chmod).
# Usage       : chmod +x init.sh && ./init.sh
# ==============================================================================

FICHIER_ENV=".env"
FICHIER_HOSTS="hosts.txt"
SCRIPT_DEPLOY="deploy_bios.sh"
SCRIPT_CLEAN="clean.sh"

echo "=================================================================="
echo " Initialisation de l'environnement / Environment Initialization"
echo "=================================================================="

# 1. Saisie masquée des 3 mots de passe / Masked input for the 3 passwords
read -r -s -p "Mot de passe / Password for PASS_WEST    : " PASS_WEST
echo ""
read -r -s -p "Mot de passe / Password for PASS_EAST    : " PASS_EAST
echo ""
read -r -s -p "Mot de passe / Password for PASS_CENTRAL : " PASS_CENTRAL
echo ""

# 2. Création du fichier .env sécurisé / Create secured .env file
umask 077
cat <<EOF > "$FICHIER_ENV"
PASS_WEST='${PASS_WEST//\'/\'\\\'\'}'
PASS_EAST='${PASS_EAST//\'/\'\\\'\'}'
PASS_CENTRAL='${PASS_CENTRAL//\'/\'\\\'\'}'
EOF
chmod 600 "$FICHIER_ENV"
echo "[OK] Fichier $FICHIER_ENV généré et sécurisé / file generated and secured (chmod 600)."

# 3. Création d'un modèle hosts.txt si absent / Create hosts.txt template if missing
if [ ! -f "$FICHIER_HOSTS" ]; then
    cat <<EOF > "$FICHIER_HOSTS"
# Format : ADRESSE_IP NOM_VARIABLE / IP_ADDRESS VARIABLE_NAME
# t66010124 PASS_WEST
# t44020123 PASS_EAST
# t33020123 PASS_CENTRAL
EOF
    echo "[INFO] Modèle $FICHIER_HOSTS créé / template created. Ajoutez vos IP / Add your IPs."
fi
chmod 600 "$FICHIER_HOSTS"
echo "[OK] Permissions sécurisées sur / Secured permissions on $FICHIER_HOSTS (chmod 600)."

# 4. Rendre deploy_bios.sh exécutable / Make deploy_bios.sh executable
if [ -f "$SCRIPT_DEPLOY" ]; then
    chmod 700 "$SCRIPT_DEPLOY"
    echo "[OK] Script $SCRIPT_DEPLOY prêt / ready (chmod 700)."
else
    echo "[ATTENTION / WARNING] $SCRIPT_DEPLOY introuvable / not found."
fi

if [ -f "$SCRIPT_CLEAN" ]; then
    chmod 700 "$SCRIPT_CLEAN"
    echo "[OK] Script $SCRIPT_CLEAN prêt / ready (chmod 700)."
else
    echo "[ATTENTION / WARNING] $SCRIPT_CLEAN introuvable / not found."
fi

# 5. Vérification de sshpass / Check for sshpass
if ! command -v sshpass &> /dev/null; then
    echo "[ATTENTION / WARNING] 'sshpass' non installé / not installed (sudo apt install sshpass)."
else
    echo "[OK] Outil 'sshpass' détecté / detected."
fi

echo "=== Terminé / Done ==="
