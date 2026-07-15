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

## Démarrage rapide

### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows : .venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py importer_statistiques ../data/donnees_statistiques_senegal_fictives.csv
python manage.py runserver
```

### Web
```bash
cd web
npm install
npm run dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## Workflow d'équipe

Voir [CONTRIBUTING.md](./CONTRIBUTING.md) pour les conventions de branches et de commits.

## Questions de démonstration

1. Quelle est la population de Thiès en 2024 ?
2. Compare le chômage à Dakar, Thiès et Saint-Louis en 2024.
3. Montre l'évolution de l'accès à Internet à Kaolack entre 2020 et 2024.
4. Quelles sont les cinq régions les plus peuplées en 2024 ?
5. Quelle est la population totale estimée du Sénégal en 2024 ?
