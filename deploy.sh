#!/bin/bash

##
## Script de déploiement global ShopManagement (frontend + backend)
## à lancer depuis ta machine locale.
##
## Il va :
##  - se connecter en SSH à ton VPS
##  - cloner / mettre à jour les deux dépôts
##  - lancer le déploiement backend
##  - lancer le déploiement frontend
##  - vérifier que les deux applis répondent sur le VPS
##

set -euo pipefail

# ==========================
# 🔧 Paramètres à adapter
# ==========================

# Utilisateur SSH sur le VPS
SSH_USER="root"

# IP / host du VPS
SSH_HOST="185.97.144.208"

# Répertoire de base sur le VPS où seront les deux projets
REMOTE_BASE_DIR="/var/www/shopmanagement"

# URLs des dépôts Git
BACKEND_REPO_URL="https://github.com/lyade28/Shopmanagement-backend.git"
FRONT_REPO_URL="https://github.com/lyade28/ShopManagement-Front.git"

# Chemins des projets sur le VPS
REMOTE_BACKEND_DIR="$REMOTE_BASE_DIR/Shopmanagement-backend"
REMOTE_FRONT_DIR="$REMOTE_BASE_DIR/ShopManagement-Front"

# ==========================
# 🎨 Couleurs / helpers
# ==========================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

remote() {
  ssh -o StrictHostKeyChecking=accept-new "${SSH_USER}@${SSH_HOST}" "$@"
}

echo -e "${GREEN}🚀 Déploiement global ShopManagement (frontend + backend)...${NC}"

# ==========================
# 1) Vérifications locales
# ==========================

echo -e "${YELLOW}🔎 Vérifications locales des projets...${NC}"

if [ ! -d "Shopmanagement-backend" ]; then
  echo -e "${RED}❌ Dossier local 'Shopmanagement-backend' introuvable.${NC}"
  echo "Assure-toi d'être dans le dossier 'management-boutique' qui contient les deux projets."
  exit 1
fi

if [ ! -d "ShopManagement-Front" ]; then
  echo -e "${RED}❌ Dossier local 'ShopManagement-Front' introuvable.${NC}"
  echo "Assure-toi d'être dans le dossier 'management-boutique' qui contient les deux projets."
  exit 1
fi

if [ ! -f "Shopmanagement-backend/deploy.sh" ]; then
  echo -e "${RED}❌ 'Shopmanagement-backend/deploy.sh' est manquant.${NC}"
  exit 1
fi

if [ ! -f "ShopManagement-Front/deploy.sh" ]; then
  echo -e "${RED}❌ 'ShopManagement-Front/deploy.sh' est manquant.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Projets locaux trouvés et scripts de déploiement existants.${NC}"

# ==========================
# 2) Vérifier accès SSH
# ==========================

echo -e "${YELLOW}🔐 Test de connexion SSH vers ${SSH_USER}@${SSH_HOST}...${NC}"
if ! remote "echo OK" >/dev/null 2>&1; then
  echo -e "${RED}❌ Impossible de se connecter en SSH à ${SSH_USER}@${SSH_HOST}.${NC}"
  echo "Vérifie :"
  echo "  - que l'IP est correcte (${SSH_HOST})"
  echo "  - l'utilisateur SSH (${SSH_USER})"
  echo "  - la clé SSH ou le mot de passe configuré"
  exit 1
fi
echo -e "${GREEN}✅ Connexion SSH OK.${NC}"

# ==========================
# 3) Préparer dossiers & git sur le VPS
# ==========================

echo -e "${YELLOW}📁 Préparation des dossiers sur le VPS...${NC}"
remote "mkdir -p '${REMOTE_BASE_DIR}'"

echo -e "${YELLOW}📥 Mise à jour / clonage du backend sur le VPS...${NC}"
remote "
  set -e;
  cd '${REMOTE_BASE_DIR}';
  if [ ! -d '${REMOTE_BACKEND_DIR##*/}/.git' ]; then
    git clone '${BACKEND_REPO_URL}' '${REMOTE_BACKEND_DIR##*/}';
  else
    cd '${REMOTE_BACKEND_DIR##*/}';
    git pull --ff-only;
  fi
"

echo -e "${YELLOW}📥 Mise à jour / clonage du frontend sur le VPS...${NC}"
remote "
  set -e;
  cd '${REMOTE_BASE_DIR}';
  if [ ! -d '${REMOTE_FRONT_DIR##*/}/.git' ]; then
    git clone '${FRONT_REPO_URL}' '${REMOTE_FRONT_DIR##*/}';
  else
    cd '${REMOTE_FRONT_DIR##*/}';
    git pull --ff-only;
  fi
"

echo -e "${GREEN}✅ Dépôts mis à jour sur le VPS.${NC}"

# ==========================
# 4) Vérifier prérequis backend sur le VPS
# ==========================

echo -e "${YELLOW}🧪 Vérifications pré-déploiement backend...${NC}"
remote "
  set -e;
  cd '${REMOTE_BACKEND_DIR}';

  if [ ! -f '.env' ]; then
    if [ -f 'env.example' ]; then
      cp env.example .env
      echo '⚠️  .env créé depuis env.example sur le VPS. Pense à l'éditer avec les bonnes valeurs (DB, ALLOWED_HOSTS, etc.).';
      exit 1
    else
      echo '❌ Ni .env ni env.example trouvés dans le backend.';
      exit 1
    fi
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo '⚠️  Docker non trouvé sur le VPS. Le script backend gérera aussi le cas sans Docker.';
  fi
"
echo -e "${GREEN}✅ Backend prêt côté VPS (au moins structurellement).${NC}"

# ==========================
# 5) Vérifier prérequis frontend sur le VPS
# ==========================

echo -e "${YELLOW}🧪 Vérifications pré-déploiement frontend...${NC}"
remote "
  set -e;
  cd '${REMOTE_FRONT_DIR}';

  if [ ! -f '.env' ] && [ -f '.env.example' ]; then
    cp .env.example .env
    echo '⚠️  .env frontend créé depuis .env.example sur le VPS. Pense à l'éditer (URL API, etc.).';
    exit 1
  fi

  if [ ! -f 'docker-compose.yml' ]; then
    echo '❌ docker-compose.yml manquant dans le frontend.';
    exit 1
  fi
"
echo -e "${GREEN}✅ Frontend prêt côté VPS (au moins structurellement).${NC}"

# ==========================
# 6) Déploiement backend sur le VPS
# ==========================

echo -e "${YELLOW}🚀 Déploiement du backend sur le VPS...${NC}"
remote "
  set -e;
  cd '${REMOTE_BACKEND_DIR}';
  bash deploy.sh
"
echo -e "${GREEN}✅ Backend déployé sur le VPS.${NC}"

# ==========================
# 7) Déploiement frontend sur le VPS
# ==========================

echo -e "${YELLOW}🚀 Déploiement du frontend sur le VPS...${NC}"
remote "
  set -e;
  cd '${REMOTE_FRONT_DIR}';
  bash deploy.sh --build --restart
"
echo -e "${GREEN}✅ Frontend déployé sur le VPS.${NC}"

# ==========================
# 8) Vérifications de santé sur le VPS
# ==========================

echo -e "${YELLOW}🏥 Vérification de la santé des services sur le VPS...${NC}"

BACKEND_OK=false
FRONT_OK=false

if remote "curl -f http://localhost/api >/dev/null 2>&1"; then
  echo -e "${GREEN}✅ Backend répond sur http://localhost/api (sur le VPS).${NC}"
  BACKEND_OK=true
else
  echo -e "${RED}❌ Le backend ne répond pas correctement sur http://localhost/api (sur le VPS).${NC}"
fi

if remote "curl -f http://localhost >/dev/null 2>&1"; then
  echo -e "${GREEN}✅ Frontend répond sur http://localhost (sur le VPS).${NC}"
  FRONT_OK=true
else
  echo -e "${RED}❌ Le frontend ne répond pas correctement sur http://localhost (sur le VPS).${NC}"
fi

if [ "$BACKEND_OK" = true ] && [ "$FRONT_OK" = true ]; then
  echo -e "${GREEN}🎉 Déploiement global réussi : frontend et backend sont up sur le VPS.${NC}"
  echo "Tu peux ensuite configurer Nginx pour exposer ça sur ton domaine / IP publique."
  exit 0
else
  echo -e "${RED}⚠️  Un ou plusieurs services ne répondent pas correctement sur le VPS.${NC}"
  echo "Vérifie les logs Docker ou systemd directement sur le serveur."
  exit 1
fi


