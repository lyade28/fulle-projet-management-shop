#!/bin/bash

##
## Script de diagnostic pour PostgreSQL sur le VPS
##

SSH_USER="root"
SSH_HOST="185.97.144.208"
REMOTE_BASE_DIR="/opt/shop-management"

echo "🔍 Diagnostic PostgreSQL sur le VPS..."
echo ""

ssh ${SSH_USER}@${SSH_HOST} "
  set -e;
  cd ${REMOTE_BASE_DIR};
  
  echo '📋 État des conteneurs:';
  docker compose ps;
  echo '';
  
  echo '📋 Logs PostgreSQL (50 dernières lignes):';
  docker compose logs --tail=50 db;
  echo '';
  
  echo '📋 Variables d'\''environnement du conteneur db:';
  docker compose exec db env | grep POSTGRES || echo '⚠️  Le conteneur db n'\''est pas accessible';
  echo '';
  
  echo '📋 Test de connexion PostgreSQL:';
  docker compose exec db pg_isready -U \${POSTGRES_USER:-shop_user} || echo '⚠️  PostgreSQL n'\''est pas prêt';
  echo '';
  
  echo '📋 Vérification du fichier .env:';
  if [ -f .env ]; then
    echo '✅ Fichier .env existe';
    echo 'Variables DATABASE_*:';
    grep -E '^DATABASE_' .env || echo '⚠️  Aucune variable DATABASE_* trouvée';
  else
    echo '❌ Fichier .env introuvable!';
  fi;
"

