---
title: "Vimでフルパスをいい感じに入力する"
emoji: "⌨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vim"]
publication_name: "vim_jp"
published: false
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2023年8月14日の記事です。

# 導入

Vimにはコマンドラインモードで `%` をカレントファイルのパスに展開してくれる機能や[^1]続けて `:h` や `:p` のようなファイル名修飾子と呼ばれる指示[^2]を与えるとパスを加工してくれる機能があります。
この機能はとても便利ですが、コマンド実行前に展開されるわけではなくVimの内部で展開されるため、履歴に `e %` のようなエントリが残ります。

`%` 単体であれば「カレントファイルを対象とした操作」として汎用的に利用することも可能ですが、ファイル名修飾子を付けてカレントファイルと同じ階層のファイルを操作するケースなどでは `:e %:h/hogehoge.txt` のような使えないエントリが残ります。
他にもそのファイルを操作していることを明示して履歴に残したいケースではこの挙動は不便です。

cmdwin等履歴を操作する機能をフル活用しているVimmerとしては、このような事態はとてもじゃないですが許容できません。かといって一々 `<C-r>=expand('%:p')<CR>` とか打つのもそれはそれでだるすぎます。
こういう時、慣れたVimmerは息をするようにマッピングをするものですが、そのついでに自分のユースケースを1つのマッピングで一気に解決できるようにしてみました。

# 実装

```vim
function s:expandpath() abort
  let pos = mode() ==# 'c' ? getcmdpos() : col('.')
  let line = mode() ==# 'c' ? getcmdline() : getline('.')

  let left = line[pos - 2]

  if left ==# '/'
    return expand('%:p:t')
  else
    return expand('%:p:h') .. '/'
  endif
endfunction

cnoremap <expr> <C-p> <SID>expandpath()
inoremap <expr> <C-p> <SID>expandpath()
```

`%:p` 及び `%:p:h` 相当の物の両方が欲しくなるので両方対応できるようにしました。

たまに挿入モードでも使いたくなるので、コマンドラインモードと挿入モードの両方で使えるように実装しています。

このマッピングは、何も無い所(正確にはカーソルの左(left)がパスじゃない場合)ではカレントファイルのディレクトリのフルパスに展開されます。私はよくこれで同じ階層にファイルを作ったりしてます。

次にそのまま打つとファイルパスの部分が展開されます。フルパスが欲しい時はここまでやります。

コマンドラインモードや挿入モードのキー空間は貴重な資源なのでマッピングする量が減ると嬉しいですね。

# :q

入力系モードはVimの操作体系からすると邪道のような物ですが、Vimのモードらしく完全にマッピングも効きますので最適化しがいがある箇所だと思います。みなさんもどんどんマッピングしましょう。

[^1]: [:h cmdline-special](https://vim-jp.org/vimdoc-ja/cmdline.html#cmdline-special)
[^2]: [:h filename-modifiers](https://vim-jp.org/vimdoc-ja/cmdline.html#filename-modifiers)

