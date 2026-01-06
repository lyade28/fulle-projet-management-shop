## Guide de déploiement complet sur VPS (Docker + docker-compose global)

Ce guide explique comment déployer **ShopManagement** (backend Django + frontend Angular) sur un VPS  
avec **Docker** et **docker-compose**, en utilisant le fichier `docker-compose.yml` global.

### Architecture des dépôts Git

Le projet est organisé en **3 dépôts Git séparés** :

1. **`Shopmanagement-backend`** : Code Django (API, modèles, vues, etc.)
2. **`ShopManagement-Front`** : Code Angular (interface utilisateur)
3. **`fulle-projet-management-shop`** : Configuration de déploiement (docker-compose global, scripts, guide)

Ce guide part du principe que :

- Ton VPS est accessible à l’adresse **`185.97.144.208`**
- Tu te connectes en **root** (ou un autre utilisateur avec sudo)
- Le code des projets se trouvera dans **`/opt/shop-management`** sur le VPS
- Tu as accès aux 3 dépôts Git (URLs GitHub/GitLab)

---

## 1. Pré-requis sur le VPS

Connecte-toi au VPS :

```bash
ssh root@185.97.144.208
```

### 1.1. Mettre à jour le système

```bash
apt update && apt upgrade -y
```

### 1.2. Installer Docker

Si Docker n’est pas encore installé :

```bash
apt install -y ca-certificates curl gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Vérifie que Docker fonctionne :

```bash
docker ps
```

### 1.3. docker compose

La commande moderne est :

```bash
docker compose version
```

Si elle fonctionne, c’est bon. Sinon, installe `docker-compose` classique :

```bash
apt install -y docker-compose
```

---

## 2. Préparation du dossier de déploiement

Sur le VPS :

```bash
mkdir -p /opt/shop-management
cd /opt/shop-management
```

### 2.1. Structure finale attendue

Après le clonage des 3 dépôts, la structure sera :

```
/opt/shop-management/
├── Shopmanagement-backend/      # Repo 1 : Code Django
│   ├── manage.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── ...
├── ShopManagement-Front/         # Repo 2 : Code Angular
│   ├── package.json
│   ├── Dockerfile
│   └── ...
├── fulle-projet-management-shop/ # Repo 3 : Config déploiement
│   ├── docker-compose.yml
│   ├── deploy.sh
│   └── DEPLOYMENT_VPS.md
├── docker-compose.yml            # Copié depuis fulle-projet-management-shop/
└── .env                          # Fichier de configuration
```

Tu as deux options pour amener le code sur le VPS :

### Option A – Cloner directement les 3 dépôts sur le VPS (recommandé)

```bash
cd /opt/shop-management

# Cloner les 3 dépôts
git clone https://github.com/lyade28/Shopmanagement-backend.git
git clone https://github.com/lyade28/ShopManagement-Front.git
git clone https://github.com/lyade28/fulle-projet-management-shop.git

# Le docker-compose.yml global se trouve dans le repo fulle-projet-management-shop
# Il sera automatiquement dans /opt/shop-management/fulle-projet-management-shop/docker-compose.yml
```

**Important** : Après le clonage, tu dois copier le `docker-compose.yml` à la racine de `/opt/shop-management` :

```bash
cd /opt/shop-management
cp fulle-projet-management-shop/docker-compose.yml .
```

### Option B – Utiliser le script `deploy.sh` global (automatisé)

Sur **ta machine locale**, dans le dossier racine `management-boutique` :

```bash
cd /Users/dev-of/Documents/perso/dev/management-boutique
./deploy.sh
```

Ce script :

- se connecte en SSH au VPS
- crée `/opt/shop-management`
- clone / met à jour les 3 dépôts
- copie le `docker-compose.yml` à la racine
- lance le déploiement avec `docker compose up -d --build`

**Note** : Remplace `TON_USER` par ton nom d'utilisateur GitHub/GitLab dans les URLs ci-dessus.

---

## 3. Fichier `.env` pour le docker-compose global

Sur le VPS, dans `/opt/shop-management`, crée un fichier `.env` :

```bash
cd /opt/shop-management
nano .env
```

Exemple de contenu :

```env
# --- Django / Backend ---
SECRET_KEY=change_moi_en_une_grande_chaine_aleatoire
DEBUG=False
ALLOWED_HOSTS=185.97.144.208,localhost,127.0.0.1
FRONTEND_URL=http://185.97.144.208

# --- Base de données Postgres ---
DATABASE_NAME=shop_management
DATABASE_USER=shop_user
DATABASE_PASSWORD=mot_de_passe_postgres_solide

# --- Redis ---
REDIS_HOST=redis
REDIS_PORT=6379

# --- Email (optionnel, adapte si besoin) ---
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=ton_email@gmail.com
EMAIL_HOST_PASSWORD=ton_mot_de_passe_ou_app_password
```

Enregistre et quitte (`Ctrl+O`, `Entrée`, `Ctrl+X` avec nano).

---

## 4. Lancer les conteneurs avec docker-compose global

Toujours sur le VPS :

```bash
cd /opt/shop-management

# (optionnel) Télécharger les dernières images si tu modifies les images de base
docker compose pull || docker-compose pull

# Build + démarrage en arrière-plan
docker compose up -d --build || docker-compose up -d --build
```

Ce que cela lance :

- `db` : PostgreSQL 15
- `redis` : Redis 7
- `backend` : Django + Gunicorn sur le port 8000
- `frontend` : Angular servi sur le port 80 (Nginx dans le Dockerfile du front)

---

## 5. Vérifications après démarrage

### 5.1. Vérifier l’état des conteneurs

```bash
cd /opt/shop-management
docker compose ps || docker-compose ps
```

Tu dois voir les services `db`, `redis`, `backend`, `frontend` en statut `Up`.

### 5.2. Vérifier les logs

```bash
docker compose logs -f backend || docker-compose logs -f backend
docker compose logs -f frontend || docker-compose logs -f frontend
```

`Ctrl+C` pour quitter les logs.

### 5.3. Tester depuis le VPS

Depuis le VPS :

```bash
curl http://localhost:8000/api/
curl http://localhost
```

Depuis ton navigateur (depuis ton PC) :

- Frontend : `http://185.97.144.208`
- Backend API (si besoin direct) : `http://185.97.144.208:8000/api/`

---

## 6. Gérer le cycle de vie (arrêt, redémarrage, mise à jour)

### 6.1. Arrêter les services

```bash
cd /opt/shop-management
docker compose down || docker-compose down
```

### 6.2. Redémarrer les services

```bash
cd /opt/shop-management
docker compose up -d || docker-compose up -d
```

### 6.3. Mettre à jour le code et redéployer

Sur le VPS :

```bash
cd /opt/shop-management

# Mettre à jour les 3 dépôts
cd Shopmanagement-backend
git pull --ff-only

cd ../ShopManagement-Front
git pull --ff-only

cd ../fulle-projet-management-shop
git pull --ff-only

# Copier le docker-compose.yml mis à jour si nécessaire
cd ..
cp fulle-projet-management-shop/docker-compose.yml .

# Rebuild et redémarrer
docker compose up -d --build || docker-compose up -d --build
```

Ou bien, depuis ta machine locale, relancer le script global :

```bash
cd /Users/dev-of/Documents/perso/dev/management-boutique
./deploy.sh
```

Le script mettra automatiquement à jour les 3 dépôts et redéploiera.

---

## 7. Création d’un superutilisateur Django

Une fois le backend démarré :

```bash
cd /opt/shop-management

docker compose exec backend python manage.py createsuperuser \
  || docker-compose exec backend python manage.py createsuperuser
```

Suis les instructions (email, mot de passe).

Tu pourras ensuite te connecter à l’admin Django :

- `http://185.97.144.208:8000/admin/`

---

## 8. (Optionnel) Ajouter Nginx / HTTPS devant

Pour l’instant :

- le **frontend** répond déjà sur le port `80` du VPS (via le container `frontend`)
- le **backend** répond sur `8000`

Pour une configuration plus avancée :

- ajouter un **reverse proxy Nginx** (en dehors ou dans un conteneur dédié)
- configurer un **nom de domaine** (DNS → IP du VPS)
- ajouter **Let’s Encrypt** pour le HTTPS

Cela peut se faire par un autre `docker-compose` ou avec Nginx installé directement sur le VPS.

---

## 9. Résumé des commandes utiles

- **Voir l’état des services** :

```bash
cd /opt/shop-management
docker compose ps || docker-compose ps
```

- **Voir les logs** :

```bash
docker compose logs -f backend || docker-compose logs -f backend
docker compose logs -f frontend || docker-compose logs -f frontend
```

- **Arrêter** :

```bash
docker compose down || docker-compose down
```

- **Redémarrer avec rebuild** :

```bash
docker compose up -d --build || docker-compose up -d --build
```

Avec ce guide, tu peux déployer ton application de A à Z sur ton VPS uniquement avec Docker et docker-compose.  
En cas de problème, les premières choses à regarder sont toujours : `docker compose ps` et `docker compose logs`.
