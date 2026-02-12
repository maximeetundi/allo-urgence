Cahier des charges — Allo Urgence (Version
professionnelle avancée)
1. Vision produit
Allo Urgence est une application mobile de gestion intelligente des flux dans les services d’urgence
hospitaliers, spécifiquement pensée pour un déploiement au Québec, où les urgences fonctionnent
selon un système de triage médical strict.
L’application doit permettre :
• 
• 
• 
• 
• 
⚠
️ 
Une pré‑inscription des patients avant leur arrivée
Une meilleure priorisation médicale
Une réduction du temps passé en salle d’attente
Une visibilité en temps réel du parcours patient
Une coordination fluide entre patients, infirmiers et médecins
Important : L’application n’effectue PAS de diagnostic médical et ne remplace jamais le jugement
clinique.
2. Plateforme technologique obligatoire
Application mobile
L’application sera développée en Flutter afin de garantir :
• 
• 
• 
• 
• 
Une base de code unique
Compatibilité Android et iOS
Maintenance simplifiée
Performance proche du natif
UI moderne et réactive
Architecture recommandée
Mobile Flutter
⬇
API sécurisée
⬇
Backend (Node, Go ou Rust recommandé)
⬇
Base de données sécurisée (PostgreSQL recommandé)
Temps réel : WebSocket ou Firebase.
1
3. Fonctionnement réel des urgences au Québec (à respecter
absolument)
Au Québec, les patients ne sont pas traités selon l’ordre d’arrivée, mais selon la gravité.
Le système utilisé est une échelle de triage médical à 5 niveaux :
Niveau
Priorité
Exemple
1
Réanimation
Arrêt cardiaque
2
Très urgent
Accident grave
3
Urgent
Douleur intense
4
Moins urgent Infection mineure
5
Non urgent
Symptômes légers
👉 L’application doit refléter cette logique.
Cependant : Le niveau final est TOUJOURS validé par un infirmier. Le patient ne fait qu’un
pré‑classement.
4. Inscription patient — données obligatoires
Au Québec, chaque patient possède une carte d’assurance maladie.
Carte d’assurance maladie (RAMQ)
C’est une carte gouvernementale qui :
• 
• 
• 
• 
Identifie officiellement le patient
Permet l’accès aux soins
Contient un numéro unique
Est demandée lors de l’arrivée à l’hôpital
Données à collecter lors de l’inscription
Obligatoires : - Nom - Prénom - Date de naissance - Numéro de carte d’assurance maladie (optionnel
au début mais recommandé) - Téléphone - Contact d’urgence
Optionnelles : - Allergies - Conditions connues - Médicaments
⚠
️ Minimiser les données pour protéger la vie privée.
2
5. Choix de la priorité par le patient (pré‑triage intelligent)
L’application doit proposer un questionnaire guidé pour aider le patient à choisir la priorité.
Exemple de catégories visibles :
🔴 Accident / traumatisme
🔴 Difficulté respiratoire
🔴 Douleur sévère
🟠 Fièvre élevée
🟡 Blessure légère
🟢 Consultation simple
Règles critiques
• 
• 
• 
• 
Interface très simple
Icônes + couleurs
Maximum 5–7 questions
Pas de jargon médical
👉 Après le questionnaire, l’app affiche :
"Niveau estimé : URGENT"
Mais ajoute :
"Le niveau final sera confirmé par un professionnel de santé." 
6. Parcours patient détaillé
1. 
2. 
3. 
4. 
5. 
6. 
7. 
8. 
9. 
Télécharge l’application
Crée un compte
Remplit le pré‑triage
Obtient un ticket
Voit le temps estimé
Se rend à l’hôpital au moment recommandé
Passe au triage réel
Attend la consultation
Est pris en charge
7. Fonctionnalités Patients
Critiques
• 
• 
• 
• 
Authentification sécurisée
Création de ticket
Pré‑triage
Position dans la file
3
• 
• 
Notifications push
Heure estimée de passage
Avancées (fortement recommandées)
• 
• 
• 
• 
• 
Check‑in via QR code à l’arrivée
Navigation vers l’hôpital
Partage du statut avec un proche
Mode accessibilité
Multilingue
8. Fonctionnalités Infirmiers
• 
• 
• 
• 
• 
• 
Dashboard temps réel
Liste priorisée
Fiche triage rapide
Validation / modification du niveau
Attribution d’une salle
Alertes pour cas critiques
Objectif majeur :
👉 effectuer un triage en moins de 
60 secondes.
9. Fonctionnalités Médecins
• 
• 
• 
• 
• 
Liste automatiquement triée
Vue synthétique du triage
Notes rapides
Statut traité
Historique
Interface ultra minimaliste.
10. UX — règles critiques pour une app d’urgence
Concevoir pour :
• 
• 
• 
personnes stressées
environnement bruyant
manipulation à une main
Obligations UX
• 
• 
• 
Gros boutons
Contraste élevé
Parcours < 30 secondes
4
Texte simple
• 
Règle d’or : ne jamais complexifier.
11. Sécurité et confidentialité (TRÈS IMPORTANT)
Les données de santé sont extrêmement sensibles.
Obligatoire :
• 
• 
• 
• 
• 
Chiffrement TLS
Données chiffrées au repos
Authentification forte pour le personnel
Journalisation
Gestion des rôles
Avant déploiement : 👉 réaliser une évaluation d’impact sur la vie privée.
12. Performance cible
• 
• 
• 
Temps de réponse < 300 ms
Support : 1 000+ utilisateurs / hôpital
Disponibilité cible : 99.9%
13. Risques majeurs
Techniques
• 
• 
• 
Latence
Crash
Perte de données
Métier
• 
• 
Mauvaise priorisation
Rejet par les soignants
Légaux
• 
• 
Non conformité
Fuite d’informations
5
14. Stratégie de déploiement
Étape 1 — Proof of Concept
Tester dans un seul hôpital.
Étape 2 — Pilote
Collecter le feedback réel.
Étape 3 — Expansion
Déploiement multi‑établissements.
15. KPIs
• 
• 
• 
• 
Temps moyen d’attente
Temps triage → médecin
Taux d’abandon
Satisfaction patient
16. Facteurs clés de succès
• 
• 
• 
• 
Simplicité extrême
Rapidité
Adoption par le personnel
Sécurité irréprochable
⚠
️ Recommandation d’expert (très important)
👉 Ne jamais laisser l’utilisateur faire un auto‑diagnostic.
👉 Toujours laisser la décision finale au personnel médical.
👉 Concevoir pour les pires situations.
👉 Tester avec de vrais soignants.
Conclusion
Allo Urgence peut devenir une solution majeure d’optimisation des urgences si l’application reste
simple, rapide et parfaitement sécurisée.
Ce document correspond désormais à un niveau professionnel, adapté pour :
