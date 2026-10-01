# beatoraja カスタムフォルダ作成ツール

beatoraja の選曲画面に出るカスタムフォルダを、GUIで作る Windows 用ツールです。難易度表・BPM・BP・クリアランプ・DJ LEVEL の条件を選ぶと、掛け合わせたフォルダを `beatoraja/folder/default.json` に書き込みます。

## ダウンロード

[Releases ページ](https://github.com/yvr1-c1ph3r/bms-folder-generator/releases/latest) から `beatoraja_folder_maker.zip` をダウンロードしてください。

解凍すると、`beatoraja_folder_maker.exe` と使い方の `README.md` が入っています。インストールは不要です。exe をダブルクリックすると起動します。

ウイルス対策ソフトが警告を出すことがあります。Python製のexeによくある誤検知です。

## このリポジトリについて

ソースコードと管理者向けの資料です。使うだけなら、上のダウンロードだけで足ります。

| 場所 | 内容 |
|---|---|
| `管理者用/beatoraja_folder_maker.py` | 本体のソース。標準ライブラリのみ（Python 3.9+） |
| `管理者用/build_exe.bat` | exe を作るバッチ。PyInstaller を自動で入れます |
| `管理者用/README2.md` | 仕様の根拠、既定値の変え方、配布の手順 |
| `管理者用/文字テスト_default.json` | スキンで表示できる文字を調べる確認用 |
| `CLAUDE.md` | Claude Code 用の引き継ぎメモ |

## ソースから動かす

```
python 管理者用/beatoraja_folder_maker.py
```

exe を作るときは `管理者用/build_exe.bat` をダブルクリックします。Python とネットワークが必要です。
