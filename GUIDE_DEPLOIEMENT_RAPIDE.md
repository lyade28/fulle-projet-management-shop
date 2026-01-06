# 🚀 Guide de déploiement rapide - Étape par étape

## 📋 Prérequis

Avant de commencer, assure-toi d'avoir :

- ✅ Accès SSH à ton VPS (`185.97.144.208`)
- ✅ Docker et Docker Compose installés sur le VPS
- ✅ Les 3 repos Git accessibles

---

## 🎯 Option 1 : Déploiement automatique (RECOMMANDÉ)

### Étape 1 : Générer la SECRET_KEY

Sur **ta machine locale** :

```bash
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

**Copie la clé générée** (exemple : `django-insecure-abc123xyz...`)

### Étape 2 : Se connecter au VPS et créer le .env

```bash
ssh root@185.97.144.208
```

Une fois connecté au VPS :

```bash
# Créer le dossier si nécessaire
mkdir -p /opt/shop-management
cd /opt/shop-management

# Créer le fichier .env
nano .env
```

### Étape 3 : Remplir le fichier .env

Colle ce contenu dans le fichier `.env` (remplace les valeurs entre `<...>`) :

```env
# --- Django / Backend ---
SECRET_KEY=<COLLE_LA_CLE_GENERE_ICI>
DEBUG=False
ALLOWED_HOSTS=185.97.144.208,localhost,127.0.0.1
FRONTEND_URL=http://185.97.144.208

# --- Base de données Postgres ---
DATABASE_NAME=shop_management
DATABASE_USER=shop_user
DATABASE_PASSWORD=<CHOISIS_UN_MOT_DE_PASSE_FORT_ICI>

# --- Redis ---
REDIS_HOST=redis
REDIS_PORT=6379

# --- Email (optionnel) ---
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=libasseyadee@gmail.com
EMAIL_HOST_PASSWORD=P@pajtm3
```

**Important** :

- Remplace `<COLLE_LA_CLE_GENERE_ICI>` par la SECRET_KEY générée à l'étape 1
- Remplace `<CHOISIS_UN_MOT_DE_PASSE_FORT_ICI>` par un mot de passe fort (ex: `MonMotDePasse123!@#`)

**Pour sauvegarder dans nano** :

- Appuie sur `Ctrl + O` puis `Entrée` pour sauvegarder
- Appuie sur `Ctrl + X` pour quitter

### Étape 4 : Quitter le VPS et lancer le déploiement

```bash
exit
```

Maintenant, sur **ta machine locale** :

```bash
cd /Users/dev-of/Documents/perso/dev/management-boutique
chmod +x deploy.sh
./deploy.sh
```

Le script va automatiquement :

1. Se connecter au VPS
2. Cloner les 3 repos
3. Copier le docker-compose.yml
4. Lancer le déploiement avec Docker
5. Vérifier que tout fonctionne

---

## 🎯 Option 2 : Déploiement manuel (si tu préfères)

### Étape 1 : Se connecter au VPS

```bash
ssh root@185.97.144.208
```

### Étape 2 : Cloner les 3 repos

```bash
cd /opt/shop-management

# Cloner les repos
git clone https://github.com/lyade28/Shopmanagement-backend.git
git clone https://github.com/lyade28/ShopManagement-Front.git
git clone https://github.com/lyade28/fulle-projet-management-shop.git
```

### Étape 3 : Copier le docker-compose.yml

```bash
cp fulle-projet-management-shop/docker-compose.yml .
```

### Étape 4 : Créer le fichier .env

```bash
# Copier depuis l'exemple
cp Shopmanagement-backend/env.example .env

# Éditer le fichier
nano .env
```

Remplis le fichier avec les valeurs (voir Option 1, Étape 3).

### Étape 5 : Lancer le déploiement

```bash
# Build et démarrage
docker compose up -d --build

# Attendre quelques secondes
sleep 10

# Vérifier l'état
docker compose ps
```

### Étape 6 : Appliquer les migrations (si nécessaire)

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py collectstatic --noinput
```

---

## ✅ Vérification après déploiement

### Vérifier que les services tournent

Sur le VPS :

```bash
docker compose ps
```

Tu devrais voir 4 services en statut `Up` :

- `shop_management_db` (PostgreSQL)
- `shop_management_redis` (Redis)
- `shop_management_backend` (Django)
- `shop_management_frontend` (Angular)

### Tester l'accès

Depuis ton navigateur :

- **Frontend** : http://185.97.144.208
- **Backend API** : http://185.97.144.208:8000/api/
- **Admin Django** : http://185.97.144.208:8000/admin/

### Voir les logs (en cas de problème)

```bash
# Logs de tous les services
docker compose logs -f

# Logs du backend uniquement
docker compose logs -f backend

# Logs du frontend uniquement
docker compose logs -f frontend
```

---

## 🔧 Créer un superutilisateur Django

Pour accéder à l'admin Django :

```bash
ssh root@185.97.144.208
cd /opt/shop-management
docker compose exec backend python manage.py createsuperuser
```

Suis les instructions (email, username, password).

---

## 🆘 En cas de problème

### Les conteneurs ne démarrent pas

```bash
# Voir les logs
docker compose logs

# Redémarrer
docker compose restart

# Rebuild complet
docker compose down
docker compose up -d --build
```

### Erreur de connexion à la base de données

Vérifie que :

- Le mot de passe dans `.env` correspond à `DATABASE_PASSWORD`
- Le service `db` est bien démarré : `docker compose ps`

### Le frontend ne charge pas

Vérifie que :

- Le port 80 est libre : `netstat -tuln | grep 80`
- Le conteneur frontend tourne : `docker compose ps frontend`
- Les logs : `docker compose logs frontend`

---

## 📝 Commandes utiles

```bash
# Arrêter tous les services
docker compose down

# Redémarrer
docker compose restart

# Voir l'état
docker compose ps

# Voir les logs
docker compose logs -f

# Accéder au shell du backend
docker compose exec backend bash

# Accéder au shell du frontend
docker compose exec frontend sh
```

---

## ✅ C'est tout !

Une fois le déploiement terminé, ton application sera accessible sur :

- **Frontend** : http://185.97.144.208
- **Backend** : http://185.97.144.208:8000/api/

🎉 **Félicitations, ton application est déployée !**
