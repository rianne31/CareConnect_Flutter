require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') })
const { GoogleGenerativeAI } = require('@google/generative-ai')
const axios = require('axios')

async function main() {
  const key = process.env.GEMINI_API_KEY
  if (!key) {
    console.error('No GEMINI_API_KEY found in .env')
    process.exit(1)
  }

  console.log('Testing Gemini connectivity...')
  const genAI = new GoogleGenerativeAI(key)
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' })
    const res = await model.generateContent('Say hello in one short sentence.')
    console.log('SDK Success:', res.response.text())
    process.exit(0)
  } catch (err) {
    console.error('SDK error:', err?.message || err)
    // Fallback to REST v1beta endpoint which may be enabled for this key
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=${key}`
      const body = {
        contents: [
          {
            role: 'user',
            parts: [{ text: 'Say hello in one short sentence.' }],
          },
        ],
      }
      const { data } = await axios.post(url, body)
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || JSON.stringify(data).slice(0, 200)
      console.log('REST v1beta Success:', text)
      process.exit(0)
    } catch (restErr) {
      const detail = restErr?.response?.data || (restErr?.message || restErr)
      console.error('REST v1beta error:', detail)
      process.exit(2)
    }
  }
}

main()