// netlify/functions/ai-analyze.js
// Proxy seguro para llamadas a Anthropic API
// La API key NUNCA se expone al frontend

exports.handler = async (event, context) => {
  // Solo permitir POST
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' }
  }

  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': process.env.URL || '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' }
  }

  try {
    const { prompt, employee } = JSON.parse(event.body)

    if (!prompt) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'Missing prompt' }) }
    }

    const apiKey = process.env.ANTHROPIC_API_KEY
    if (!apiKey) {
      return { statusCode: 500, headers, body: JSON.stringify({ error: 'API key not configured' }) }
    }

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      }),
    })

    if (!response.ok) {
      const errorData = await response.json()
      return { statusCode: response.status, headers, body: JSON.stringify({ error: errorData }) }
    }

    const data = await response.json()
    const text = data.content.map(c => c.text || '').join('')
    const clean = text.replace(/```json|```/g, '').trim()
    
    let analysis
    try {
      analysis = JSON.parse(clean)
    } catch {
      return { statusCode: 200, headers, body: JSON.stringify({ raw: text }) }
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ analysis }),
    }
  } catch (error) {
    console.error('AI analyze error:', error)
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: error.message }),
    }
  }
}
