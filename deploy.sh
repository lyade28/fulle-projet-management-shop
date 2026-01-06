#!/bin/bash

##
## Script de déploiement global ShopManagement (frontend + backend)
## à lancer depuis ta machine locale.
##
## Il va :
##  - se connecter en SSH à ton VPS
##  - cloner / mettre à jour les 3 dépôts (backend, frontend, fulle-projet-management-shop)
##  - copier le docker-compose.yml global à la racine
##  - lancer le déploiement avec docker-compose global
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

# Répertoire de base sur le VPS où seront les 3 projets
REMOTE_BASE_DIR="/opt/shop-management"

# URLs des dépôts Git
BACKEND_REPO_URL="https://github.com/lyade28/Shopmanagement-backend.git"
FRONT_REPO_URL="https://github.com/lyade28/ShopManagement-Front.git"
DEPLOY_REPO_URL="https://github.com/lyade28/fulle-projet-management-shop.git"

# Chemins des projets sur le VPS
REMOTE_BACKEND_DIR="$REMOTE_BASE_DIR/Shopmanagement-backend"
REMOTE_FRONT_DIR="$REMOTE_BASE_DIR/ShopManagement-Front"
REMOTE_DEPLOY_DIR="$REMOTE_BASE_DIR/fulle-projet-management-shop"

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

echo -e "${YELLOW}🔎 Vérifications locales...${NC}"

if [ ! -f "docker-compose.yml" ]; then
  echo -e "${RED}❌ 'docker-compose.yml' introuvable dans le dossier actuel.${NC}"
  echo "Assure-toi d'être dans le dossier du repo 'fulle-projet-management-shop' (repo de déploiement)."
  exit 1
fi

if [ ! -f "DEPLOYMENT_VPS.md" ]; then
  echo -e "${YELLOW}⚠️  'DEPLOYMENT_VPS.md' introuvable (optionnel mais recommandé).${NC}"
fi

echo -e "${GREEN}✅ Fichiers de déploiement trouvés.${NC}"

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

echo -e "${YELLOW}📥 Mise à jour / clonage du repo de déploiement sur le VPS...${NC}"
remote "
  set -e;
  cd '${REMOTE_BASE_DIR}';
  if [ ! -d '${REMOTE_DEPLOY_DIR##*/}/.git' ]; then
    git clone '${DEPLOY_REPO_URL}' '${REMOTE_DEPLOY_DIR##*/}';
  else
    cd '${REMOTE_DEPLOY_DIR##*/}';
    git pull --ff-only;
  fi
"

echo -e "${YELLOW}📋 Copie du docker-compose.yml global à la racine...${NC}"
remote "
  set -e;
  cd '${REMOTE_BASE_DIR}';
  if [ -f '${REMOTE_DEPLOY_DIR##*/}/docker-compose.yml' ]; then
    cp '${REMOTE_DEPLOY_DIR##*/}/docker-compose.yml' ./docker-compose.yml;
    echo '✅ docker-compose.yml copié.';
  else
    echo '❌ docker-compose.yml introuvable dans fulle-projet-management-shop.';
    exit 1;
  fi
"

echo -e "${GREEN}✅ Dépôts mis à jour et docker-compose.yml copié sur le VPS.${NC}"

# ==========================
# 4) Vérifier prérequis sur le VPS
# ==========================

echo -e "${YELLOW}🧪 Vérifications pré-déploiement...${NC}"
remote "
  set -e;
  cd '${REMOTE_BASE_DIR}';

  # Vérifier Docker
  if ! command -v docker >/dev/null 2>&1; then
    echo '❌ Docker n'\''est pas installé sur le VPS.';
    echo 'Installe Docker d'\''abord (voir DEPLOYMENT_VPS.md).';
    exit 1
  fi

  if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo '❌ docker-compose n'\''est pas installé sur le VPS.';
    echo 'Installe docker-compose d'\''abord (voir DEPLOYMENT_VPS.md).';
    exit 1
  fi

  # Vérifier le fichier .env à la racine
  if [ ! -f '.env' ]; then
    if [ -f '${REMOTE_BACKEND_DIR##*/}/env.example' ]; then
      echo '⚠️  .env manquant. Création depuis env.example du backend...';
      cp '${REMOTE_BACKEND_DIR##*/}/env.example' .env;
      echo '⚠️  IMPORTANT: Édite le fichier .env avec les bonnes valeurs (SECRET_KEY, DATABASE_PASSWORD, ALLOWED_HOSTS, etc.)';
      echo 'Puis relance ce script.';
      exit 1
    else
      echo '❌ Ni .env ni env.example trouvés.';
      exit 1
    fi
  fi

  # Vérifier que docker-compose.yml existe
  if [ ! -f 'docker-compose.yml' ]; then
    echo '❌ docker-compose.yml introuvable à la racine.';
    exit 1
  fi
"
echo -e "${GREEN}✅ Prérequis vérifiés sur le VPS.${NC}"

# ==========================
# 5) Déploiement avec docker-compose global
# ==========================

echo -e "${YELLOW}🚀 Déploiement avec docker-compose global sur le VPS...${NC}"
remote "
  set -e;
  cd '${REMOTE_BASE_DIR}';

  # Arrêter les conteneurs existants s'ils tournent
  docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true;

  # Build et démarrage
  echo '📦 Build des images...';
  docker compose build --no-cache || docker-compose build --no-cache;

  echo '▶️  Démarrage des services...';
  docker compose up -d || docker-compose up -d;

  # Attendre que les services soient prêts
  echo '⏳ Attente du démarrage des services (30 secondes)...';
  sleep 30;

  # Vérifier que les conteneurs sont bien démarrés
  echo '🔍 Vérification de l'\''état des conteneurs...';
  docker compose ps || docker-compose ps;

  # Attendre que la base de données soit prête avant les migrations
  echo '⏳ Attente que la base de données soit prête...';
  sleep 5;

  # Appliquer les migrations Django
  echo '📊 Application des migrations...';
  docker compose exec -T backend python manage.py migrate --noinput || docker-compose exec -T backend python manage.py migrate --noinput || true;

  # Collecter les fichiers statiques
  echo '📁 Collecte des fichiers statiques...';
  docker compose exec -T backend python manage.py collectstatic --noinput || docker-compose exec -T backend python manage.py collectstatic --noinput || true;
"
echo -e "${GREEN}✅ Déploiement terminé sur le VPS.${NC}"

# ==========================
# 6) Vérifications de santé sur le VPS
# ==========================

echo -e "${YELLOW}🏥 Vérification de la santé des services sur le VPS...${NC}"

# Attendre un peu plus que les services soient complètement prêts
echo -e "${YELLOW}⏳ Attente supplémentaire pour que les services soient prêts (10 secondes)...${NC}"
sleep 10

BACKEND_OK=false
FRONT_OK=false

# Essayer plusieurs fois pour le backend (il peut prendre du temps à démarrer)
for i in {1..3}; do
  if remote "curl -f http://localhost:8000/api/ >/dev/null 2>&1 || curl -f http://localhost/api/ >/dev/null 2>&1"; then
    echo -e "${GREEN}✅ Backend répond sur http://localhost:8000/api/ (sur le VPS).${NC}"
    BACKEND_OK=true
    break
  else
    if [ $i -lt 3 ]; then
      echo -e "${YELLOW}⏳ Tentative $i/3 : Backend pas encore prêt, attente de 5 secondes...${NC}"
      sleep 5
    fi
  fi
done

if [ "$BACKEND_OK" = false ]; then
  echo -e "${RED}❌ Le backend ne répond pas correctement après 3 tentatives.${NC}"
  echo -e "${YELLOW}💡 Vérifie les logs avec: ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose logs backend'${NC}"
fi

# Essayer plusieurs fois pour le frontend
for i in {1..3}; do
  if remote "curl -f http://localhost >/dev/null 2>&1"; then
    echo -e "${GREEN}✅ Frontend répond sur http://localhost (sur le VPS).${NC}"
    FRONT_OK=true
    break
  else
    if [ $i -lt 3 ]; then
      echo -e "${YELLOW}⏳ Tentative $i/3 : Frontend pas encore prêt, attente de 5 secondes...${NC}"
      sleep 5
    fi
  fi
done

if [ "$FRONT_OK" = false ]; then
  echo -e "${RED}❌ Le frontend ne répond pas correctement après 3 tentatives.${NC}"
  echo -e "${YELLOW}💡 Vérifie les logs avec: ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose logs frontend'${NC}"
fi

if [ "$BACKEND_OK" = true ] && [ "$FRONT_OK" = true ]; then
  echo ""
  echo -e "${GREEN}🎉 Déploiement global réussi : frontend et backend sont up sur le VPS.${NC}"
  echo ""
  echo "📋 URLs d'accès :"
  echo "  - Frontend : http://${SSH_HOST}"
  echo "  - Backend API : http://${SSH_HOST}:8000/api/"
  echo "  - Admin Django : http://${SSH_HOST}:8000/admin/"
  echo ""
  echo "💡 Prochaines étapes :"
  echo "  - Configure Nginx pour exposer sur ton domaine / IP publique"
  echo "  - Configure SSL/HTTPS avec Let's Encrypt"
  echo "  - Crée un superuser Django : ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose exec backend python manage.py createsuperuser'"
  exit 0
else
  echo ""
  echo -e "${RED}⚠️  Un ou plusieurs services ne répondent pas correctement sur le VPS.${NC}"
  echo ""
  echo "🔍 Commandes utiles pour diagnostiquer :"
  echo "  - Voir l'état des conteneurs : ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose ps'"
  echo "  - Logs backend : ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose logs backend'"
  echo "  - Logs frontend : ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose logs frontend'"
  echo "  - Logs de tous les services : ssh ${SSH_USER}@${SSH_HOST} 'cd ${REMOTE_BASE_DIR} && docker compose logs'"
  exit 1
fi


