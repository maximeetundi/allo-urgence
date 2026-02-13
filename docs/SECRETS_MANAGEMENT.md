# 🔐 Secrets Management - Allo Urgence

## ⚠️ IMPORTANT - Sécurité des Secrets

**NE JAMAIS:**
- ❌ Commiter les fichiers `.env` dans git
- ❌ Partager les secrets par email/Slack
- ❌ Utiliser des secrets faibles ou par défaut
- ❌ Réutiliser les mêmes secrets entre environnements

**TOUJOURS:**
- ✅ Générer des secrets forts et aléatoires
- ✅ Utiliser des secrets différents pour dev/staging/prod
- ✅ Stocker les secrets de production dans un gestionnaire sécurisé
- ✅ Faire une rotation régulière des secrets

---

## Génération de Secrets Forts

### Méthode 1: Script Automatique (Recommandé)

```bash
cd server
npm run generate-secrets
```

Cela génère:
- `JWT_SECRET`: 64 caractères (base64url)
- `DB_PASSWORD`: 32 caractères (base64url)

**Exemple de sortie:**
```
🔐 ═══════════════════════════════════════════════════════════
🔐  Strong Secrets Generator - Allo Urgence
🔐 ═══════════════════════════════════════════════════════════

Add these to your .env file:

─────────────────────────────────────────────────────────────
JWT_SECRET=k7L9mN2pQ4rS6tU8vW0xY2zA4bC6dE8fG0hI2jK4lM6nO8pQ0rS2tU4vW6xY8zA0
DB_PASSWORD=a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6
─────────────────────────────────────────────────────────────
```

### Méthode 2: Ligne de Commande

**Linux/macOS:**
```bash
# JWT_SECRET (64 caractères)
openssl rand -base64 48 | tr -d "=+/" | cut -c1-64

# DB_PASSWORD (32 caractères)
openssl rand -base64 24 | tr -d "=+/" | cut -c1-32
```

**Windows (PowerShell):**
```powershell
# JWT_SECRET
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | % {[char]$_})

# DB_PASSWORD
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
```

---

## Configuration par Environnement

### Développement Local

**Fichier:** `server/.env`

```bash
JWT_SECRET=dev-secret-min-32-chars-long-for-development-only
DB_PASSWORD=devpassword123
```

> ⚠️ Même en dev, utilisez des secrets d'au moins 32 caractères

### Staging

**Fichier:** `.env` (racine, pour Docker Compose)

```bash
JWT_SECRET=<généré avec npm run generate-secrets>
DB_PASSWORD=<généré avec npm run generate-secrets>
```

### Production

**Recommandation:** Utiliser un gestionnaire de secrets

#### Option 1: Variables d'Environnement Système

```bash
# Sur le serveur de production
export JWT_SECRET="<secret-fort-64-chars>"
export DB_PASSWORD="<password-fort-32-chars>"

# Puis démarrer l'application
docker-compose up -d
```

#### Option 2: Gestionnaire de Secrets Cloud

**AWS Secrets Manager:**
```bash
# Stocker le secret
aws secretsmanager create-secret \
  --name allo-urgence/jwt-secret \
  --secret-string "<secret-fort>"

# Récupérer dans l'application
JWT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id allo-urgence/jwt-secret \
  --query SecretString --output text)
```

**Google Cloud Secret Manager:**
```bash
# Stocker
echo -n "<secret-fort>" | gcloud secrets create jwt-secret --data-file=-

# Récupérer
JWT_SECRET=$(gcloud secrets versions access latest --secret="jwt-secret")
```

**Azure Key Vault:**
```bash
# Stocker
az keyvault secret set \
  --vault-name allo-urgence-vault \
  --name jwt-secret \
  --value "<secret-fort>"

# Récupérer
JWT_SECRET=$(az keyvault secret show \
  --vault-name allo-urgence-vault \
  --name jwt-secret \
  --query value -o tsv)
```

---

## Validation au Démarrage

Le serveur valide automatiquement les secrets au démarrage:

### Vérifications Effectuées

✅ **Variables requises présentes**
- `JWT_SECRET`, `DB_PASSWORD`, etc.

✅ **Longueur minimale**
- `JWT_SECRET` ≥ 32 caractères

✅ **Détection de secrets faibles**
- Mots comme "secret", "password", "change-me"

### Comportement

**Si validation échoue:**
```
❌ Missing required environment variables: JWT_SECRET, DB_PASSWORD
Error: Missing required environment variables: JWT_SECRET, DB_PASSWORD
```

**Si secrets faibles détectés:**
```
⚠️ JWT_SECRET appears to be a default/weak value. Please use a strong random secret in production
⚠️ DB_PASSWORD appears to be a default/weak value. Please use a strong password in production
```

---

## Rotation des Secrets

### Quand Faire une Rotation?

- 🔄 **Tous les 90 jours** (recommandé)
- 🚨 **Immédiatement** si compromis
- 👤 **Départ d'un employé** ayant accès
- 🔧 **Après un incident de sécurité**

### Procédure de Rotation JWT_SECRET

1. **Générer nouveau secret**
   ```bash
   npm run generate-secrets
   ```

2. **Mettre à jour .env**
   ```bash
   JWT_SECRET=<nouveau-secret>
   ```

3. **Redémarrer l'application**
   ```bash
   docker-compose restart backend
   ```

4. **⚠️ Impact:** Tous les tokens existants seront invalidés
   - Les utilisateurs devront se reconnecter

### Procédure de Rotation DB_PASSWORD

1. **Générer nouveau mot de passe**
   ```bash
   npm run generate-secrets
   ```

2. **Mettre à jour dans PostgreSQL**
   ```bash
   docker-compose exec db psql -U allourgence -c \
     "ALTER USER allourgence WITH PASSWORD '<nouveau-password>';"
   ```

3. **Mettre à jour .env**
   ```bash
   DB_PASSWORD=<nouveau-password>
   ```

4. **Redémarrer backend**
   ```bash
   docker-compose restart backend
   ```

---

## Checklist Sécurité

### Avant le Déploiement

- [ ] Secrets générés avec `npm run generate-secrets`
- [ ] JWT_SECRET ≥ 64 caractères
- [ ] DB_PASSWORD ≥ 32 caractères
- [ ] Fichier `.env` dans `.gitignore`
- [ ] Secrets différents pour chaque environnement
- [ ] Validation au démarrage activée

### En Production

- [ ] Secrets stockés dans gestionnaire sécurisé
- [ ] Accès aux secrets limité (principe du moindre privilège)
- [ ] Logs ne contiennent pas de secrets
- [ ] Plan de rotation documenté
- [ ] Backup des secrets (chiffré)

---

## Dépannage

### Erreur: "Missing required environment variables"

**Cause:** Variables manquantes dans `.env`

**Solution:**
```bash
# Copier le template
cp .env.example .env

# Générer les secrets
cd server && npm run generate-secrets

# Copier les secrets générés dans .env
```

### Erreur: "JWT_SECRET should be at least 32 characters"

**Cause:** Secret trop court

**Solution:**
```bash
# Générer un nouveau secret fort
npm run generate-secrets
```

### Warning: "appears to be a default/weak value"

**Cause:** Secret contient des mots comme "secret", "password"

**Solution:**
```bash
# Générer un vrai secret aléatoire
npm run generate-secrets
```

---

**Documentation mise à jour:** 2026-02-13  
**Version:** 1.0
