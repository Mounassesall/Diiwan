import { statisticsData } from './mockData';

// Helper to normalize strings (remove accents and lower case)
export function normalizeText(text) {
  if (!text) return '';
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/-/g, ' ');
}

const REGIONS = [
  'Dakar', 'Diourbel', 'Fatick', 'Kaffrine', 'Kaolack', 'Kédougou', 
  'Kolda', 'Louga', 'Matam', 'Saint-Louis', 'Sédhiou', 'Tambacounda', 
  'Thiès', 'Ziguinchor'
];

const INDICATORS = {
  taux_chomage_pct: {
    label: "Taux de chômage (%)",
    aliases: ['chomage', 'chomeur', 'chomeurs', 'sans emploi', 'travail'],
    unit: '%',
    format: val => `${val.toFixed(1)}%`
  },
  acces_internet_pct: {
    label: "Accès à Internet (%)",
    aliases: ['internet', 'connexion', 'web', 'connectivite', 'en ligne'],
    unit: '%',
    format: val => `${val.toFixed(1)}%`
  },
  population: {
    label: "Population (hab.)",
    aliases: ['population', 'habitants', 'habitant', 'peuple', 'personnes', 'demographie'],
    unit: ' hab.',
    format: val => new Intl.NumberFormat('fr-FR').format(val) + ' hab.'
  },
  taux_pauvrete_pct: {
    label: "Taux de pauvreté (%)",
    aliases: ['pauvrete', 'pauvre', 'pauvres', 'seuil de pauvrete'],
    unit: '%',
    format: val => `${val.toFixed(1)}%`
  },
  taux_alphabetisation_pct: {
    label: "Taux d'alphabétisation (%)",
    aliases: ['alphabetisation', 'alphabetise', 'lire', 'ecrire', 'instruction'],
    unit: '%',
    format: val => `${val.toFixed(1)}%`
  },
  taux_urbanisation_pct: {
    label: "Taux d'urbanisation (%)",
    aliases: ['urbanisation', 'urbain', 'ville', 'villes', 'citadin'],
    unit: '%',
    format: val => `${val.toFixed(1)}%`
  },
  taux_scolarisation_pct: {
    label: "Taux de scolarisation (%)",
    aliases: ['scolarisation', 'ecole', 'ecoles', 'scolarise', 'eleves', 'classe'],
    unit: '%',
    format: val => `${val.toFixed(1)}%`
  },
  centres_sante: {
    label: "Nombre de centres de santé",
    aliases: ['sante', 'hopitaux', 'hopital', 'dispensaire', 'clinique', 'centres de sante'],
    unit: '',
    format: val => `${val}`
  },
 production_cerealiere_tonnes: {
    label: "Production céréalière (tonnes)",
    aliases: ['cereales', 'cereale', 'production', 'agriculture', 'recolte', 'tonnes'],
    unit: ' tonnes',
    format: val => new Intl.NumberFormat('fr-FR').format(val) + ' tonnes'
  }
};

export function queryMockData(question) {
  const normQuery = normalizeText(question);

  // 1. Off-topic check
  const isOffTopic = !normQuery.match(/(senegal|dakar|thies|region|statistique|chomage|internet|population|pauvrete|alphabetisation|urbanisation|scolarisation|sante|cereale|agri)/i) 
    && !REGIONS.some(r => normQuery.includes(normalizeText(r)));

  if (isOffTopic) {
    return {
      answer: "Je suis Diiwan, l'agent conversationnel spécialisé dans les statistiques régionales du Sénégal (données pédagogiques 2020-2024). Je ne peux répondre qu'aux questions portant sur ces thématiques.",
      table: [],
      chart: null,
      metadata: { fictitious: true, off_topic: true }
    };
  }

  // 2. Extract regions
  const matchedRegions = [];
  REGIONS.forEach(region => {
    const normRegion = normalizeText(region);
    // Boundary check using words
    if (normQuery.includes(normRegion)) {
      matchedRegions.push(region);
    }
  });

  // 3. Extract indicator
  let matchedIndicatorKey = null;
  for (const [key, meta] of Object.entries(INDICATORS)) {
    if (meta.aliases.some(alias => normQuery.includes(alias))) {
      matchedIndicatorKey = key;
      break;
    }
  }

  // 4. Extract years
  const yearRegex = /202[0-4]/g;
  const matchedYears = [];
  let match;
  while ((match = yearRegex.exec(normQuery)) !== null) {
    matchedYears.push(parseInt(match[0]));
  }

  let startYear = 2024;
  let endYear = 2024;
  let hasYearRange = false;

  if (matchedYears.length === 1) {
    startYear = matchedYears[0];
    endYear = matchedYears[0];
  } else if (matchedYears.length >= 2) {
    startYear = Math.min(...matchedYears);
    endYear = Math.max(...matchedYears);
    hasYearRange = true;
  } else {
    // Check range expressions like "de 2020 a 2024" or "entre 2020 et 2024"
    if (normQuery.includes('evolution') || normQuery.includes('historique') || normQuery.includes('tendance')) {
      startYear = 2020;
      endYear = 2024;
      hasYearRange = true;
    }
  }

  // 5. Determine operation
  let operation = 'value';
  if (hasYearRange) {
    operation = 'trend';
  } else if (matchedRegions.length > 1) {
    operation = 'compare';
  } else if (normQuery.match(/(classement|top|plus|moins|meilleur|pire|rang)/i)) {
    operation = 'ranking';
  } else if (normQuery.match(/(total|somme|moyenne|global)/i)) {
    operation = normQuery.includes('moyenne') ? 'average' : 'sum';
  }

  // 6. Clarification checks
  if (!matchedIndicatorKey) {
    return {
      answer: "Je n'ai pas bien compris quel indicateur vous intéresse. Souhaitez-vous des informations sur la population, le chômage, la pauvreté, la scolarisation, la production céréalière, l'accès à internet, ou les centres de santé ?",
      table: [],
      chart: null,
      metadata: { fictitious: true, needs_clarification: true }
    };
  }

  const indicatorMeta = INDICATORS[matchedIndicatorKey];

  // 7. Execute operations
  if (operation === 'value') {
    // Requires exactly one region
    if (matchedRegions.length === 0) {
      return {
        answer: `Pour obtenir le ${indicatorMeta.label.toLowerCase()}, veuillez spécifier une région du Sénégal (par exemple : Dakar, Thiès, Kaolack...).`,
        table: [],
        chart: null,
        metadata: { fictitious: true, needs_clarification: true }
      };
    }

    const region = matchedRegions[0];
    const record = statisticsData.find(d => d.region === region && d.annee === startYear);

    if (!record) {
      return {
        answer: `Aucune donnée trouvée pour la région ${region} en ${startYear}.`,
        table: [],
        chart: null,
        metadata: { fictitious: true, rows_used: 0 }
      };
    }

    const val = record[matchedIndicatorKey];
    const formattedVal = indicatorMeta.format(val);
    const answer = `En ${startYear}, le/la **${indicatorMeta.label.toLowerCase()}** dans la région de **${region}** est estimé(e) à **${formattedVal}**.`;

    return {
      answer,
      table: [{ annee: startYear, valeur: val }],
      chart: null,
      metadata: { fictitious: true, rows_used: 1, region, indicator: matchedIndicatorKey, year: startYear }
    };

  } else if (operation === 'compare') {
    const year = startYear; // compare on single year
    const records = statisticsData.filter(d => matchedRegions.includes(d.region) && d.annee === year);

    if (records.length === 0) {
      return {
        answer: `Aucune donnée de comparaison trouvée pour les régions spécifiées en ${year}.`,
        table: [],
        chart: null,
        metadata: { fictitious: true, rows_used: 0 }
      };
    }

    const table = records.map(r => ({ region: r.region, valeur: r[matchedIndicatorKey] }));
    const answersList = records.map(r => `${r.region} (${indicatorMeta.format(r[matchedIndicatorKey])})`);
    const answer = `Comparaison pour le/la **${indicatorMeta.label.toLowerCase()}** en **${year}** :\n` + 
      answersList.map((item, idx) => `${idx + 1}. ${item}`).join('\n');

    const chart = {
      type: 'bar',
      labels: table.map(t => t.region),
      datasets: [{
        label: `${indicatorMeta.label} (${year})`,
        data: table.map(t => t.valeur),
        backgroundColor: 'rgba(16, 185, 129, 0.6)', // Emerald color
        borderColor: 'rgb(16, 185, 129)',
        borderWidth: 1
      }]
    };

    return {
      answer,
      table,
      chart,
      metadata: { fictitious: true, rows_used: records.length, regions: matchedRegions, indicator: matchedIndicatorKey, year }
    };

  } else if (operation === 'trend') {
    // Requires a region
    const region = matchedRegions[0] || 'Dakar'; // fallback to Dakar if none matched, or ask clarification
    if (matchedRegions.length === 0) {
      return {
        answer: `Pour analyser l'évolution du/de la ${indicatorMeta.label.toLowerCase()}, veuillez préciser la région souhaitée.`,
        table: [],
        chart: null,
        metadata: { fictitious: true, needs_clarification: true }
      };
    }

    const records = statisticsData
      .filter(d => d.region === region && d.annee >= startYear && d.annee <= endYear)
      .sort((a, b) => a.annee - b.annee);

    if (records.length === 0) {
      return {
        answer: `Aucune donnée historique trouvée pour la région ${region} entre ${startYear} et ${endYear}.`,
        table: [],
        chart: null,
        metadata: { fictitious: true, rows_used: 0 }
      };
    }

    const table = records.map(r => ({ annee: r.annee, valeur: r[matchedIndicatorKey] }));
    const firstVal = indicatorMeta.format(table[0].valeur);
    const lastVal = indicatorMeta.format(table[table.length - 1].valeur);
    const answer = `Évolution du/de la **${indicatorMeta.label.toLowerCase()}** pour la région de **${region}** entre **${startYear}** et **${endYear}** :\n` +
      `Elle est passée de **${firstVal}** en ${startYear} à **${lastVal}** en ${endYear}.`;

    const chart = {
      type: 'line',
      labels: table.map(t => t.annee),
      datasets: [{
        label: `${indicatorMeta.label} - ${region}`,
        data: table.map(t => t.valeur),
        fill: false,
        borderColor: 'rgb(16, 185, 129)',
        tension: 0.1
      }]
    };

    return {
      answer,
      table,
      chart,
      metadata: { fictitious: true, rows_used: records.length, region, indicator: matchedIndicatorKey, startYear, endYear }
    };

  } else if (operation === 'ranking') {
    const year = startYear;
    // Determine ranking limit (e.g., "les cinq regions" -> limit 5)
    let limit = 5;
    const limitMatch = normQuery.match(/(cinq|5|trois|3|dix|10)/);
    if (limitMatch) {
      const valMap = { 'cinq': 5, '5': 5, 'trois': 3, '3': 3, 'dix': 10, '10': 10 };
      limit = valMap[limitMatch[0]] || 5;
    }

    // Determine direction
    const isAscending = normQuery.includes('moins') || normQuery.includes('pire') || normQuery.includes('faible');

    const yearRecords = statisticsData.filter(d => d.annee === year);
    if (yearRecords.length === 0) {
      return {
        answer: `Aucune donnée disponible pour l'année ${year}.`,
        table: [],
        chart: null,
        metadata: { fictitious: true, rows_used: 0 }
      };
    }

    const sortedRecords = [...yearRecords].sort((a, b) => {
      return isAscending 
        ? a[matchedIndicatorKey] - b[matchedIndicatorKey] 
        : b[matchedIndicatorKey] - a[matchedIndicatorKey];
    });

    const sliced = sortedRecords.slice(0, limit);
    const table = sliced.map(r => ({ region: r.region, valeur: r[matchedIndicatorKey] }));

    const textDirection = isAscending ? "les moins" : "les plus";
    const answer = `Classement des **${limit} régions** ${textDirection} performantes pour le/la **${indicatorMeta.label.toLowerCase()}** en **${year}** :\n` +
      sliced.map((r, i) => `${i + 1}. **${r.region}** : ${indicatorMeta.format(r[matchedIndicatorKey])}`).join('\n');

    const chart = {
      type: 'bar',
      labels: table.map(t => t.region),
      datasets: [{
        label: `${indicatorMeta.label} (${year})`,
        data: table.map(t => t.valeur),
        backgroundColor: isAscending ? 'rgba(239, 68, 68, 0.6)' : 'rgba(16, 185, 129, 0.6)',
        borderColor: isAscending ? 'rgb(239, 68, 68)' : 'rgb(16, 185, 129)',
        borderWidth: 1
      }]
    };

    return {
      answer,
      table,
      chart,
      metadata: { fictitious: true, rows_used: sliced.length, indicator: matchedIndicatorKey, year, limit }
    };

  } else if (operation === 'sum' || operation === 'average') {
    const year = startYear;
    const yearRecords = statisticsData.filter(d => d.annee === year);

    if (yearRecords.length === 0) {
      return {
        answer: `Aucune donnée disponible pour calculer l'agrégation en ${year}.`,
        table: [],
        chart: null,
        metadata: { fictitious: true, rows_used: 0 }
      };
    }

    const values = yearRecords.map(r => r[matchedIndicatorKey]);
    let aggregatedValue = 0;
    let labelText = '';

    if (operation === 'sum') {
      aggregatedValue = values.reduce((sum, v) => sum + v, 0);
      labelText = 'somme totale';
    } else {
      aggregatedValue = values.reduce((sum, v) => sum + v, 0) / values.length;
      labelText = 'moyenne régionale';
    }

    const formattedAggr = indicatorMeta.format(aggregatedValue);
    const answer = `La **${labelText}** estimée du/de la **${indicatorMeta.label.toLowerCase()}** pour l'ensemble du Sénégal en **${year}** est de **${formattedAggr}** (basé sur les 14 régions).`;

    return {
      answer,
      table: [{ indicateur: indicatorMeta.label, valeur: aggregatedValue }],
      chart: null,
      metadata: { fictitious: true, rows_used: yearRecords.length, indicator: matchedIndicatorKey, year, operation }
    };
  }

  // Fallback
  return {
    answer: "Votre demande n'a pas pu être traitée par le service de statistiques.",
    table: [],
    chart: null,
    metadata: { fictitious: true, error: true }
  };
}
