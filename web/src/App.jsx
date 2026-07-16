import React, { useState, useEffect } from 'react';
import ChatDiiwan from './ChatDiiwan';
import CarteDiiwan from './CarteDiiwan';
import GraphiqueDiiwan from './GraphiqueDiiwan';
import { Map, BarChart2, Table, Info, AlertCircle, Moon, Sun, HelpCircle } from 'lucide-react';

const INDICATORS = [
  { key: 'population', label: 'Population' },
  { key: 'taux_chomage_pct', label: 'Taux de chômage' },
  { key: 'acces_internet_pct', label: 'Accès Internet' },
  { key: 'taux_pauvrete_pct', label: 'Taux de pauvreté' },
  { key: 'taux_alphabetisation_pct', label: "Taux d'alphabétisation" },
  { key: 'taux_urbanisation_pct', label: "Taux d'urbanisation" },
  { key: 'taux_scolarisation_pct', label: 'Taux de scolarisation' },
  { key: 'centres_sante', label: 'Centres de santé' },
  { key: 'production_cerealiere_tonnes', label: 'Production céréalière' }
];

const YEARS = [2020, 2021, 2022, 2023, 2024];

const INDICATOR_MAP_TEXT = {
  population: "la population",
  taux_chomage_pct: "le taux de chômage",
  acces_internet_pct: "l'accès à Internet",
  taux_pauvrete_pct: "le taux de pauvreté",
  taux_alphabetisation_pct: "le taux d'alphabétisation",
  taux_urbanisation_pct: "le taux d'urbanisation",
  taux_scolarisation_pct: "le taux de scolarisation",
  centres_sante: "le nombre de centres de santé",
  production_cerealiere_tonnes: "la production céréalière"
};

export default function App() {
  const [mockMode, setMockMode] = useState(false);
  const [inputQuestion, setInputQuestion] = useState('');
  const [theme, setTheme] = useState('dark');
  const [showHelp, setShowHelp] = useState(false);
  
  // Map Sync states
  const [selectedIndicator, setSelectedIndicator] = useState('population');
  const [selectedYear, setSelectedYear] = useState(2024);
  
  // Visualization outputs from chat
  const [activeChart, setActiveChart] = useState(null);
  const [activeTable, setActiveTable] = useState(null);
  const [activeTab, setActiveTab] = useState('carte'); // 'carte' or 'vis'

  // Apply theme to document
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const handleNewResult = (result) => {
    // Sync indicator & year if found in query response metadata
    if (result.metadata) {
      if (result.metadata.indicator) {
        setSelectedIndicator(result.metadata.indicator);
      }
      if (result.metadata.year) {
        setSelectedYear(result.metadata.year);
      } else if (result.metadata.startYear) {
        setSelectedYear(result.metadata.startYear);
      }
    }

    // Capture chart & table
    if (result.chart) {
      setActiveChart(result.chart);
      setActiveTable(result.table || null);
      // Auto-switch to visual tab to show off the generated chart
      setActiveTab('vis');
    } else {
      setActiveChart(null);
      setActiveTable(result.table && result.table.length > 0 ? result.table : null);
      if (result.table && result.table.length > 0) {
        setActiveTab('vis');
      }
    }
  };

  const handleRegionClick = (regionName) => {
    const textInd = INDICATOR_MAP_TEXT[selectedIndicator] || "la population";
    // Set question without auto-submitting
    setInputQuestion(`Quelle est ${textInd} de ${regionName} en ${selectedYear} ?`);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', overflow: 'hidden' }}>
      
      {/* Premium Header */}
      <header className="glass-panel" style={{ padding: '0 20px', height: '60px' }}>
        <div className="logo-container">
          <span className="logo-text">Diiwan</span>
          <span className="hide-on-mobile" style={{ fontSize: '12px', color: '#94a3b8', background: 'rgba(255,255,255,0.05)', padding: '2px 8px', borderRadius: '4px', border: '1px solid rgba(255,255,255,0.05)' }}>
            Sénégal Stats AI
          </span>
        </div>



        {/* Control toggles */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#94a3b8' }}>
            <span className="hide-on-mobile">Mode Démo (Offline)</span>
            <label className="switch" title="Mode Démo (Offline)">
              <input 
                type="checkbox" 
                checked={mockMode} 
                onChange={(e) => setMockMode(e.target.checked)} 
              />
              <span className="slider"></span>
            </label>
          </div>

          {/* Theme toggle */}
          <button
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            title="Thème Clair/Sombre"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              background: 'rgba(255, 255, 255, 0.05)',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              borderRadius: '8px',
              color: '#94a3b8',
              fontSize: '13px',
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
            onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)'}
            onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.05)'}
          >
            {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
            <span className="hide-on-mobile">{theme === 'dark' ? 'Clair' : 'Sombre'}</span>
          </button>

          {/* Help button */}
          <button
            id="btn-aide"
            onClick={() => setShowHelp(true)}
            title="Aide"
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: '34px',
              height: '34px',
              background: 'rgba(16, 185, 129, 0.1)',
              border: '1px solid rgba(16, 185, 129, 0.3)',
              borderRadius: '50%',
              color: '#10b981',
              fontSize: '16px',
              cursor: 'pointer',
              transition: 'all 0.2s',
              flexShrink: 0,
            }}
            onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(16, 185, 129, 0.25)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = 'rgba(16, 185, 129, 0.1)'; }}
          >
            <HelpCircle size={17} />
          </button>
        </div>
      </header>

      {/* Help Modal */}
      {showHelp && (
        <div
          id="modale-aide"
          onClick={(e) => e.target === e.currentTarget && setShowHelp(false)}
          style={{
            position: 'fixed', inset: 0, zIndex: 9999,
            background: 'rgba(0,0,0,0.65)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}
        >
          <div style={{
            background: theme === 'dark' ? '#1e293b' : '#f8fafc',
            border: `1px solid ${theme === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.1)'}`,
            borderRadius: '20px',
            padding: '32px',
            maxWidth: '480px',
            width: '90%',
            maxHeight: '80vh',
            overflowY: 'auto',
            boxShadow: '0 24px 60px rgba(0,0,0,0.5)',
          }}>
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
              <HelpCircle size={24} color="#10b981" />
              <h2 style={{ margin: 0, fontSize: '18px', color: theme === 'dark' ? '#fff' : '#0f172a' }}>
                Comment utiliser Diiwan ?
              </h2>
            </div>
            <p style={{ margin: '0 0 20px', fontSize: '13px', color: '#94a3b8', lineHeight: 1.6 }}>
              Posez vos questions en <strong style={{color:'#10b981'}}>français naturel</strong> sur les régions du Sénégal entre 2020 et 2024.
            </p>

            {/* Indicators */}
            <h3 style={{ margin: '0 0 10px', fontSize: '14px', color: '#10b981' }}>📊 Indicateurs disponibles</h3>
            <ul style={{ margin: '0 0 20px', paddingLeft: '18px', color: theme === 'dark' ? '#cbd5e1' : '#334155', fontSize: '13px', lineHeight: 2 }}>
              {[
                'Population', 'Taux de chômage (%)', 'Taux de pauvreté (%)',
                "Taux d'alphabétisation (%)", "Taux d'urbanisation (%)",
                'Taux de scolarisation (%)', "Accès à Internet (%)",
                'Centres de santé (nb)', 'Production céréalière (tonnes)'
              ].map(ind => <li key={ind}>{ind}</li>)}
            </ul>

            {/* Examples */}
            <h3 style={{ margin: '0 0 10px', fontSize: '14px', color: '#10b981' }}>💡 Exemples de questions</h3>
            <ul style={{ margin: '0 0 28px', paddingLeft: '18px', color: theme === 'dark' ? '#94a3b8' : '#64748b', fontSize: '12px', lineHeight: 2.2, fontStyle: 'italic' }}>
              {[
                "Quelle est la population de Dakar en 2024 ?",
                "Compare le chômage à Thiès et Saint-Louis.",
                `"Montre l'évolution de l'accès internet à Matam de 2020 à 2024."`,
                "Quelles sont les 5 régions les plus peuplées ?",
                "Population totale du Sénégal en 2024 ?",
              ].map(q => <li key={q}>{q}</li>)}
            </ul>

            <button
              id="btn-aide-fermer"
              onClick={() => setShowHelp(false)}
              style={{
                width: '100%', padding: '12px',
                background: '#10b981', color: '#fff',
                border: 'none', borderRadius: '10px',
                fontSize: '15px', fontWeight: 600,
                cursor: 'pointer', transition: 'background 0.2s',
              }}
              onMouseEnter={(e) => e.currentTarget.style.background = '#059669'}
              onMouseLeave={(e) => e.currentTarget.style.background = '#10b981'}
            >
              Compris !
            </button>
          </div>
        </div>
      )}


      {/* Main Workspace */}
      <main className="app-grid">
        
        {/* Left Side: Conversational Agent Panel */}
        <div style={{ borderRight: '1px solid var(--border-color)', height: '100%', overflow: 'hidden' }}>
          <ChatDiiwan 
            mockMode={mockMode}
            inputQuestion={inputQuestion}
            setInputQuestion={setInputQuestion}
            onNewResult={handleNewResult}
          />
        </div>

        {/* Right Side: Interactive Visualization Panel */}
        <div className="dashboard-panel" style={{ boxSizing: 'border-box', display: 'flex', flexDirection: 'column', height: '100%', overflow: 'hidden', padding: '16px', gap: '16px', background: 'rgba(15, 23, 42, 0.2)' }}>
          
          {/* Tabs header & Selector controls */}
          <div style={{ boxSizing: 'border-box', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px', flexShrink: 0, width: '100%' }}>
            
            {/* Visual Tabs toggle buttons */}
            <div style={{ boxSizing: 'border-box', display: 'inline-flex', alignItems: 'center', background: 'var(--bg-secondary)', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '4px', gap: '4px' }}>
              <button 
                onClick={() => setActiveTab('carte')}
                style={{
                  boxSizing: 'border-box',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', padding: '0 16px', minHeight: '32px', border: 'none', borderRadius: '6px', fontSize: '13px', fontWeight: '500', cursor: 'pointer',
                  background: activeTab === 'carte' ? 'rgba(16, 185, 129, 0.15)' : 'transparent',
                  color: activeTab === 'carte' ? '#10b981' : 'var(--text-secondary)',
                  transition: '0.2s'
                }}
              >
                <Map size={15} />
                Carte Régionale
              </button>
              <button 
                onClick={() => setActiveTab('vis')}
                style={{
                  boxSizing: 'border-box',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', padding: '0 16px', minHeight: '32px', border: 'none', borderRadius: '6px', fontSize: '13px', fontWeight: '500', cursor: 'pointer',
                  background: activeTab === 'vis' ? 'rgba(16, 185, 129, 0.15)' : 'transparent',
                  color: activeTab === 'vis' ? '#10b981' : 'var(--text-secondary)',
                  transition: '0.2s'
                }}
              >
                <BarChart2 size={15} />
                Graphiques & Données { (activeChart || activeTable) && <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#ef4444', display: 'inline-block' }} /> }
              </button>
            </div>

            {/* Manual controls for Map visualization */}
            {activeTab === 'carte' && (
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                <select 
                  value={selectedIndicator} 
                  onChange={(e) => setSelectedIndicator(e.target.value)}
                  style={{
                    background: 'var(--bg-secondary)', border: '1px solid var(--border-color)', color: 'var(--text-primary)', borderRadius: '8px', padding: '8px 14px', fontSize: '13px', outline: 'none', cursor: 'pointer', transition: 'border-color 0.2s'
                  }}
                >
                  {INDICATORS.map(ind => (
                    <option key={ind.key} value={ind.key}>{ind.label}</option>
                  ))}
                </select>

                <select 
                  value={selectedYear} 
                  onChange={(e) => setSelectedYear(parseInt(e.target.value))}
                  style={{
                    background: 'var(--bg-secondary)', border: '1px solid var(--border-color)', color: 'var(--text-primary)', borderRadius: '8px', padding: '8px 14px', fontSize: '13px', outline: 'none', cursor: 'pointer', transition: 'border-color 0.2s'
                  }}
                >
                  {YEARS.map(yr => (
                    <option key={yr} value={yr}>{yr}</option>
                  ))}
                </select>
              </div>
            )}
          </div>

          {/* Active Tab contents */}
          <div className="glass-card" style={{ flex: 1, overflow: 'hidden', padding: '0', display: 'flex', flexDirection: 'column' }}>
            {activeTab === 'carte' ? (
              <CarteDiiwan 
                mockMode={mockMode}
                indicator={selectedIndicator}
                year={selectedYear}
                onRegionClick={handleRegionClick}
              />
            ) : (
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '16px', padding: '20px', overflowY: 'auto' }}>
                
                {/* Chart segment */}
                {activeChart ? (
                  <div style={{ flex: 1, minHeight: '300px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    <div style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <BarChart2 size={16} style={{ color: '#10b981' }} />
                      Visualisation Graphique
                    </div>
                    <div style={{ flex: 1, background: 'var(--glass-card-bg)', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '16px' }}>
                      <GraphiqueDiiwan chart={activeChart} />
                    </div>
                  </div>
                ) : (
                  <div style={{ flex: 1, minHeight: '180px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', border: '1px dashed var(--border-color)', borderRadius: '8px', color: 'var(--text-secondary)', gap: '10px' }}>
                    <BarChart2 size={32} />
                    <span style={{ fontSize: '13px' }}>Aucun graphique généré pour la dernière réponse.</span>
                  </div>
                )}

                {/* Table segment */}
                {activeTable ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    <div style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Table size={16} style={{ color: '#10b981' }} />
                      Tableau de données
                    </div>
                    <div style={{ overflowX: 'auto', border: '1px solid var(--border-color)', borderRadius: '8px' }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px', textAlign: 'left' }}>
                        <thead>
                          <tr style={{ background: 'rgba(255,255,255,0.02)', borderBottom: '1px solid var(--border-color)' }}>
                            {Object.keys(activeTable[0]).map((h, idx) => (
                              <th key={idx} style={{ padding: '10px 14px', color: 'var(--text-secondary)', textTransform: 'capitalize', fontWeight: '600' }}>
                                {h === 'annee' ? 'Année' : h === 'valeur' ? 'Valeur' : h}
                              </th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {activeTable.map((row, rIdx) => (
                            <tr key={rIdx} style={{ borderBottom: rIdx < activeTable.length - 1 ? '1px solid var(--border-color)' : 'none' }}>
                              {Object.values(row).map((c, cIdx) => (
                                <td key={cIdx} style={{ padding: '10px 14px', color: 'var(--text-primary)' }}>
                                  {typeof c === 'number' && !Number.isInteger(c)
                                    ? c.toFixed(1)
                                    : typeof c === 'number'
                                      ? new Intl.NumberFormat('fr-FR').format(c)
                                      : c
                                  }
                                </td>
                              ))}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                ) : null}

              </div>
            )}
          </div>
        </div>

      </main>
    </div>
  );
}
