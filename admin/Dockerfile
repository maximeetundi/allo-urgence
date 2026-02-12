# Admin Panel - Next.js
FROM node:20-alpine

WORKDIR /app

# Copier package.json et installer dépendances
COPY package*.json ./
RUN npm install

# Copier le code source
COPY . .

# Build l'application
RUN npm run build

# Exposer le port
EXPOSE 3356

# Commande de démarrage
CMD ["npm", "start"]
