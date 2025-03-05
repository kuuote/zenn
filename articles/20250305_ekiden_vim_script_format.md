---
title: ":%!xxx-fmtをいい感じにスクリプトでやる"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vim"]
publication_name: "vim_jp"
published: true
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2025-03-05の記事です。
前回の記事は[kawarimidoll](https://zenn.dev/kawarimidoll)さんの[略しすぎて別の単語になってしまったVimのコマンドなにこれクイズ](https://zenn.dev/vim_jp/articles/36213839dda0f2)でした。私はdebuなのに`:debu`使ったことがありませんでした。
次回の記事は[staticWagomU](https://wagomu.me/)さんの`vim駅伝を2年間書き続けることで得られたもの`の予定です。継続してるのえらい。

Vimでは[:range!](https://vim-jp.org/vimdoc-ja/change.html#:range!)という機能を使うことにより、外部コマンドでフィルターをかけられます。これを使って `:%!xxxfmt -` のように標準入出力を使ったフォーマットコマンドでフォーマットをかけるという使い方ができます。
これはシンプルでよいのですが、フォーマットをかけた際にカーソルがファイルの先頭に戻る^[ファイル全体が書き換えられるため]、エラーが起きた際にファイル全体が置き換わる(アンドゥしてもカーソルが戻らないので結構不便)という問題があります。
Vim scriptでも同じことをよりよい方法で行えるため、私はちょっとしたスクリプトを書いて使っています。本記事ではそのスクリプトを紹介して解説します。

```vim
function! vimrc#feat#format#execute(cmd) abort
  let result = systemlist(a:cmd, getline(1, '$'))
  if v:shell_error != 0
    for l in result
      echoerr l
    endfor
    return
  endif
  let view = winsaveview()
  call deletebufline('%', 1, '$')
  call setline(1, result)
  call winrestview(view)
endfunction
```

まず、最初の行はバッファ全体を取得してコマンドに流し込み結果を取得というのをバッファを壊さずに行っています。[^shell-portable]
コマンドだと問答無用でバッファが書き換わりますが、スクリプトだと `v:shell_error` でコマンドの返り値を取得できます。
コマンドが異常終了している場合、`result`はエラーメッセージとみなせるので各行ごとに[:echoerr](https://vim-jp.org/vimdoc-ja/eval.html#:echoerr)で出力します。^[結合して出力すると改行が`^@`で表示されます]
正常終了している場合は、まず[winsaveview()](https://vim-jp.org/vimdoc-ja/builtin.html#winsaveview%28%29)を使い、画面の表示情報(どこまでスクロールしてるか、カーソルがどこにあるか)を保存します。
その上で[deletebufline()](https://vim-jp.org/vimdoc-ja/builtin.html#deletebufline%28%29)と[setline()](https://vim-jp.org/vimdoc-ja/builtin.html#setline%28%29)でバッファをコマンドの結果に置き換えた後、[winrestview()](https://vim-jp.org/vimdoc-ja/builtin.html#winrestview%28%29)でカーソル位置などを元に戻します。

後は各ftpluginに `nnoremap <buffer> mf <Cmd>call vimrc#feat#format#execute('nixfmt')<CR>` のように書いて使っています。

数分で書いた割に結構便利に使えています。

[^shell-portable]: [systemlist()](https://vim-jp.org/vimdoc-ja/builtin.html#systemlist%28%29)は雑にコマンドを実行してくれて入力もいい感じに扱ってくれますが、シェルの影響を受けるためあまりポータブルとは言えません。筆者は`config.fish`にうっかりechoを書いてしまい出力に混ざるというやらかしをしてしまったことがあります。
