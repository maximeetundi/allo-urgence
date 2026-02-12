# Backend - Node.js 20
FROM node:20-alpine

WORKDIR /app

# Copier package.json et installer dépendances
COPY package*.json ./
RUN npm ci --only=production

# Copier le code source
COPY src/ ./src/
COPY data/ ./data/

# Exposer le port
EXPOSE 3000

# Commande de démarrage
CMD ["npm", "start"]
