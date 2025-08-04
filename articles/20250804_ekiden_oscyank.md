---
title: "ちょっとしたコードで端末エミュレータのコピー機能を使う"
emoji: "📋"
type: "tech"
topics: ["vim", "neovim"]
publication_name: "vim_jp"
published: true
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2025-08-04の記事です。
前回の記事は[Totto66](https://totto66.hatenablog.com/)さんの[Vimの標準機能で自動補完](https://totto66.hatenablog.com/entry/vim-ekiden-20250801)でした。私はddc.vimユーザーなので組み込み自動補完を試すのは当分先になりそうですが最小構成でも作る時に使えたらと思います。

# intro

xterm互換の端末エミュレータの多くには[Operating System Commands](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands)というエスケープシーケンスをサポートしており、その中のOSC 52という物を使うと端末に出力したものをクリップボードにコピーできます。

端末エミュレータ次第でサイズの制限があるものの[^wezterm]対応してる端末エミュレータに出力が通りさえすればSSH先だろうが使えるのでとても便利です。

Vim上からもこのOSC52のシーケンスを組み立てて端末に直接出力できれば使えます。例えば[vim-oscyank](https://github.com/ojroques/vim-oscyank)というプラグインがあり私もお世話になっています。

# かつては工夫が必要だった

かつてはこのシーケンスを組み立てるにはVim scriptで頑張ったり外部環境に依存した手段を取るなどの工夫が必要でした。3つの要素を例に、vim-oscyankが取っている手段と最近できるようになった方法と合わせて紹介して、最後に紹介した内容を元にスクリプトを組み立てていきます。

# 選択範囲の取得

vim-oscyankでは、設定、レジスタの中身、選択範囲などを退避した後に指示した範囲でyankを行い最後に諸々を復元するという方法を取っています。これはhelpの[:map-operator](https://vim-jp.org/vimdoc-ja/map.html#:map-operator)の項で紹介されている伝統的な方法です。

Vim9.1.0120からは[getregion()](https://vim-jp.org/vimdoc-ja/builtin.html#getregion%28%29)という渡した範囲のテキストを直接取得する関数が使えます。
この関数を使えば `getregion(getpos('v'), getpos('.'), #{ type: mode() })` のように簡潔に同じ処理を書けます。

# Base64のエンコード

vim-oscyankではVim scriptの実装を使っています。そこまで大きい実装ではないですが筆者はその場でサッと書けと言われて書ける自信はありません。[^vital]

Vim9.1.0980からは[base64_encode()](https://vim-jp.org/vimdoc-ja/builtin.html#base64_encode%28%29)という関数が使えます。ちゃんとBlobが対象になってるのが嬉しい所です。
これと合わせて文字列をBlobにする[str2blob()](https://vim-jp.org/vimdoc-ja/builtin.html#str2blob%28%29)という関数も入ってるので~~この程度ならどっちみち誤差ではありますが~~高速に文字列をBase64エンコードできて気持ちがいいです。

```vim
" バイナリファイルの内容をエンコードする
echo base64_encode(readblob('somefile.bin'))
" 文字列をエンコードする
echo base64_encode(str2blob(somestr->split("\n")))
```

これはhelpにある例(上記に貼っているvimdoc-jaのリンクより)ですが、これくらいシンプルなコードで使えます。

# 端末への直接出力

vim-oscyankでは`/dev/fd/2`というデバイスファイルがある場合はそれに書き込む、`echo`コマンドがあるなら叩くといった手段を取ります。これは環境への依存が存在します。[^env]

Vim8.2.0258からは[echoraw()](https://vim-jp.org/vimdoc-ja/builtin.html#echoraw%28%29)という関数により直接端末に文字列を送れます。

```vim
echoraw(sequence)
```

# スクリプト

私はビジュアルモードで`<CR>`を叩くと選択範囲に対してOSC52を使ったyankが走るようにしているのですが、これを実装してみます。[^operator]

OSC52は `<Esc>` `]` `5` `2` `;` *`Pc`* `;` *`Pd`* `;` `<Esc>` `\` という構成のシーケンスです。
`Pc`はどのバッファを対象にするか(xtermを動かすプラットフォームであるX Window SystemにはVimと似たように複数のカットバッファが存在する)で、今回の用途だとクリップボードを示す`c`を指定します。
`Pd`はBase64でエンコードしたyankしたいデータを指定します。

ビジュアルモードで範囲選択した物を取得してBase64エンコードし、シーケンスに合成した上で端末にするという処理を書くと以下のようになります。

```vim
function s:oscyank() abort
  " 選択範囲のテキストを取得
  let text = getregion(getpos('v'), getpos('.'), #{ type: mode() })
  " Base64エンコード
  let encoded = text->str2blob()->base64_encode()
  " OSC52シーケンスを組み立て
  let seq = "\<Esc>]52;c;" .. encoded .. "\<Esc>\\"
  " 端末に出力
  call echoraw(seq)
endfunction

" ビジュアルモードに関数を実行するマッピングを定義
xnoremap <CR> <Cmd>call <SID>oscyank()<CR><Esc>
```

元々シーケンス合成と出力が短くなるのは知っていましたが、それ以外の部分がここまで短くなるのには筆者も驚きました。

# Appendix

これはVimで使える方法でNeovimではまた別の手段で行うことになります。また、Neovimではそもそもclipboard providerの設定により特別なコードを書かずともOSC52を使えるようになっています。(下記及び`:h clipboard-osc52`参照)気になる方がいたら調べてみてください。

```lua
vim.g.clipboard = 'osc52'
```

# :qa

Vimは日々進化しており、前と比べて制約もどんどん減ってきています。`getregion()`や`base64_encode()`は入る所も見ていたので目の前で進化を感じられてよかったです。
また、Base64のエンコード処理は使い所に迷う関数だと思いますが、ぴったりの用途で使えて満足しています。
この記事を書く中で[OSC 52 で出力をクリップボードにコピーするためのワンライナー](https://zenn.dev/sankantsu/articles/ef2d277789fa8a)という記事にお世話になりました。ありがとうございました。

[^wezterm]: 私が使ってるWezTermは大きめらしく、手元のSKK辞書で検証した結果786426バイトまでコピーできました
[^vital]: 例えば[vital.vim](https://github.com/vim-jp/vital.vim)にはBase64を扱うモジュールがあって実際はそれを使えるので手で書くことはないですが
[^env]: 機能しないケースが実際にあるかは知りません。主要な環境でそんなものがあれば知りたいです。
[^operator]: 完全にオペレータにするのがいいと思うんですがその場で書くのが面倒なので欲しい人がいたら作ってみてください
