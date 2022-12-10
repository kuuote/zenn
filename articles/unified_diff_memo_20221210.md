---
title: "Unified Diffに関する覚え書き"
emoji: "📜"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["diff"]
published: true
---

[ddu-source-git_diff](https://github.com/kuuote/ddu-source-git_diff)を実装しててUnified形式のdiffをパースする必要があったのでメモ

- 自分が必要な範囲でしか書いてないので参考資料の方が詳しい
  - [unified 形式パッチの文法について](https://mizunashi-mana.github.io/blog/posts/2019/04/about-unified-diff-style/)
  - [Comparing and Merging Files](https://www.gnu.org/software/diffutils/manual/diffutils.html#Output-Formats)
    - diffutilsのマニュアル。上の記事で参照されているもので、多分一番これが詳しい
- Unified形式はdiffutilsなどが出力するフォーマットの1つでこのような見た目をしている(データはdiffutilsのマニュアルより抜粋)
  ```diff
  --- lao	2002-02-21 23:30:39.942229878 -0800
  +++ tzu	2002-02-21 23:30:50.442260588 -0800
  @@ -1,7 +1,6 @@
  -The Way that can be told of is not the eternal Way;
  -The name that can be named is not the eternal name.
   The Nameless is the origin of Heaven and Earth;
  -The Named is the mother of all things.
  +The named is the mother of all things.
  +
   Therefore let there always be non-being,
     so we may see their subtlety,
   And let there always be being,
  @@ -9,3 +8,6 @@
   The two are the same,
   But after they are produced,
     they have different names.
  +They both may be called deep and profound.
  +Deeper and more profound,
  +The door of all subtleties!
  ```
  - diffutilsのマニュアル曰く[Wayne Davison](https://github.com/WayneD)氏が設計した物らしい
  - 人にも見やすいからか広く使われており、`git diff`などのツールは標準でこれを吐く
    - 今回パースすることになったのは`git diff`の出力を扱いたかったため
- このフォーマットはヘッダーとブロックのような構造から成り立つパッチを1つの単位とし、1つのファイルに複数のパッチを持てる
  - パッチは以下の定義から成る
    - `---`及び`+++`で始まるファイル名の定義
      - ヘッダーみたいなもの
      - `---`が旧ファイル、`+++`が新ファイル
      - 次にファイル名。Tab以外の任意長の文字列(何を受け付けるのかは調べてない) + 任意でTabとコメントから成り立つ
        - 上の例だと分かりづらいけど`lao`と日付の間にTabがある。日付はコメント
          - `diffutils`は日付を入れるが`git diff`は入れない。gitにとってファイルのタイムスタンプは重要ではないということだろう多分
    - `@@`で始まるヘッダーと正規表現で言う所の`[ +-]`で始まるdiff本体から成るハンクが任意個
      - ヘッダーの意味はこう。`@@ -(古いファイルの位置),(古いファイルのハンクの長さ) +(新しいファイルの位置),(新しいファイルの長さ) @@`
        - 長さについては1の場合は省略できる
        - `git diff`も省略するので対応しないといけない
    - 本体は先頭1文字が指示、その後は実際の行の中身
      - `-`だと新しいファイルから削除される
      - `+`だと新しいファイルに追記される
      - 何も付いていない場合はそのまま使われる
  - `git diff`の場合先頭に以下のような出力がくっついているがUnified形式のお気持ちからするとこれはコメント
    ```diff
    diff --git a/file b/file
    index aaaaaaa..bbbbbbb 100644
    ```
    - `git`にとっては意味のある出力らしいので注意
- 意味のある単位で切り出すには以下のことをやるといい
  - フォーマットが正しいと仮定して行っているので人が編集しているのを想定するとエラーハンドリングなどの面で不適格
    - `patch`や`git`などの正しく処理しているプログラムを参照すべし
  - ファイルを先頭から走査し`---`で始まる行を探し出す
  - 2行分切り出して飛ばす
  - `@`で始まってるか見る。もしそうでなければ今まで切り出したデータを1つのパッチとして別の場所に切り出す。これを繰り返す
    - 先頭行をパースしハンクの長さをそれぞれ取り出す
    - 新旧それぞれ用にカウンタを用意する
    - 各行に以下の処理を適用
      - `-`だったら旧カウンタを+
      - `+`だったら新カウンタを+
      - ` `だったら両方を+
      - カウンタがハンクの長さと全て一致したらハンクの終わりと見なし、それ以前の行を全て切り出す
  - パッチの切り出しが終わったら最初に戻って同じことをファイルの終端まで繰り返す
  - 参照実装は[ここ](https://github.com/kuuote/ddu-source-git_diff/blob/b7d8678666f26ce3fd1daf2fae2cf7a3d3424863/denops/%40ddu-sources/udiff/diff.ts#L12)にある
