const axios = require('axios');

const CLAUDE_API_KEY = process.env.CLAUDE_API_KEY;
const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';

const generateResponse = async (message, userName = 'Friend', context = []) => {
  try {
    if (CLAUDE_API_KEY) {
      return await generateWithClaude(message, userName, context);
    }
  } catch (error) {
    console.warn('Claude API failed:', error.message);
  }

  try {
    return await generateWithOllama(message, userName, context);
  } catch (error) {
    console.warn('Ollama failed:', error.message);
  }

  return {
    reply: `Ha! That's a good one, ${userName}! I'm having trouble thinking of a witty response right now, but I appreciate the laugh.`
  };
};

const generateWithClaude = async (message, userName, context) => {
  const systemPrompt = `You are a witty AI comedian. You tell adult jokes and engage in funny banter. Always address the user by their name: ${userName}. Keep responses concise (1-3 sentences). Be clever and playful.`;

  const messages = [
    ...context.map(msg => ({
      role: msg.type === 'user' ? 'user' : 'assistant',
      content: msg.text
    })),
    {
      role: 'user',
      content: message
    }
  ];

  const response = await axios.post(
    CLAUDE_API_URL,
    {
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 500,
      system: systemPrompt,
      messages: messages
    },
    {
      headers: {
        'x-api-key': CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json'
      },
      timeout: 10000
    }
  );

  const text = response.data.content[0].text;
  return { reply: text };
};

const generateWithOllama = async (message, userName, context) => {
  const systemPrompt = `You are a witty AI comedian. You tell adult jokes and engage in funny banter. Always address the user by their name: ${userName}. Keep responses concise (1-3 sentences). Be clever and playful.`;

  const prompt = `${systemPrompt}\n\nUser: ${message}`;

  const response = await axios.post(
    `${OLLAMA_URL}/api/generate`,
    {
      model: 'llama2',
      prompt: prompt,
      stream: false
    },
    { timeout: 15000 }
  );

  return { reply: response.data.response };
};

module.exports = {
  generateResponse
};
