# Allo Urgence - Panel Admin

Panel d'administration Next.js pour la gestion des urgences hospitalières.

## 🚀 Démarrage

### Développement local

```bash
# Installer les dépendances
npm install

# Lancer le serveur de développement
npm run dev
```

Le panel sera accessible sur `http://localhost:3001`

### Production (Docker)

```bash
# Build et lancement
docker-compose up -d admin
```

## 📁 Structure

```
admin/
├── app/              # Pages Next.js
│   ├── dashboard/    # Dashboard avec stats
│   ├── users/        # Gestion utilisateurs
│   ├── hospitals/    # Gestion hôpitaux
│   └── tickets/      # Gestion tickets/file d'attente
├── components/       # Composants React
├── lib/             # Services API
├── Dockerfile       # Image Docker
└── package.json     # Dépendances
```

## 🔑 Accès

- URL: `http://localhost:3001` (dev) ou `https://admin.allo-urgence.tech-afm.com` (prod)
- Comptes de démo:
  - Infirmier: `nurse@allourgence.ca` / `nurse123`
  - Médecin: `doctor@allourgence.ca` / `doctor123`

## 🛠️ Technologies

- Next.js 14
- React 18
- TypeScript
- Tailwind CSS
- Recharts (graphiques)
- Lucide React (icônes)
