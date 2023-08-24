---
title: "大体十行くらいでcmdwinっぽく振る舞うウィンドウを作る"
emoji: "⌨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vim"]
publication_name: "vim_jp"
published: true
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2023年8月25日の記事です。

# q:

Vimの便利機能の1つにコマンドラインウィンドウという物があります。`:`相当の起動のためのキーシーケンスが`q:`になっており、`:q`の誤爆で出てくるので使ってなくても見たことある方は多いのではないかと思います。

この機能は、各種コマンドラインの履歴を完全なVimのバッファとして提供してくれ、その中ではノーマルモードでできることが一通り全てできます。つまり履歴を編集するのにコマンドラインモードにいる必要がなく、Vimの機能をフル活用できるのです。

しかしながら、`It is a special kind of window`と書いてある通り、特殊なウィンドウになっていて制約が強く[^1]、ウィンドウを作り出す自動補完プラグインなどはまず動きません[^2]。慣れてる物は使いたくなるものです。幸いVimにはコマンドライン履歴を操作する`histnr()`、`histget()`、`histadd()`と言った関数やコマンドを実行するための方法が存在するため再現すること自体は可能なはずです。

# i

というわけでサクッと実装しました。

```vim
function! s:execute() abort
  let s:cmd = getline('.')
  tabclose
  autocmd CmdlineEnter * ++once call setcmdline(s:cmd)
  call feedkeys(":\<CR>", s:cmd =~# '^:' ? 'n' : 'nt')
endfunction

-tabnew
setlocal buftype=nofile bufhidden=hide noswapfile syntax=vim
let s:hist = range(histnr(':'), 0, -1)->map('histget(":", v:val)')->filter('!empty(v:val)')
call setline(2, s:hist)
nnoremap <buffer> <nowait> <CR> <Esc><Cmd>call <SID>execute()<CR>
inoremap <buffer> <nowait> <CR> <Esc><Cmd>call <SID>execute()<CR>
```

タブが開いてコマンドラインの履歴が並びます。適当に編集して確定すると実行できます。便利ですね。
怠惰なのでこの機能自体は関数にしてません。適当にファイルに保存してsourceしましょう。

```
nnoremap <Space><Space> <Cmd>source ~/.vim/bundle/cmdwin.vim<CR>
```

# :h

これで終わっても何のこっちゃという感じなので適当に解説します。
先頭にexecuteという関数がありますが、一旦飛ばします。

```vim
-tabnew
```

行数を減らして横着するには極力何かを戻す動作を減らす必要があります。つまり復元するレイアウトが無ければいいのです。そこで使えるのはpopup/floatwinもしくはtabになります。 ですが、popupwinは中を編集できず、floatwinは中に入れるものの召喚するのに手間が必要ということで却下。後はtabです。

tabであればtab自身のレイアウトもクソも無いので1行で召喚できます。そして、tabは通常カレントの右に現れ、閉じると右のtabが選択されます。これでは閉じる度に右に移動してしまいます。復元するには右に移動したかも調べる必要があります。これも面倒臭いですね。閉じる方は工夫できないので開く方を工夫します。

`:h tabnew`の結果を読むと、`-tabnew`をすると手前に開くと書いてあります。これで閉じるコードが`tabclose`だけで済むようになりました。
間違って開いた際もタブを閉じると元通りです。

```vim
setlocal buftype=nofile bufhidden=hide noswapfile syntax=vim
```

`:h scratch-buffer`に載ってることそのまんまです。ついでにVim scriptのsyntax定義を適用しています。
本当はこれを適用したバッファは適切に始末しなくてはならないのですが、私がVimを頻繁に落とすタイプなので横着をしています。


```vim
let s:hist = range(histnr(':'), 0, -1)->map('histget(":", v:val)')->filter('!empty(v:val)')
```

これがcmdwinとして肝心な部分です。
本来のcmdwinではバッファの一番下が新しいですが、今回はtabにする以上、一番上に配置されている方が都合がいいです。これは`histget()`で取れる値とは順番が逆なので、何かしらの方法で逆にしてやる必要があります。それを踏まえて、やってることを書いていきます。

まずは`range(histnr(':'), 0, -1)`の部分で、履歴の個数分のrangeを含むリストを作ります。新しい履歴ほど番号が大きいため、一発で上から新しい順に並べるため逆順のrangeにしています。
次に`map('histget(":", v:val)')`の部分でrangeの数値を元に履歴を取得していきます。
取得した履歴は空白も含まれるため(cmdwinは取り除いている模様)`filter('!empty(v:val)')`を適用して取り除きます。

```vim
call setline(2, s:hist)
```

取得した物を実際にバッファに埋めます、中身はこれで完成です。`setline()`は実際に存在する行+1まで使うことができ、この際は行末に挿入されます。こうすることで、入力用のスペースが空きます。

```vim
nnoremap <buffer> <nowait> <CR> <Esc><Cmd>call <SID>execute()<CR>
inoremap <buffer> <nowait> <CR> <Esc><Cmd>call <SID>execute()<CR>
```

最後は行の実行です。`<CR>`で始まるマッピングがあると面倒なので`<nowait>`を付けています。
`<Esc>`で挿入モードを解除してから実行に移ります。ノーマルモードの方は必要ないのですが、面倒なので合わせて付けてます。

```vim
function! s:execute() abort
  let s:cmd = getline('.')
  tabclose
  autocmd CmdlineEnter * ++once call setcmdline(s:cmd)
  call feedkeys(":\<CR>", s:cmd =~# '^:' ? 'n' : 'nt')
endfunction
```

行頭に置いていたこれが、コマンドを実行するための関数になります。
実はここの処理を書くのに一番苦労しました。後半部分の黒魔術っぽいコードがそれなんですが、これは制御文字などをそのままコマンドラインに突っ込んだ上でユーザーが打ってるように見せかけるための細工です。コマンド実行の際の一部の振る舞いが、このように実行することでしか再現できないためcmdwinと同じ振る舞いをするにはこうするしかありません。

より詳しく書くと、Vimはユーザーがコマンドを実際に打っていると判断すると(ユーザーが`:`や`<CR>`を含め、1文字でも実際に打たれた物の一部を入力しているという条件)通常のコマンド実行に加えて以下の動作を行います。

- コマンドライン履歴への登録
- `:`レジスタへの記録

このうち履歴は`histadd()`で書き込めるのですが、レジスタの方はこのプロセスか、もしくは実際のcmdwinを開いて実行することでしか書き込めません。後者も実際に試してみたのですが、制御が困難なため採用しませんでした。

上記のコードは`feedkeys()`という入力を捏造する関数で、「コマンドラインを開いて実行する」という命令を実際にユーザーが打ったかのように(第二引数の`t`が肝)送り付け、コマンドラインを開いた直後に実行される物をセットするようにフックをかけて、上記のプロセスを再現しています。

こうすることで、あたかもcmdwinであるかのように振る舞うウィンドウが作れるわけです。
私はこの後に補完プラグインのセットアップなどを書いて使っていました。[^3]

# :q

Vim自体の完成度が高いため、ここまで手を抜いてもプラグインとして成立する。あるいはこの程度の規模のプラグインでも結構色々考えてるということを伝えたかったです。
これを見た誰かがプラグインを作るきっかけになったのなら、私は嬉しいです。
Have fun :)

[^1]: 該当のウィンドウを編集する以外のほとんどのことができない。これは`'cedit'`によりスクリプトの実行中の`input()`などからも呼び出せるが故の制約だと思われる。
[^2]: 組み込み補完は普通に動作する。また、Neovimでは[cmdwin内からウィンドウを開けるようにするパッチ](https://github.com/neovim/neovim/pull/24457)が適用されているためその限りではない。私が使っているddc.vimはこのパッチ以降動作するようになっている。
[^3]: 実際に使っていた物は[ここ](https://github.com/kuuote/dotvim/blob/e4bc4b1967fccf273517a1fd2652c5c0020534f8/bundle/cmdwin.vim)に置いている。
