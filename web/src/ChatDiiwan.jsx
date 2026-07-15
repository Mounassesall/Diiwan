import React, { useState, useEffect, useRef } from 'react';
import { Send, AlertTriangle, HelpCircle, Loader2 } from 'lucide-react';
import { queryMockData } from './mockService';

// Helper to get CSRF token from Django cookie
function getCookie(name) {
  let cookieValue = null;
  if (document.cookie && document.cookie !== '') {
    const cookies = document.cookie.split(';');
    for (let i = 0; i < cookies.length; i++) {
      const cookie = cookies[i].trim();
      if (cookie.substring(0, name.length + 1) === (name + '=')) {
        cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
        break;
      }
    }
  }
  return cookieValue;
}

// Simple text formatter to handle **bold** and newlines
function formatMessageText(text) {
  if (!text) return '';
  
  // Replace **bold** with <strong>bold</strong>
  let formatted = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  
  // Replace newlines with <br/>
  return formatted.split('\n').map((line, idx) => (
    <span key={idx}>
      {line}
      {idx < formatted.split('\n').length - 1 && <br />}
    </span>
  ));
}

export default function ChatDiiwan({ mockMode, inputQuestion, setInputQuestion, onNewResult }) {
  const [messages, setMessages] = useState([
    {
      sender: 'agent',
      text: "Bonjour ! Je suis Diiwan, votre assistant statistique pour les régions du Sénégal. Posez-moi une question sur le chômage, la population, l'accès internet, ou d'autres indicateurs entre 2020 et 2024.",
      response: null
    }
  ]);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  
  const chatEndRef = useRef(null);

  // Auto-scroll chat to bottom
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  const handleSubmit = async (e) => {
    if (e) e.preventDefault();
    if (!inputQuestion.trim() || loading) return;

    const userText = inputQuestion.trim();
    setInputQuestion(''); // Clear input
    setErrorMsg('');

    // Add user message to history
    setMessages(prev => [...prev, { sender: 'user', text: userText }]);
    setLoading(true);

    if (mockMode) {
      // Offline / Mock mode execution
      setTimeout(() => {
        try {
          const result = queryMockData(userText);
          setMessages(prev => [...prev, {
            sender: 'agent',
            text: result.answer,
            response: result
          }]);
          
          if (onNewResult) {
            onNewResult(result);
          }
        } catch (err) {
          setErrorMsg("Erreur lors de l'analyse locale de la question.");
        } finally {
          setLoading(false);
        }
      }, 600); // Small delay to simulate API latency
    } else {
      // Live Mode call
      const csrfToken = getCookie('csrftoken');
      const headers = {
        'Content-Type': 'application/json',
      };
      if (csrfToken) {
        headers['X-CSRFToken'] = csrfToken;
      }

      try {
        const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || ''}/api/question/`, {
          method: 'POST',
          headers,
          body: JSON.stringify({ question: userText })
        });

        if (!response.ok) {
          throw new Error(`Serveur injoignable (HTTP ${response.status})`);
        }

        const result = await response.json();
        setMessages(prev => [...prev, {
          sender: 'agent',
          text: result.answer,
          response: result
        }]);

        if (onNewResult) {
          onNewResult(result);
        }
      } catch (err) {
        console.error("Live API failure:", err);
        setErrorMsg(`Échec réseau : ${err.message}. Assurez-vous que le backend Django est démarré, ou passez en Mode Démo.`);
      } finally {
        setLoading(false);
      }
    }
  };

  // Trigger send if user clicked on map which set inputQuestion
  useEffect(() => {
    // If inputQuestion ends with ' ?' and has length, we can optionally submit or just wait for click
    // Prompt 2.3: "pré-remplit la zone de saisie du chat avec 'Quelle est la {indicateur} de {région} en {année} ?' au lieu d'envoyer automatiquement."
    // So we do not auto-submit, just keep the text there.
  }, [inputQuestion]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'rgba(15, 23, 42, 0.4)' }}>
      {/* Conversation History */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {messages.map((msg, index) => {
          const isUser = msg.sender === 'user';
          const hasTable = msg.response?.table && msg.response.table.length > 0;
          const isFictitious = msg.response?.metadata?.fictitious;

          return (
            <div key={index} className="slide-up" style={{
              alignSelf: isUser ? 'flex-end' : 'flex-start',
              maxWidth: '85%',
              display: 'flex',
              flexDirection: 'column',
              gap: '6px'
            }}>
              {/* Message Bubble */}
              <div className="glass-card" style={{
                padding: '16px 20px',
                borderRadius: isUser ? '18px 18px 2px 18px' : '18px 18px 18px 2px',
                backgroundColor: isUser ? 'rgba(16, 185, 129, 0.25)' : 'var(--glass-card-bg)',
                border: isUser ? '1px solid rgba(16, 185, 129, 0.4)' : '1px solid var(--border-color)',
                fontSize: '15px',
                lineHeight: '1.6',
                color: 'var(--text-primary)',
                wordBreak: 'break-word',
                boxShadow: '0 4px 15px rgba(0,0,0,0.05)'
              }}>
                <div>{formatMessageText(msg.text)}</div>

                {/* HTML Table rendering if table is not empty */}
                {hasTable && (
                  <div style={{ marginTop: '12px', overflowX: 'auto', borderRadius: '6px', border: '1px solid var(--border-color)' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px', textAlign: 'left' }}>
                      <thead>
                        <tr style={{ background: 'rgba(255, 255, 255, 0.05)', borderBottom: '1px solid var(--border-color)' }}>
                          {Object.keys(msg.response.table[0]).map((head, hIdx) => (
                            <th key={hIdx} style={{ padding: '8px 12px', textTransform: 'capitalize', color: 'var(--text-secondary)', fontWeight: '600' }}>
                              {head === 'annee' ? 'Année' : head === 'valeur' ? 'Valeur' : head}
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {msg.response.table.map((row, rIdx) => (
                          <tr key={rIdx} style={{
                            borderBottom: rIdx < msg.response.table.length - 1 ? '1px solid var(--border-color)' : 'none',
                            background: rIdx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.02)'
                          }}>
                            {Object.values(row).map((cell, cIdx) => (
                              <td key={cIdx} style={{ padding: '8px 12px', color: 'var(--text-primary)' }}>
                                {typeof cell === 'number' && !Number.isInteger(cell) 
                                  ? cell.toFixed(1) 
                                  : typeof cell === 'number' 
                                    ? new Intl.NumberFormat('fr-FR').format(cell) 
                                    : cell
                                }
                              </td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>

              {/* Fictitious banner warning */}
              {!isUser && isFictitious && (
                <div style={{
                  fontSize: '12px',
                  color: '#fbbf24',
                  display: 'flex',
                  alignSelf: 'flex-start',
                  alignItems: 'center',
                  gap: '4px',
                  background: 'rgba(245, 158, 11, 0.1)',
                  padding: '2px 8px',
                  borderRadius: '10px',
                  border: '1px solid rgba(245, 158, 11, 0.2)',
                  marginTop: '2px'
                }}>
                  <AlertTriangle size={10} /> Données pédagogiques fictives
                </div>
              )}
            </div>
          );
        })}

        {/* Loading Spinner Indicator */}
        {loading && (
          <div className="pulse-glow slide-up" style={{ alignSelf: 'flex-start', display: 'flex', gap: '8px', alignItems: 'center', background: 'rgba(30, 41, 59, 0.4)', padding: '12px 16px', borderRadius: '14px', border: '1px solid var(--border-color)' }}>
            <Loader2 size={16} className="animate-spin" style={{ color: '#10b981' }} />
            <span style={{ fontSize: '15px', color: 'var(--text-secondary)' }}>Diiwan réfléchit...</span>
          </div>
        )}

        {/* Error message card */}
        {errorMsg && (
          <div className="fade-in" style={{
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid rgba(239, 68, 68, 0.3)',
            color: '#fca5a5',
            padding: '12px 16px',
            borderRadius: '8px',
            fontSize: '15px',
            display: 'flex',
            alignItems: 'start',
            gap: '8px',
            marginTop: '8px'
          }}>
            <AlertTriangle size={16} style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>{errorMsg}</div>
          </div>
        )}
        <div ref={chatEndRef} />
      </div>

      {/* Input Saisir Section */}
      <form onSubmit={handleSubmit} style={{
        padding: '16px',
        borderTop: '1px solid var(--border-color)',
        display: 'flex',
        gap: '8px',
        alignItems: 'center',
        background: 'rgba(15, 23, 42, 0.6)'
      }}>
        <input
          type="text"
          value={inputQuestion}
          onChange={(e) => setInputQuestion(e.target.value)}
          placeholder="Posez une question sur les statistiques..."
          disabled={loading}
          style={{
            flex: 1,
            background: 'var(--input-bg)',
            border: '1px solid var(--border-color)',
            borderRadius: '24px',
            padding: '14px 20px',
            color: 'var(--text-primary)',
            outline: 'none',
            fontSize: '15px',
            transition: 'border-color 0.2s',
          }}
          onFocus={(e) => e.target.style.borderColor = 'rgba(16, 185, 129, 0.6)'}
          onBlur={(e) => e.target.style.borderColor = 'var(--border-color)'}
        />
        <button
          type="submit"
          disabled={loading || !inputQuestion.trim()}
          style={{
            background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
            border: 'none',
            width: '48px',
            height: '48px',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#ffffff',
            cursor: 'pointer',
            opacity: (!inputQuestion.trim() || loading) ? 0.6 : 1,
            transition: 'transform 0.2s, opacity 0.2s',
          }}
          onMouseEnter={(e) => { if (inputQuestion.trim() && !loading) e.currentTarget.style.transform = 'scale(1.05)' }}
          onMouseLeave={(e) => { e.currentTarget.style.transform = 'none' }}
        >
          <Send size={16} />
        </button>
      </form>
    </div>
  );
}
