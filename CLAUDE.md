# CLAUDE.md — beatoraja カスタムフォルダ作成ツール

Claude Code はこのフォルダで起動すると、このファイルを自動で読みます。作業を引き継ぐときはここから読んでください。

## これは何か

beatoraja の選曲画面に出るカスタムフォルダを、GUIで作るWindows用ツールです。難易度表・BPM・BP・クリアランプ・DJ LEVEL の条件を選ぶと、掛け合わせたフォルダを `beatoraja/folder/default.json` に書き込みます。

- 言語: Python 3.9+、**標準ライブラリのみ**（tkinter / sqlite3 / urllib）
- 配布形態: PyInstaller の onefile exe
- 単一ファイル構成: `bmsFolderGenerator.py`（約2,080行）に全部入っています

外部ライブラリを増やさない方針です。exe のサイズと誤検知を抑えるためです。

## ファイル

GitHub に上げるのは `管理者用/` などの管理用ファイルだけです。配布物（exe と利用者向け README.md）は `ダウンロードはこちら/` に置きますが、`.gitignore` で Git から除外し、GitHub Releases の zip で配ります。手順は `管理者用/README2.md` にあります。

| ファイル | 役割 | 配布 |
|---|---|---|
| `管理者用/bmsFolderGenerator.py` | 本体 | しない |
| `管理者用/build_exe.bat` | exe を作る（リポジトリ直下の `配布用/` に出力。Git対象外） | しない |
| `管理者用/README2.md` | 管理者向け。仕様の根拠・参考資料・既定値の変え方・配布手順 | しない |
| `管理者用/文字テスト_default.json` | スキンで表示できる文字を調べる確認用 | しない |
| `CLAUDE.md`（ルート） | このファイル | しない |
| `ダウンロードはこちら/`（Git対象外） | exe・利用者向け README.md・配布zip | Releases の zip で配る |

**詳しい背景は `管理者用/README2.md` に書いてあります。** beatoraja 本体のソースで確認した仕様、参考リンク、動作確認の内容はそちらを参照してください。ここでは重複させません。

## 動かす・作る

```
python 管理者用/bmsFolderGenerator.py     # そのまま起動
管理者用/build_exe.bat                        # exe を作る（配布用/ に出力。PyInstaller を自動で入れる）
```

`.py` を直したら **exe を作り直す**まで利用者には反映されません。

## コードの地図

`bmsFolderGenerator.py` を上から順に、区切りコメントで6つに分けています。

1. **定数**（50〜175行あたり）
   `RANGE_DASH` `LE_SYMBOL` `BUILTIN_TABLES` `DEFAULT_*_RANGES` `CLEAR_LAMPS` `DJ_LEVELS` `ALLOWED_KEYS` `ROOT_NAME` `IN_CHUNK` `SIZE_WARN`
2. **通信・難易度表の読み込み**
   `http_get` `resolve_header_url`（HTMLの `<meta name="bmstable">` を解決）`load_table`
3. **SQL生成**
   `hash_sql`（md5/sha256 の `IN` 展開）`bpm_sql` `bp_sql` `lamp_sql` `dj_level_sql` `and_sql`
4. **フォルダ構造の組み立て**
   `build_folder`（中心。条件を掛け合わせて1つのフォルダを返す）`level_items` `table_base_sql` `auto_title` `validate_folders`
5. **ファイルの読み書き**
   `read_existing` `merge_into_root` `write_default_json` `guess_default_json`、難易度表の保存 `load_tables` `save_tables`
6. **譜面数の集計**
   `ChartCounter`（DBを読み取り専用で開く）`prune_empty` `list_players` `default_player`

GUIは `App`（`tk.Tk` の派生）と部品クラス `ScrollFrame` `RangeEditor` `RankEditor` `Section`、および `make_range_tree` などの補助関数です。

## 触るときに守ること

**`default.json` のキーは5種類だけ**
`name` / `sql` / `folder` / `showall` / `rcourse` 以外を書くと、beatoraja がカスタムフォルダ全体を読み込まなくなります。書き込み前に `validate_folders()` が検査します。ここを緩めないでください。

**記号は定数経由で**
`RANGE_DASH` と `LE_SYMBOL` を直接使い、フォルダ名に記号をハードコードしないこと。スキンのフォントに無い文字があると豆腐になるため、1か所で差し替えられる形を保ちます。

**DBは読み取り専用**
`ChartCounter` は `file:...?mode=ro` の URI で開きます。beatoraja のデータを書き換えない、`-wal` などの副産物を作らない、を崩さないこと。

**桁揃えは表の列で**
一覧の桁揃えに空白padding を使わないこと。日本語の文字幅が半角2つぶんでない環境でずれます。`make_range_tree()` の Treeview の列（`anchor` と `width`）で決めます。過去にpadding方式で3回作り直しました。

**GUI部品は `App.__init__` で先に作る**
`_build_ui()` の途中で `self.xxx_var` を参照する箇所があるため、`StringVar` / `BooleanVar` は `__init__` でまとめて作ります。過去にこの順序ミスで起動しないバグを2回出しました。

**書き込みの前に必ずバックアップ**
`write_default_json()` が `default.json.<日時>.bak` を作ります。

## 決まっている設計（戻さないこと）

利用者との相談で決めた仕様です。理由つきで残します。

- **入れ子にしない。** 条件を掛け合わせた結果は `低速 - 100 / BP≦10` のような1階層のフラットな並びにする。選曲画面で潜る回数を減らすため
- **難易度表はレベルで分けず、絞り込み条件として使う。** 「Satellite の譜面すべてを対象に、BPだけで振り分ける」が既定の動き。レベルで分けたいときだけ「最下層を難易度レベルにする」を使う
- **難易度表だけを選んだ場合に限り**、中身をレベルごとにする
- **生成物は `カスタムフォルダ` の中**に入れる。`default.json` の先頭に置き、既存の `MY BEST` などには触らない
- **未プレイ × LAMP / SCORE の組み合わせは作らない。** 必ず空になるため
- **DJ LEVEL は整数比較。** 同梱 default.json の `* 50 / notes >= 88.88` はSQLiteの整数割り算で端が落ちる。`EXスコア × 9 >= ノート数 × 2k` を使う
- **難易度表は取得したらファイルに保存**して、次回起動でも使えるようにする。削除した既定表は復活させない

## 検証のしかた

tkinter が無い環境（CI、Linuxコンテナ）でも中身を確認できるようにしています。過去にサンドボックスで使った方法です。

**1. ダミーtkinterで起動を通す**
`tkinter` / `tkinter.ttk` / `filedialog` / `messagebox` を差し替えたダミーモジュールを `sys.modules` に入れてから `App()` を生成します。ウィジェットの生成順の誤り（未定義の `self.xxx` 参照）はこれで捕まります。Treeview は `insert` / `delete` / `get_children` / `selection` / `index` / `column` を持つスタブが必要です。

**2. 実DBでSQLを照合**
beatoraja 本体と同じ形の SELECT を組み、同じスキーマの `songdata.db` / `score.db` / `scorelog.db` / `songreview.db` を作って、生成したWHERE句が期待した譜面だけを返すか確かめます。境界値（DJ LEVEL のちょうどの点数、`clear` 0〜10、ソフランの幅が狭い譜面）を必ず入れること。

**3. 偽の beatoraja フォルダで通しテスト**
`songdata.db` / `config.json` / `player/<名前>/score.db` を並べたフォルダを作り、`App._do_work()` を直接呼んで `default.json` の中身を確認します。0件フォルダの除外もここで見ます。

スキーマのCREATE文は `README2.md` の記載と、本体の `ScoreDatabaseAccessor.java` / `SQLiteSongDatabaseAccessor.java` に合わせてください。

## 残っていること

- **`≦`（U+2266）が実機のスキンで表示できるか未確認。** `文字テスト_default.json` で確認し、化けるなら `LE_SYMBOL = "<="` に変える。`★` `▼` `▽`（難易度表の記号）も同様に未確認
- テストコードはリポジトリに残していません。必要なら `tests/` を作る（exe に巻き込まれないよう、PyInstaller の対象から外すこと）
