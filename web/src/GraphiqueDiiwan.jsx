import React, { useEffect, useRef } from 'react';
import Chart from 'chart.js/auto';

export default function GraphiqueDiiwan({ chart }) {
  const canvasRef = useRef(null);
  const chartInstanceRef = useRef(null);

  useEffect(() => {
    // Destroy previous Chart.js instance explicitly to avoid memory leaks
    if (chartInstanceRef.current) {
      chartInstanceRef.current.destroy();
      chartInstanceRef.current = null;
    }

    if (!chart || !canvasRef.current) return;

    const ctx = canvasRef.current.getContext('2d');
    
    // Configure default chart styles
    const configuredDatasets = chart.datasets.map(ds => {
      const isLine = chart.type === 'line';
      return {
        ...ds,
        borderColor: ds.borderColor || (isLine ? '#10b981' : '#059669'),
        backgroundColor: ds.backgroundColor || (isLine ? 'rgba(16, 185, 129, 0.1)' : 'rgba(16, 185, 129, 0.6)'),
        borderWidth: ds.borderWidth || 2,
        tension: isLine ? 0.3 : 0,
        fill: isLine ? true : false,
      };
    });

    chartInstanceRef.current = new Chart(ctx, {
      type: chart.type || 'bar',
      data: {
        labels: chart.labels,
        datasets: configuredDatasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            labels: {
              color: '#cbd5e1',
              font: {
                family: 'Inter',
                size: 12,
                weight: '500'
              }
            }
          },
          tooltip: {
            backgroundColor: '#1e293b',
            titleColor: '#f8fafc',
            bodyColor: '#e2e8f0',
            borderColor: 'rgba(255, 255, 255, 0.1)',
            borderWidth: 1,
            padding: 10
          }
        },
        scales: {
          x: {
            grid: {
              color: 'rgba(255, 255, 255, 0.06)'
            },
            ticks: {
              color: '#94a3b8',
              font: {
                family: 'Inter'
              }
            }
          },
          y: {
            grid: {
              color: 'rgba(255, 255, 255, 0.06)'
            },
            ticks: {
              color: '#94a3b8',
              font: {
                family: 'Inter'
              }
            }
          }
        }
      }
    });

    return () => {
      if (chartInstanceRef.current) {
        chartInstanceRef.current.destroy();
        chartInstanceRef.current = null;
      }
    };
  }, [chart]);

  if (!chart) return null;

  return (
    <div className="w-full h-full" style={{ position: 'relative', minHeight: '300px' }}>
      <canvas ref={canvasRef} />
    </div>
  );
}
