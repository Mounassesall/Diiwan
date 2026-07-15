import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, GeoJSON } from 'react-leaflet';
import { senegalGeoJSON, statisticsData } from './mockData';

// Map of indicator keys to labels & config
const INDICATOR_CONFIG = {
  taux_chomage_pct: { label: "Chômage", isNegative: true, unit: '%' },
  acces_internet_pct: { label: "Accès Internet", isNegative: false, unit: '%' },
  population: { label: "Population", isNegative: false, unit: ' hab.' },
  taux_pauvrete_pct: { label: "Pauvreté", isNegative: true, unit: '%' },
  taux_alphabetisation_pct: { label: "Alphabétisation", isNegative: false, unit: '%' },
  taux_urbanisation_pct: { label: "Urbanisation", isNegative: false, unit: '%' },
  taux_scolarisation_pct: { label: "Scolarisation", isNegative: false, unit: '%' },
  centres_sante: { label: "Centres de santé", isNegative: false, unit: '' },
  production_cerealiere_tonnes: { label: "Prod. céréalière", isNegative: false, unit: ' t' }
};

export default function CarteDiiwan({ mockMode, indicator, year, onRegionClick }) {
  const [geoData, setGeoData] = useState(senegalGeoJSON);
  const [statsMap, setStatsMap] = useState({});
  const [minVal, setMinVal] = useState(0);
  const [maxVal, setMaxVal] = useState(1);
  const [loading, setLoading] = useState(false);

  // Fetch or compute data map
  useEffect(() => {
    if (mockMode) {
      // Offline / Mock mode: process local stats
      processLocalStats();
    } else {
      // Live Mode: fetch from Django API /api/regions/geojson/
      setLoading(true);
      fetch(`/api/regions/geojson/?indicator=${indicator}&annee=${year}`)
        .then(res => {
          if (!res.ok) throw new Error('API failed');
          return res.json();
        })
        .then(data => {
          setGeoData(data);
          // Extract value mappings from geoJSON features
          const valMap = {};
          let min = Infinity;
          let max = -Infinity;
          
          data.features.forEach(f => {
            const regName = f.properties.shapeName || f.properties.name || f.properties.region;
            // The django api is expected to attach the indicator value in properties
            const val = f.properties.value;
            if (val !== undefined && val !== null) {
              valMap[regName] = val;
              if (val < min) min = val;
              if (val > max) max = val;
            }
          });
          
          setStatsMap(valMap);
          setMinVal(min === Infinity ? 0 : min);
          setMaxVal(max === -Infinity ? 100 : max);
          setLoading(false);
        })
        .catch(err => {
          console.warn("Live API map fetch failed, falling back to local mock data:", err);
          processLocalStats();
          setLoading(false);
        });
    }
  }, [mockMode, indicator, year]);

  const processLocalStats = () => {
    // Filter statistics for the current year
    const yearStats = statisticsData.filter(d => d.annee === year);
    const valMap = {};
    let min = Infinity;
    let max = -Infinity;

    yearStats.forEach(d => {
      const val = d[indicator];
      if (val !== undefined && val !== null) {
        valMap[d.region] = val;
        if (val < min) min = val;
        if (val > max) max = val;
      }
    });

    setStatsMap(valMap);
    setMinVal(min === Infinity ? 0 : min);
    setMaxVal(max === -Infinity ? 100 : max);
    setGeoData(senegalGeoJSON);
  };

  // Get color based on HSL scaling
  const getColor = (value) => {
    if (value === undefined || value === null) return '#475569'; // Slate 600 default
    const range = maxVal - minVal || 1;
    const pct = (value - minVal) / range; // 0 to 1

    const isNegative = INDICATOR_CONFIG[indicator]?.isNegative;
    
    // Low value is 85% lightness, High value is 30% lightness
    const lightness = 80 - pct * 45;

    if (isNegative) {
      // Red scale for negative indicators (chomage, pauvrete)
      return `hsl(0, 75%, ${lightness}%)`;
    } else {
      // Emerald scale for positive indicators
      return `hsl(142, 70%, ${lightness}%)`;
    }
  };

  const styleFeature = (feature) => {
    const regName = feature.properties.shapeName || feature.properties.name || feature.properties.region;
    const value = statsMap[regName];
    return {
      fillColor: getColor(value),
      weight: 1.5,
      opacity: 1,
      color: '#0f172a', // border color matches page background
      fillOpacity: 0.8,
    };
  };

  const onEachFeature = (feature, layer) => {
    const regName = feature.properties.shapeName || feature.properties.name || feature.properties.region;
    const value = statsMap[regName];
    const unit = INDICATOR_CONFIG[indicator]?.unit || '';
    const label = INDICATOR_CONFIG[indicator]?.label || indicator;
    
    const formattedVal = value !== undefined && value !== null 
      ? (typeof value === 'number' && !Number.isInteger(value) ? value.toFixed(1) : value) + unit
      : 'N/A';

    // Tooltip popup
    layer.bindTooltip(`
      <div style="font-family: 'Inter', sans-serif; font-size: 13px; color: #1e293b; padding: 2px 4px;">
        <strong>${regName}</strong><br/>
        ${label} : <span style="font-weight: 600; color: #059669;">${formattedVal}</span>
      </div>
    `, { sticky: true, opacity: 0.9 });

    // Click behavior
    layer.on({
      click: () => {
        if (onRegionClick) {
          onRegionClick(regName);
        }
      },
      mouseover: (e) => {
        const l = e.target;
        l.setStyle({
          fillOpacity: 0.95,
          weight: 2.5,
          color: '#ffffff'
        });
      },
      mouseout: (e) => {
        const l = e.target;
        l.setStyle({
          fillOpacity: 0.8,
          weight: 1.5,
          color: '#0f172a'
        });
      }
    });
  };

  // Center of Senegal
  const position = [14.45, -14.45];
  const config = INDICATOR_CONFIG[indicator];

  // Helper to format values for the legend
  const formatLegendVal = (val) => {
    if (typeof val !== 'number') return 'N/A';
    if (indicator === 'population') {
      return new Intl.NumberFormat('fr-FR', { notation: 'compact' }).format(val);
    }
    return val % 1 === 0 ? val : val.toFixed(1);
  };

  return (
    <div className="w-full h-full flex flex-col relative" style={{ minHeight: '380px' }}>
      {loading && (
        <div style={{
          position: 'absolute', top: 10, right: 10, zIndex: 1000,
          background: 'rgba(15, 23, 42, 0.8)', border: '1px solid rgba(255,255,255,0.1)',
          padding: '6px 12px', borderRadius: '4px', fontSize: '12px'
        }}>
          Chargement de la carte...
        </div>
      )}
      
      <div style={{ flex: 1, height: '100%' }}>
        <MapContainer 
          center={position} 
          zoom={7.2} 
          style={{ height: '100%', width: '100%' }}
          zoomControl={true}
          scrollWheelZoom={false}
          doubleClickZoom={false}
        >
          <TileLayer
            attribution='&copy; OpenStreetMap'
            url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          />
          <GeoJSON
            key={`${indicator}-${year}-${JSON.stringify(statsMap)}`}
            data={geoData}
            style={styleFeature}
            onEachFeature={onEachFeature}
          />
        </MapContainer>
      </div>

      {/* Choropleth Legend */}
      <div style={{
        position: 'absolute', bottom: 16, right: 16, zIndex: 1000,
        background: 'rgba(15, 23, 42, 0.85)', backdropFilter: 'blur(8px)',
        border: '1px solid rgba(255, 255, 255, 0.08)',
        padding: '12px', borderRadius: '8px', width: '180px',
        fontFamily: 'Inter, sans-serif'
      }}>
        <div style={{ fontSize: '11px', fontWeight: '600', color: '#94a3b8', marginBottom: '6px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
          Légende ({year})
        </div>
        <div style={{ fontSize: '12px', fontWeight: '500', color: '#f1f5f9', marginBottom: '8px' }}>
          {config?.label}
        </div>
        
        {/* Visual Color Scale Gradient Bar */}
        <div style={{
          height: '10px',
          borderRadius: '5px',
          background: config?.isNegative
            ? `linear-gradient(to right, hsl(0, 75%, 80%), hsl(0, 75%, 30%))`
            : `linear-gradient(to right, hsl(142, 70%, 80%), hsl(142, 70%, 30%))`,
          marginBottom: '6px'
        }} />
        
        <div style={{ display: 'flex', justifyContent: 'between', fontSize: '11px', color: '#94a3b8' }}>
          <span style={{ flex: 1, textAlign: 'left' }}>Min: {formatLegendVal(minVal)}{config?.unit}</span>
          <span style={{ flex: 1, textAlign: 'right' }}>Max: {formatLegendVal(maxVal)}{config?.unit}</span>
        </div>
        
        <div style={{ fontSize: '9px', color: '#64748b', marginTop: '8px', textAlign: 'center', fontStyle: 'italic' }}>
          * Cliquez sur une région pour poser une question.
        </div>
      </div>
    </div>
  );
}
