// The Mac-side companion: the phone posts a question plus the open chapter,
// the Claude Agent SDK answers on this machine's Claude Code login. The
// model can call add_card; the cards ride back in the response and the
// phone writes them to its own store — the phone stays the source of truth.
import http from 'node:http';
import { query, tool, createSdkMcpServer } from '@anthropic-ai/claude-agent-sdk';
import { z } from 'zod';

const PERSONA =
  'You are a native Chinese speaker reading a book together with a learner, ' +
  'sitting beside them. Answer their questions about the text in English, ' +
  'with Chinese examples where they help. Be concise and warm; answer only ' +
  'what was asked. Pay special attention to meaning that is implied rather ' +
  'than written: dropped subjects, unmarked conditionals, aspect particles. ' +
  'Never correct the learner unless they ask to be corrected. When the ' +
  'learner asks to save or remember a word (or you both agree one is worth ' +
  'keeping), call the add_card tool to put it in their Anki deck.';

async function ask({ question, chapter, history }) {
  const cards = [];
  const anki = createSdkMcpServer({
    name: 'anki',
    version: '1.0.0',
    tools: [
      tool(
        'add_card',
        "Add a flashcard to the learner's Anki deck.",
        {
          word: z.string().describe('the Chinese word or phrase'),
          pinyin: z.string().describe('accented pinyin'),
          gloss: z.string().describe('short English meaning'),
          sentence: z.string().describe('example sentence, ideally from the book'),
        },
        async (args) => {
          cards.push(args);
          return { content: [{ type: 'text', text: `card saved: ${args.word}` }] };
        },
      ),
    ],
  });

  const transcript = (history ?? [])
    .map((t) => `${t.role === 'user' ? 'Learner' : 'You'}: ${t.content}`)
    .join('\n\n');
  const prompt = transcript
    ? `${transcript}\n\nLearner: ${question}`
    : question;

  let text = '';
  for await (const m of query({
    prompt,
    options: {
      systemPrompt:
        `${PERSONA}\n\nThe reader currently has this passage open:\n\n${chapter ?? ''}`,
      mcpServers: { anki },
      allowedTools: ['mcp__anki__add_card'],
      disallowedTools: ['Bash', 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'WebSearch', 'WebFetch'],
      maxTurns: 5,
      permissionMode: 'bypassPermissions',
    },
  })) {
    if (m.type === 'result') {
      if (m.subtype === 'success') text = m.result;
      else throw new Error(`agent ${m.subtype}`);
    }
  }
  return { text, cards };
}

const READER =
  'You prepare one Chinese sentence for a learner reading a book.\n\n' +
  'Reply with JSON and nothing else — no prose around it, no code fence:\n' +
  '{"translation": "...", "notes": [{"about": "...", "says": "..."}]}\n\n' +
  'translation: natural English for the whole sentence, not word by word.\n' +
  'notes: only meaning that is implied rather than written — dropped ' +
  'subjects, unmarked conditionals, aspect particles, register, an idiom ' +
  'whose parts mislead. "about" quotes the fragment from the sentence; ' +
  '"says" is one plain English line about what it carries. A sentence that ' +
  'implies nothing beyond its words gets an empty notes list; do not pad it ' +
  'with a gloss of every word, which is what this exists instead of.';

/// One sentence, prepared: the translation plus what it implies. Structured
/// rather than prose, because the sheet renders the halves differently and
/// the result is cached on the phone under the sentence itself.
async function read({ sentence, chapter }) {
  let text = '';
  for await (const m of query({
    prompt: `Prepare this sentence:\n\n${sentence}`,
    options: {
      systemPrompt: `${READER}\n\nIt appears in this passage:\n\n${chapter ?? ''}`,
      disallowedTools: ['Bash', 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'WebSearch', 'WebFetch'],
      maxTurns: 1,
      permissionMode: 'bypassPermissions',
    },
  })) {
    if (m.type === 'result') {
      if (m.subtype === 'success') text = m.result;
      else throw new Error(`agent ${m.subtype}`);
    }
  }
  // A model told to emit bare JSON still fences it sometimes; the sheet
  // showing a parse error over that would be a self-inflicted failure.
  const json = text.trim().replace(/^```(?:json)?/, '').replace(/```$/, '');
  const start = json.indexOf('{');
  const end = json.lastIndexOf('}');
  if (start < 0 || end < start) throw new Error('the reading was not JSON');
  return JSON.parse(json.slice(start, end + 1));
}

const ROUTES = { '/ask': ask, '/read': read };

http
  .createServer(async (req, res) => {
    const handler = req.method === 'POST' ? ROUTES[req.url] : undefined;
    if (!handler) {
      res.writeHead(404).end();
      return;
    }
    let body = '';
    for await (const c of req) body += c;
    console.log(new Date().toISOString(), `${req.url}:`, body.slice(0, 120));
    try {
      const out = await handler(JSON.parse(body));
      console.log(new Date().toISOString(), 'answered:', JSON.stringify(out).slice(0, 80));
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify(out));
    } catch (e) {
      console.log(new Date().toISOString(), 'error:', String(e?.message ?? e));
      res.writeHead(500, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ error: String(e?.message ?? e) }));
    }
  })
  .listen(8790, "127.0.0.1", () => console.log("tutor server on 127.0.0.1:8790"));
