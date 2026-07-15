# Diiwan — Bibliothèque de prompts pour Antigravity / Cursor

Agent IA de statistiques régionales du Sénégal — Maïmouna Sall (backend), Ngoné Gueye (web), Rokhy Marone (mobile)

---

## Comment utiliser ce document

- Chaque prompt est **autonome mais séquentiel** : ne sautez pas d'étape, l'agent IA code mieux quand il a le contexte des fichiers déjà générés.
- Collez d'abord le **bloc "Contexte partagé"** ci-dessous en début de session (nouveau chat Cursor/Antigravity), avant le premier prompt de votre section.
- Après **chaque** génération : relisez le code, ne collez jamais un prompt sur du code que vous n'avez pas vérifié. Le prof va vous interroger sur ce que vous avez produit — si vous ne pouvez pas l'expliquer, c'est un risque en soutenance.
- Quand un prompt touche à la sécurité (validation, liste blanche, CSRF), vérifiez vous-même la sortie — c'est le critère le plus scruté du sujet.
- Un prompt trop vague donne du code générique. Ceux ci-dessous sont volontairement précis (noms de champs exacts, formats JSON exacts) — gardez cette précision quand vous les adaptez.

---

## Contexte partagé (à coller en premier, dans chaque session)

```
Projet : Diiwan, agent conversationnel de statistiques régionales du Sénégal.
14 régions × années 2020-2024, données pédagogiques FICTIVES (à afficher clairement dans l'UI).

Modèle de données (StatistiqueRegionale) :
- region : CharField(max_length=40)
- annee : PositiveSmallIntegerField
- population : PositiveBigIntegerField
- taux_urbanisation_pct : DecimalField
- taux_alphabetisation_pct : DecimalField
- taux_chomage_pct : DecimalField
- taux_pauvrete_pct : DecimalField
- acces_internet_pct : DecimalField
- centres_sante : PositiveIntegerField
- taux_scolarisation_pct : DecimalField
- production_cerealiere_tonnes : PositiveIntegerField
Contrainte d'unicité sur (region, annee).

Principe de sécurité NON NÉGOCIABLE : aucun texte venant de l'utilisateur ne doit
atteindre values(), order_by() ou aggregate() sans passer par une liste blanche
de champs autorisés définie côté développeur. Aucun SQL généré par un LLM n'est
jamais exécuté directement.

Contrat JSON de l'API (POST /api/question/) :
{
  "answer": "texte en français",
  "table": [{"annee": 2020, "valeur": 41.0}],
  "chart": {"type": "line", "labels": [...], "datasets": [{"label": "...", "data": [...]}]} | null,
  "metadata": {"fictitious": true, "rows_used": 5}
}

Opérations supportées : value, compare, trend, ranking, sum, average.
Régions (14) : Dakar, Diourbel, Fatick, Kaffrine, Kaolack, Kédougou, Kolda, Louga,
Matam, Saint-Louis, Sédhiou, Tambacounda, Thiès, Ziguinchor.
```

---

## Section 1 — Backend Django/DRF (Maïmouna)

### Prompt 1.1 — Initialisation et modèle
```
Crée un projet Django avec une app "statistiques". Génère le modèle StatistiqueRegionale
avec exactement les champs listés dans le contexte partagé ci-dessus, plus une contrainte
d'unicité Meta.constraints sur (region, annee). Enregistre le modèle dans l'admin Django
avec list_display sur region, annee, population. Ajoute un champ global affiché dans
l'admin (via une méthode ou un modèle Site) indiquant "Données pédagogiques fictives".
Fournis aussi le requirements.txt (Django, djangorestframework, psycopg2-binary,
django-cors-headers) et les settings minimaux pour connecter PostgreSQL avec PostGIS
activé (django.contrib.gis.db.backends.postgis).
```

### Prompt 1.2 — Import CSV idempotent
```
Crée une commande de gestion Django "importer_statistiques" (management command) qui
prend un chemin CSV en argument. Le CSV a les colonnes : region, annee, population,
taux_urbanisation_pct, taux_alphabetisation_pct, taux_chomage_pct, taux_pauvrete_pct,
acces_internet_pct, centres_sante, taux_scolarisation_pct, production_cerealiere_tonnes.

Exigences :
- Vérifie que les colonnes obligatoires sont présentes, sinon erreur claire.
- Vérifie que annee est entre 2020 et 2024.
- Vérifie que tous les champs *_pct sont entre 0 et 100.
- Utilise update_or_create sur (region, annee) pour éviter les doublons à une
  seconde exécution.
- Affiche à la fin : nombre de lignes créées, mises à jour, rejetées (avec la raison
  du rejet pour chacune).
- Écris 3 tests qui vérifient : import initial (70 lignes créées), ré-import sans
  doublon, rejet d'une ligne avec pourcentage invalide.
```

### Prompt 1.3 — Analyseur de question → QueryIntent
```
Crée un module "analyseur.py" qui transforme une question en français en un objet
QueryIntent structuré (utilise une dataclass ou un serializer DRF), avec les champs :
indicator, regions (liste), start_year, end_year, operation, limit, chart_type,
needs_clarification (bool), clarification_message (str|None).

Règles :
- Dictionnaire d'alias mots usuels → champs du modèle. Exemples : "chômage"/"chomage"
  → taux_chomage_pct, "internet" → acces_internet_pct, "population"/"habitants"
  → population, "pauvreté" → taux_pauvrete_pct, "alphabétisation" → taux_alphabetisation_pct,
  "urbanisation" → taux_urbanisation_pct, "scolarisation" → taux_scolarisation_pct,
  "santé"/"centres de santé" → centres_sante, "céréales"/"production" →
  production_cerealiere_tonnes.
- Détecte les 14 noms de région insensible à la casse et aux accents (normalise
  avec unicodedata avant comparaison).
- Extrait les années avec une regex (formats "en 2024", "entre 2020 et 2024",
  "de 2020 à 2024").
- Détermine l'opération : "value" par défaut, "compare" si plusieurs régions +
  même année, "trend" si une région + plage d'années, "ranking" si mots comme
  "plus", "top", "classement", "sum"/"average" si "total"/"somme"/"moyenne".
- Si l'indicateur OU l'opération n'est pas déterminable, retourne
  needs_clarification=True avec un message demandant précisément ce qui manque.
- Si aucune région n'est mentionnée pour une opération qui en a besoin (compare,
  value), demande clarification plutôt que de deviner.

Écris des tests pour : une question simple, une comparaison, une évolution,
un classement, une agrégation, une question ambiguë (doit demander clarification),
une région inconnue, une question hors sujet (doit être détectée comme hors périmètre,
pas comme ambiguë).
```

### Prompt 1.4 — Validateur à liste blanche + moteur ORM
```
Crée un module "validateur.py" qui prend un QueryIntent et vérifie que :
- indicator est dans FIELDS_WHITELIST (liste explicite des 9 champs numériques
  du modèle, définie en constante Python, jamais dérivée du texte utilisateur)
- regions sont dans REGIONS_WHITELIST (liste des 14 régions)
- start_year/end_year sont dans [2020, 2024]
- operation est dans OPERATIONS_WHITELIST (value, compare, trend, ranking, sum, average)
Si une vérification échoue, retourne une erreur explicite, ne lève jamais d'exception
non gérée.

Puis crée "moteur.py" avec une fonction executer_intention(intent) qui, SEULEMENT
après validation, exécute la requête ORM correspondante sur StatistiqueRegionale :
- value : filter + values + first
- compare : filter(region__in=...) + order_by
- trend : filter + order_by("annee")
- ranking : filter + order_by(f"-{indicator}")[:limit]
- sum/average : aggregate(Sum(...)) ou aggregate(Avg(...))
Important : le nom de champ passé à values()/order_by()/aggregate() doit toujours
venir de FIELDS_WHITELIST (utilise getattr ou un dict de mapping, jamais une f-string
construite depuis intent.indicator brut).

Écris des tests pour chaque opération, plus un test qui prouve qu'une valeur
d'indicator hors liste blanche est rejetée avant d'atteindre l'ORM.
```

### Prompt 1.5 — API DRF
```
Crée une vue DRF (APIView ou @api_view) pour POST /api/question/ qui :
1. Reçoit {"question": "..."} en JSON
2. Appelle l'analyseur, puis le validateur, puis le moteur
3. Si needs_clarification, retourne {"answer": message, "table": [], "chart": null,
   "metadata": {"needs_clarification": true}}
4. Si hors périmètre détecté, retourne poliment un refus dans "answer" sans erreur HTTP
5. Sinon formate la réponse exactement selon le contrat JSON du contexte partagé
   (answer en français avec les vraies valeurs, table, chart avec le bon chart_type,
   metadata avec fictitious=true et rows_used)
6. Gère les erreurs (requête malformée) avec un code 400 et un message clair
Rejette toute méthode autre que POST (405).
Écris 4 tests d'intégration : question simple, comparaison avec graphique bar,
question hors sujet, question ambiguë.
```

### Prompt 1.6 — Bonus IA générative (Gemini)
```
Ajoute une couche optionnelle : avant l'analyseur déterministe, tente d'appeler
l'API Gemini (google-generativeai) en mode JSON structuré (response_schema) pour
extraire un QueryIntent brut depuis la question. Contraintes strictes :
- Clé API lue depuis une variable d'environnement GEMINI_API_KEY, jamais en dur.
- Température basse (0.1 max).
- Timeout de 5 secondes et limite de taille sur la requête envoyée.
- N'envoie au modèle QUE la question et la liste des indicateurs/régions valides
  (jamais les données statistiques elles-mêmes).
- Le JSON retourné par Gemini passe OBLIGATOIREMENT par le même validateur.py
  que le mode déterministe — aucun raccourci.
- Si l'appel échoue, timeout, ou renvoie un JSON invalide : repli automatique et
  silencieux vers l'analyseur déterministe (jamais d'erreur visible pour l'utilisateur).
- Log l'intention validée dans un logger Django, jamais la clé API ni la question brute.
Ajoute un flag settings.py USE_GENERATIVE_AI (bool) pour activer/désactiver cette
couche facilement en démo.
```

### Prompt 1.7 — Extension géospatiale (PostGIS)
```
Crée un modèle RegionGeometrie (region OneToOne vers StatistiqueRegionale ou
CharField unique, geom = MultiPolygonField(srid=4326)). Crée une commande de
gestion "importer_geometries" qui charge un GeoJSON des 14 régions du Sénégal
(je te fournirai le fichier) et remplit ce modèle. Crée un endpoint GET
/api/regions/geojson/ qui retourne un FeatureCollection GeoJSON où chaque feature
a les propriétés region + la valeur du dernier indicateur demandé (paramètre
?indicator=taux_chomage_pct&annee=2024, validé contre la même liste blanche).
```

---

## Section 2 — Frontend Web React (Ngoné)

### Prompt 2.1 — Interface de dialogue
```
Crée une app React (Vite) avec un composant ChatDiiwan : zone de saisie, bouton
Envoyer, historique de conversation (question utilisateur + réponse agent), un
indicateur de chargement pendant l'appel API, et un message d'erreur lisible en
cas d'échec réseau. Chaque réponse de l'agent affiche :
- le texte de answer
- un tableau HTML si table n'est pas vide
- une bannière "Données pédagogiques fictives" si metadata.fictitious est true
Envoie POST vers /api/question/ avec {"question": texte}, protège la requête avec
le jeton CSRF Django (lis-le depuis le cookie csrftoken). Utilise fetch, pas axios.
```

### Prompt 2.2 — Graphique Chart.js
```
Ajoute un composant GraphiqueDiiwan qui reçoit l'objet "chart" de la réponse API
(type, labels, datasets) et affiche un graphique Chart.js (bar ou line selon
chart.type). Détruis explicitement l'instance Chart.js précédente avant d'en créer
une nouvelle à chaque nouvelle réponse (évite le memory leak / superposition de
graphiques). N'affiche rien si chart est null.
```

### Prompt 2.3 — Carte choroplèthe
```
Ajoute une carte avec react-leaflet qui consomme GET /api/regions/geojson/
(paramétrée par le dernier indicateur/année demandés dans le chat) et colore
chaque région selon la valeur de l'indicateur (échelle de couleurs continue,
légende affichée). Au clic sur une région, pré-remplit la zone de saisie du chat
avec "Quelle est la {indicateur} de {région} en {année} ?" au lieu d'envoyer
automatiquement.
```

---

## Section 3 — Mobile Flutter (Rokhy)

### Prompt 3.1 — Écran de dialogue
```
Crée un écran Flutter DiiwanChatScreen avec un TextField de saisie, un bouton
Envoyer, une ListView d'historique de conversation (bulles question/réponse style
messagerie), un indicateur de chargement (CircularProgressIndicator) pendant
l'appel réseau, et une gestion d'erreur affichée dans un SnackBar. Utilise le
package http pour POST vers {baseUrl}/api/question/ avec le corps
{"question": texte}. Affiche un bandeau "Données pédagogiques fictives" quand
metadata.fictitious est true. Modélise la réponse avec des classes Dart
typées (DiiwanResponse, ChartData, TableRow) plutôt que du Map<String, dynamic>
brut dans les widgets.
```

### Prompt 3.2 — Graphiques fl_chart
```
Ajoute un widget DiiwanChart qui reçoit un ChartData (type "bar" ou "line",
labels, datasets) et affiche un BarChart ou LineChart de fl_chart en conséquence.
Le widget doit se reconstruire proprement à chaque nouvelle réponse (pas de state
résiduel de l'ancien graphique). N'affiche rien si chart est null.
```

### Prompt 3.3 — Carte choroplèthe mobile
```
Ajoute un écran de carte avec flutter_map qui charge les polygones GeoJSON depuis
{baseUrl}/api/regions/geojson/ et colore chaque région du Sénégal selon la valeur
d'un indicateur sélectionné dans un menu déroulant en haut de l'écran. Au tap sur
une région, navigue vers l'écran de chat avec une question pré-remplie
correspondante.
```

---

## Section 4 — Commun aux trois (tests, démo, doc)

### Prompt 4.1 — README
```
Génère un README.md pour Diiwan avec : description du projet en 3 phrases,
avertissement sur les données fictives, instructions d'installation backend
(venv, requirements, migrate, import CSV, runserver), instructions frontend
web (npm install, npm run dev), instructions mobile (flutter pub get, flutter run),
5 exemples de questions à tester (au moins 2 qui produisent un graphique), et une
section "Limites et améliorations possibles" (mentionne : jeu de données fictif,
NLU déterministe limité aux alias définis, dépendance optionnelle à une API
externe pour le bonus).
```

### Prompt 4.2 — Cinq questions de démonstration
```
Confirme que ces 5 questions couvrent bien tous les cas du barème et fonctionnent
de bout en bout, ajoute-les en fixtures de test si absentes :
1. "Quelle est la population de Thiès en 2024 ?" (value)
2. "Compare le chômage à Dakar, Thiès et Saint-Louis en 2024." (compare, bar)
3. "Montre l'évolution de l'accès à Internet à Kaolack entre 2020 et 2024." (trend, line)
4. "Quelles sont les cinq régions les plus peuplées en 2024 ?" (ranking, bar)
5. "Quelle est la population totale estimée du Sénégal en 2024 ?" (sum)
```

---

## Checklist avant de committer du code généré par IA

- [ ] Je peux expliquer, sans relire le code, ce que fait chaque fonction générée dans cette session
- [ ] Aucune f-string ou concaténation ne construit un nom de champ ORM depuis l'input utilisateur
- [ ] Les tests passent réellement (`python manage.py test`), pas seulement générés
- [ ] Aucune clé API n'apparaît dans le code (grep "AIza\|sk-\|API_KEY" avant commit)
- [ ] Le repli déterministe fonctionne même si `USE_GENERATIVE_AI = False`
- [ ] La mention "données pédagogiques fictives" est visible dans chaque interface (web + mobile)
