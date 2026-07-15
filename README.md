# Diiwan

Agent conversationnel de statistiques régionales du Sénégal — projet de fin de formation BTS APD.

**Équipe** : Maïmouna Sall (backend), Ngoné Gueye (frontend web), Rokhy Marone (mobile)

> ⚠️ Toutes les données utilisées sont **pédagogiques et fictives**. Elles imitent la structure de données d'une agence comme l'ANSD mais ne contiennent aucune donnée officielle.

## Structure du dépôt

```
Diiwan/
├── backend/     Django + DRF + PostgreSQL/PostGIS — Maïmouna
├── web/         React (Vite) — Ngoné
├── mobile/      Flutter — Rokhy
├── docs/        Schémas, captures d'écran, notes d'architecture
└── data/        CSV source et dictionnaire de données
```

## 🚀 Déploiement en Production

### 1. Frontend Web (Vercel)
L'application web est déployée sur Vercel : **[Lien vers l'application Vercel]** *(à remplacer par l'URL finale Vercel)*
- Le fichier `web/vercel.json` gère le routage SPA.
- La variable d'environnement `VITE_API_BASE_URL` pointe vers le backend Render.

### 2. Backend Django (Render)
L'API REST est hébergée sur Render : **https://diiwan-backend.onrender.com**
- Base de données : PostgreSQL managé avec extension PostGIS activée.
- *Note : sur le plan gratuit de Render, le premier appel après 15 min d'inactivité peut prendre 30 à 60 secondes pour réveiller le serveur.*

### 3. Application Mobile (Android APK)
L'application Flutter est compilée nativement pour Android.
- Téléchargez l'APK de release : **[Lien vers l'APK]** *(à fournir après le build final)*
- L'application est configurée pour pointer automatiquement vers l'API de production en mode release.

---

## 🛠️ Démarrage rapide (Développement Local)

### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows : .venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py importer_statistiques ../data/donnees_statistiques_senegal_fictives.csv
python manage.py importer_geometrie ../data/regions_senegal.geojson
python manage.py runserver
```

Variables d'environnement utiles dans `backend/.env` :
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`
- `SECRET_KEY` et `DEBUG=True`
- `GEMINI_API_KEY` (optionnel, pour l'extraction d'intention IA)

### Web
```bash
cd web
npm install
npm run dev
```
L'application web est disponible sur `http://localhost:5173`.

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```
Pour cibler un backend distant ou local :
```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000
```

## Workflow d'équipe

Voir [CONTRIBUTING.md](./CONTRIBUTING.md) pour les conventions de branches et de commits.

## Questions de démonstration

Ces 5 questions couvrent les opérations principales du barème :

1. Quelle est la population de Thiès en 2024 ? *(value)*
2. Compare le chômage à Dakar, Thiès et Saint-Louis en 2024. *(compare + graphique bar)*
3. Montre l'évolution de l'accès à Internet à Kaolack entre 2020 et 2024. *(trend + graphique line)*
4. Quelles sont les cinq régions les plus peuplées en 2024 ? *(ranking + graphique bar)*
5. Quelle est la population totale estimée du Sénégal en 2024 ? *(sum)*

## Limites et améliorations possibles

- **Jeu de données fictif** : les valeurs ne proviennent pas de l'ANSD et ne doivent pas être citées comme des statistiques officielles.
- **NLU déterministe limité** : l'analyseur repose sur des alias prédéfinis ; les formulations très libres peuvent demander une clarification.
- **IA générative optionnelle** : l'extraction d'intention via Gemini (`USE_GENERATIVE_AI`) est un bonus ; le repli vers l'analyseur déterministe reste actif en cas d'échec ou si la clé API est absente.
- **Carte choroplèthe** : dépend de l'import GeoJSON PostGIS et de l'endpoint `/api/regions/geojson/`.
- **Pas d'authentification utilisateur** : l'API est ouverte en contexte pédagogique ; une authentification serait nécessaire en production.
