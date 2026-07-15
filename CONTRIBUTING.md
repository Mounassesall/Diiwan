# Guide de collaboration — Diiwan

## Branches

- `main` — toujours stable, c'est ce que le prof évalue. **Jamais de push direct.**
- `dev` — branche d'intégration, tout part de là et y retourne.
- Branches de travail, une par tâche, jamais par personne :
  - `backend/<sujet>` — ex. `backend/import-csv`, `backend/analyseur-nlu`
  - `web/<sujet>` — ex. `web/chart-js`, `web/carte-choroplethe`
  - `mobile/<sujet>` — ex. `mobile/ecran-chat`, `mobile/fl-chart`

Créer une branche :
```bash
git checkout dev
git pull
git checkout -b backend/import-csv
```

## Commits

Format court en français, préfixé par domaine :
```
backend: ajoute la commande d'import CSV idempotente
web: détruit l'instance Chart.js avant redessin
mobile: corrige l'affichage du bandeau données fictives
```
Un commit = un changement logique. Pas de commits "wip" ou "fix" sans contexte.

## Pull requests

1. Ouvrir la PR vers `dev` (jamais directement vers `main`).
2. Description courte : ce que ça change + comment le tester.
3. Au moins **une des deux autres personnes** relit avant de merger — même si elle ne connaît pas la stack en détail, elle vérifie que le principe de sécurité (liste blanche ORM) n'est pas contourné et que la mention "données fictives" est présente.
4. Merger `dev` dans `main` seulement à des points de synchronisation (fin de séance TP, avant démo).

## Réglages GitHub recommandés (Settings → Branches)

- Protéger `main` : interdire le push direct, exiger une pull request.
- Protéger `dev` : exiger au moins 1 review avant merge.
- Activer "Require status checks" si vous ajoutez une CI (tests automatiques).

## Avant chaque commit de code généré par IA

Voir la checklist dans `docs/Diiwan_prompts_IA_generative.md` — en particulier :
aucune clé API en dur, aucun nom de champ ORM construit depuis l'input utilisateur,
tests réellement exécutés.
