---
title: "Vim Input Method Editor"
emoji: "🇯🇵"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vim", "ime", "skk"]
publication_name: "vim_jp"
published: true
---


VimをIME代わりにするVIMEというソフトウェアがvim-jpで紹介された際に試しましたが上手く動かなかったので、カッとなって作ったスクリプトを紹介します。

```sh
#!/bin/bash -u

wezterm start --class Floaterm nvim /tmp/clip || exit 1
if [[ -e /tmp/clip ]]; then
  head -c -1 /tmp/clip | xclip -selection clipboard
  notify-send -t 1000 copied
  rm -f /tmp/clip
fi
```

このようなスクリプトを用意し、私が普段使っているi3の設定に以下の記述を行います。

```
for_window [instance="Floaterm"] floating enable
bindsym Mod4+c exec XMODIFIERS=@im= ~/.config/i3/clip.sh
```

すると `Mod4(Super)+c` を押すと画面中央にWezTerm+Vimが立ち上がります。後はコピーしたい内容を入力し保存終了したらクリップボードにコピーされるので貼り付けるだけです。自作の日本語入力プラグインである[skkeleton](https://github.com/vim-skk/skkeleton)とこのスクリプトを一緒に使えばある程度VimをIMEのように使えます。

# おまけ

以下はおまけです。skkeletonについて雑に書いてます。

私は普段、日本語入力を行うのにSKKを使っています。「プログラムで行うのが難しい^[TODO: 形態素解析は自然言語処理の永遠の課題だと思います、この辺については[日本語入力を支える技術](https://gihyo.jp/book/2012/978-4-7741-4993-6)という本に詳しく書いてあります。ちなみにSKKは全くやりません。]、文節の区切りを人にやらせる」という発想による大変シンプルな仕組みと、それに伴う効率のいい入力体験を特徴としたIMEです。
シンプルな仕組み故にテキストエディタ上で実装するのも容易で(そもそもの発祥がEmacs Lispのプログラムである^[[Daredevil SKK](http://openlab.ring.gr.jp/skk/ddskk-ja.html)と呼ばれています。私もEmacs使ってる時は使ってます。])処理系も多数存在しています。
私も、このシンプルなIMEに惚れ込み、Emacsごと覚えた後、元々使っていたVimでも[eskk.vim](https://github.com/vim-skk/eskk.vim)という処理系を使うようになりました。
その後、紆余曲折あり[skkeleton](https://github.com/vim-skk/skkeleton)という新しい処理系を作りました。これについては[以前記事を書いています](https://zenn.dev/kuu/articles/vac2021-skkeleton)。^[ちなみにこの記事もskkeletonで書いています。]
作る上でちょっとVimのことを知ったりしたので内部実装について要点をいくつか書いていきたいと思います。

# 実装する時に考えていたこと

- キーマップや仮名テーブルを変更できるように設計する

eskk.vimでは各種機能は分岐の塊としてハードコードされていましたが、自由に変更できるとするとこのような実装をする訳にはいかないしメンテナンスの観点からもよくありません。そこでskkeletonではSKKの「仮名入力状態と変換状態をくるくる行き来する」という動作にそれぞれテーブルを与えました。個々の機能は特定のインターフェースを持つ関数として表現することにしました。これにより(個々の関数の中身は別として)大枠はかなりシンプルになったと思います。
ハンドリングしているのはこの辺りです。
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/keymap.ts
仮名テーブルについても、カスタマイズできるようにすると共にこの関数をセットできるようにしています。
管理しているのはこの辺りで
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/kana.ts
実際のハンドリングを行っているのはkanaInput関数の中です
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/function/input.ts#L80-L157

- 任意の仮名配列を使えるようにする

SKKは全体的にローマ字入力を前提として設計されており、それは辞書の送りあり変換部分の仕様にも及んでいます。例えば今打った「及ん」は`およn /及/`のように収録されています。eskk.vimではローマ字で入力することを前提にして、入力を保存し利用することで送りあり変換を実現していますが、完全な配列のカスタマイズができないという問題がありました。
skkeletonでは、Emacsの本家SKKと同様に、このようなテーブルを用意し仮名からローマ字のプリフィクスを導くようにしました。
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/okuri.ts

# language-mappingとiminsert

skkeletonは、プラグインの性質上ほとんどのマッピングを独自の物に置き換えますが、`language-mapping` という機能を使って実現しています^[こちらはeskk.vimを参考にしました]。元は、入力の一部分をその言語固有の配列に切り替えるために用意されている機能で(IMEのためではない！)、挿入モードやコマンドラインモードのマッピングを破壊せず別のマッピングを被せるという動きをします。そして、この機能は `'iminsert'` というオプションにより制御されます。

ここまで聞くと簡単に聞こえますが実際はもう少し複雑で、実際に `language-mapping` が使われるかと `'iminsert'` は独立しており、モードに入る際に `'iminsert'` が `1` になっていて、なおかつ1つでも `:lmap` が定義されていれば有効という動きをします。また、APIが挿入モードのキーバインドしかないため、プラグインから切り替えるには `<expr>` マッピングの返り値にする、 `feedkeys()` を使うなどしてVimに該当のキーを送出してやる必要があります。なお、この際に `'iminsert'`も連動して切り替わります。

幸い `input()` からの復帰の際に連動したりはしませんが、結局整合性を取るため手動でセットし直す必要があります。

https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/main.ts#L142-L167

# 入力される度に何をやっているのか

独自でバッファを管理している
preeditで実現している
  差分を抜き差し
入力→stateを操作→preeditの差分を操作

skkeletonでは独自で入力バッファ(preeditと呼んでいます)を管理しており、それをバッファ上に描画することでIMEとしての動作を実現しています。
preeditの中身は状態を元に生成されるようにしています。
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/state.ts#L90-L101
ユーザーがキーを打つ度に対応する関数を実行し、変化した状態から新しいpreeditを生成し、差分を出力します。
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/preedit.ts#L10-L21
Vim側から呼び出す度に、この差分が返ってくるので後はこれをVimに送れば完成です。
https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/autoload/skkeleton.vim#L106-L117
Vimのtextlockを避けるために `feedkeys()` を使って処理していますが、`i` を付けて先行入力の先頭に送ってしまえば正しい順番で処理され問題なく動作します。

# 辞書登録について

SKKの辞書登録は再帰的に動作するためstateを退避したりといった管理が必要になります、恐らくSKKを実装する上で一番厄介な機能と思われます。skkeletonにおいては自前でスタックを管理したりせずにプログラム内にstateを退避した上で新しいstateをその場で作り、再帰的にVim側の `input()` を呼び出すように実装しています。

https://github.com/vim-skk/skkeleton/blob/188b7e03d5a30aef8f7b105a78b038b3d0ff0c0c/denops/skkeleton/function/jisyo.ts
