# README2 — 管理者向けメモ

配布用の `README.md` には書かない、作る側のための資料です。**配布物には含めないでください。**

## フォルダ構成

```
bmsFolderGenerator/
├─ README.md                  GitHub のトップ用（利用者向けの使い方も含む）
├─ CLAUDE.md
├─ .gitignore                   （配布物を Git から除外）
├─ 管理者用/                    ← GitHub に上げる
│   ├─ bmsFolderGenerator.py
│   ├─ build_exe.bat
│   ├─ README2.md
│   └─ 文字テスト_default.json
└─ ダウンロードはこちら/        ← Git に入れない。zip を Releases に添付して配る
    ├─ bmsFolderGenerator.exe
    ├─ README.md                （ルートの README.md と同一）
    └─ bmsFolderGenerator.zip
```

`build_exe.bat` は exe を `配布用/`（Git対象外）に出力します。できた exe を `ダウンロードはこちら/` に移し、zip を作り直します。

## 配布の手順

1. `build_exe.bat` で exe を作る
2. `ダウンロードはこちら/` の exe を差し替える
3. exe と README.md を `bmsFolderGenerator.zip` に固める
4. GitHub の Releases で新しいリリースを作り、zip を添付する
5. README を直したときは、ルートの `README.md` と `ダウンロードはこちら/README.md` を同じ内容にそろえる（zip に入れる README とGitHubのトップは同一）

## exe を作る

`build_exe.bat` をダブルクリックすると、`配布用` フォルダ（リポジトリ直下、Git対象外）に `bmsFolderGenerator.exe` ができます。

バッチがやっていること。

1. `py` か `python` を探す
2. `pip install --upgrade pyinstaller`
3. `pyinstaller --noconfirm --clean --onefile --windowed` で exe を作り、`build` `dist` `*.spec` を片付ける

Python とネットワークが必要なのはビルドのときだけです。初回は PyInstaller のダウンロードで数分かかります。

**ソースを直したら必ず作り直してください。** exe は Python コードを内包しているため、`.py` を編集しただけでは exe に反映されません。

## 記号を変える

スキンのフォントに無い文字は、フォルダ名で豆腐や別の記号に化けます。`bmsFolderGenerator.py` の先頭近くにある2行を書き換えると、既定値も自動命名も一括で変わります。

```python
RANGE_DASH = " - "
LE_SYMBOL = "≦"
```

- `RANGE_DASH` … BPM や DJ LEVEL の範囲のつなぎ（`低速 - 100` `DJ LEVEL - B`）
- `LE_SYMBOL` … BP の「以下」（`BP≦10` `11≦BP≦20` `51≦BP`）

`≦`（U+2266）が表示できないなら `LE_SYMBOL = "<="` にします。書き換えたら exe を作り直し、すでに作ったフォルダは作り直してください（名前が変わるだけなので、古い名前のフォルダは「生成したフォルダ」タブから削除します）。

## 文字テストの使い方

`文字テスト_default.json` は、空フォルダを38個並べただけのファイルです（SQLはすべて `1 = 2`）。

1. `beatoraja\folder\default.json` を `default.json.orig` にリネーム
2. `文字テスト_default.json` を `beatoraja\folder\` にコピーし、名前を `default.json` に変更
3. beatoraja を起動して「文字テスト」フォルダを開き、化けている番号を確認
4. `default.json` を消して `default.json.orig` を戻す

18番までが文字そのもの、19番より下が実際に使う名前の候補です。`★` `▼` `▽` は難易度表のヘッダから取る記号なので、化ける場合はフォルダ名の付け方から考え直す必要があります。

## 既定値を変える場所

すべて `bmsFolderGenerator.py` の先頭付近にあります。

| 定数 | 中身 |
|---|---|
| `BUILTIN_TABLES` | 最初から並ぶ難易度表（表示名, header URL） |
| `DEFAULT_BPM_RANGES` | BPMの区切り。`(名前, 下限, 上限, BPM変化あり?)` |
| `DEFAULT_BP_RANGES` | BPの区切り。`(名前, 下限, 上限)` |
| `DEFAULT_LAMP_RANGES` | クリアランプ。`(名前, 下限ランプ, 上限ランプ)` |
| `DEFAULT_SCORE_RANGES` | DJ LEVEL。`(名前, 下限, 上限)` |
| `CLEAR_LAMPS` | ランプ名と `score.clear` の対応 |
| `DJ_LEVEL_NINTHS` | DJ LEVEL としきい値（9分のいくつ以上か） |
| `ROOT_NAME` | 一番上のフォルダ名（`カスタムフォルダ`） |
| `SIZE_WARN` | この大きさを超えたら書き込み前に確認する（3MB） |
| `IN_CHUNK` | `IN (...)` を分割する単位（400件） |

既定の表を増やすと、すでに `difficulty_tables.json` を持っている環境にも次回起動時に自動で追加されます。ユーザーが削除した表は記録が残るため、勝手に復活しません。

## beatoraja 側の仕様（実装の根拠）

すべて本体のソースで確認した内容です。

**読み込まれるのは `folder/default.json` だけ**
`BarManager.java` の `init()` が `Paths.get("folder/default.json")` を直接開きます。`folder` ディレクトリを列挙する処理はないため、別名のファイルは読まれません。

**使えるキーは5つだけ**
`BarManager.CommandFolder` のフィールドが `name` / `folder` / `sql` / `rcourse` / `showall` です。libGDX の `Json` は `setIgnoreUnknownFields(true)` を呼んでいないため、未知のキーが1つでもあると例外になり、カスタムフォルダ全体が読み込まれません。本ツールは書き込み前に `validate_folders()` で検査します。

**`sql` は WHERE 句の中身**
`SQLiteSongDatabaseAccessor#getSongDatas()` が次の形で組み立てます。

```sql
SELECT DISTINCT md5, song.sha256 AS sha256, title, ... , charthash
FROM (song に songreview.db を LEFT JOIN したサブクエリ) AS song
LEFT OUTER JOIN (score LEFT OUTER JOIN scorelog ON score.sha256 = scorelog.sha256)
  ON song.sha256 = score.sha256
WHERE <ここに sql が入る>
```

`songinfo.db` が有効なときは `information` と **INNER JOIN** に変わります。そのため `songinfo.db` にレコードが無い譜面は結果から落ちます。

**参照できるテーブル**
ATTACH されるのは `score.db` / `scorelog.db` / `songreview.db` / `songinfo.db` の4つだけです。エイリアスではなくテーブル名で修飾します（`score.clear` であって `scoredb.score.clear` ではない）。

| 修飾子 | 使える主な列 |
|---|---|
| `song.` | md5, sha256, title, genre, artist, path, level, difficulty, maxbpm, minbpm, length, mode, notes, favorite, adddate, charthash |
| `score.` | clear, epg, lpg, egr, lgr, notes, combo, minbp, playcount, clearcount, date |
| `scorelog.` | clear, oldclear, score, oldscore, minbp, oldminbp, date |
| `information.` | n, ln, s, ls, total, density, peakdensity, mainbpm（songinfo.db 有効時のみ） |

**難易度表は SQL から見えない**
難易度表は `table/` の `.bmt`（gzip + JSON）に保存され、SQLがアクセスできるDBには入りません。そのため本ツールは配布JSONから `md5` を取り出して `song.md5 IN (...)` に展開しています。`TableDataAccessor` と `TableData` で確認しました。

**クリアランプの値**
`ClearType.java` の定義。NoPlay(0) Failed(1) AssistEasy(2) LightAssistEasy(3) Easy(4) Normal(5) Hard(6) ExHard(7) FullCombo(8) Perfect(9) Max(10)。

**DJ LEVEL の判定**
同梱の `folder/default.json` は `(lpg*2+epg*2+lgr+egr) * 50 / score.notes >= 88.88` と書いていますが、SQLite の整数割り算のせいで端の点数が落ちます。本ツールは `レート >= k/9` を `EXスコア × 9 >= ノート数 × 2k` に置き換えた整数の比較にしています（AAA なら `* 16`）。

**プレイヤー**
`player/<playerid>/score.db`。`config.json` の `playername` が現在のプレイヤーです（`PlayerConfig.init` が `config.getPlayername()` を使用）。

## 譜面数の数え方

`ChartCounter` が `songdata.db` を `file:...?mode=ro` の URI で開き、`score.db` と `scorelog.db` も同じく読み取り専用で ATTACH します。無い場合は同じ列を持つ TEMP テーブルを作って未プレイ扱いにします。

数えるSQLは本体と同じ形の `SELECT DISTINCT ...` を `SELECT COUNT(*) FROM ( ... )` で包んだものです。読み取り専用なので、beatoraja のデータを書き換えることはありません（書き込みが拒否されること、`-wal` などの副産物が出ないことをテストで確認済み）。

## 動作確認の内容

beatoraja 本体と同じ形のSQLを組み、同じスキーマの `songdata.db` / `score.db` / `scorelog.db` / `songreview.db` を作って検証しています。

- 既定値21行（BPM5・BP5・LAMP7・SCORE4）が、それぞれ期待した譜面だけを返すこと
- DJ LEVEL の境界ちょうどの点数が正しい側に入ること（ノート数900、EX 1600/1400/1200/1000 とその前後1点）
- クリアランプ `clear` 0〜10 の11譜面が、正しい行にだけ入ること
- ソフラン（`minbpm != maxbpm`）が固定BPM譜面を拾わず、変化幅の狭い譜面も拾うこと
- 条件の組み合わせ（難易度表・BPM・BP・LAMP・SCORE の有無、レベル階層のあり／なし）で構造とキー検査が通ること
- `md5` を5000件並べても正しく動くこと（`IN` の分割）
- 難易度表の保存と再読み込み、削除した既定表が復活しないこと、壊れた保存ファイルからの復帰
- `カスタムフォルダ` の作成・追記・同名の置き換え・削除（1件／まるごと）
- 0件フォルダの除外と、中身が無くなった親フォルダの削除
- ダミーの tkinter で画面を実際に組み立て、起動から生成・削除・再起動・オフライン生成まで例外が出ないこと

テストはサンドボックス上で書き捨てにしています。手元に残す場合は `管理者用` フォルダに置かないでください（exe に巻き込まれます）。

## 参考資料

- beatoraja 本体: <https://github.com/exch-bms2/beatoraja>
  - `src/bms/player/beatoraja/select/BarManager.java`（`folder/default.json` の読み込み、`CommandFolder` の定義）
  - `src/bms/player/beatoraja/select/bar/CommandBar.java`（SQLの実行）
  - `src/bms/player/beatoraja/song/SQLiteSongDatabaseAccessor.java`（SQLの組み立て、ATTACH）
  - `src/bms/player/beatoraja/ScoreDatabaseAccessor.java`（score テーブルの定義）
  - `src/bms/player/beatoraja/ClearType.java`（クリアランプの値）
  - `src/bms/player/beatoraja/TableDataAccessor.java`・`TableData.java`（難易度表の保存先）
  - `src/bms/player/beatoraja/PlayerConfig.java`（プレイヤーの持ち方）
  - `folder/default.json`（同梱のカスタムフォルダの実例）
- 難易度表のヘッダ
  - Satellite <https://stellabms.xyz/sl/header.json>
  - Stella <https://stellabms.xyz/st/header.json>
  - 発狂BMS難易度表（★・GENOCIDE） <https://miraiscarlet.github.io/bms/table/genocide_insane/header_insane.json>
  - NEW GENERATION 発狂難易度表（▼） <https://rattoto10.github.io/second_table/insane_header.json>
  - 第2通常難易度表（▽） <https://bmsnormal2.syuriken.jp/js/header.json>
- 難易度表の一覧: 主な難易度表まとめ <https://w.atwiki.jp/bms_progress/pages/4471.html>
- カスタムフォルダの解説（KasaBlog）
  - LR2編 <https://www.kasacontent.com/musicgame/bms/1655/>
  - beatoraja編 <https://www.kasacontent.com/musicgame/beatoraja/4404/>
- カスタムフォルダの実例集 <https://github.com/kasakon555/beatorajaCustomFolder>
