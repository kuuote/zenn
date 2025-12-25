---
title: "Vim scriptで値を隠蔽する"
emoji: "🔐"
type: "tech"
topics: ["vim"]
publication_name: "vim_jp"
published: true
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2025-12-26の記事です。
前回の記事は[kyoh86](https://zenn.dev/kyoh86)さんの[NeovimからCodexを呼び出してコードの補完を提案してもらう](https://zenn.dev/vim_jp/articles/8badce9ef420e7)でした。Codex使いとしては気になるので後ほど試してみようと思います。

---

私は最近Nostrにハマっているのですが、このNostrでは公開鍵暗号を使用して個人を識別します。つまり、絶対に秘匿しなければならない、変更できない鍵のみが個人を識別するために必要な物となります。

1VimmerとしてはVimでNostrをやりたくて仕方がないのですが、それをやるにはVim scriptで絶対に漏らせない秘密鍵を扱う必要があります。

:::message
実の所、denopsなどの外部で値を隠せる手段を利用したら楽なのですが、今回は割愛します。
:::

---

Vim scriptにおいて値を格納する方法は2つ、グローバル変数やバッファ等に紐付いたローカル変数とスクリプトローカル変数となります。

グローバル変数などは言わずもがな、スクリプトローカル変数についても簡単に取り出すことはできないですが、Vim scriptのスクリプト管理がファイルパスをキーとしているため、ファイルを退避した上で当該スクリプトを変数を取得するだけの物に置き換えて読み込ませ、更に元に戻す、といった手段を取ることで取り出せます。[^vital]

これでは打つ手なしと思われますが、Vim scriptにはclosureという機能が存在します。

# closure

[closure](https://vim-jp.org/vimdoc-ja/eval.html#closure)もしくは[:func-closure](https://vim-jp.org/vimdoc-ja/userfunc.html#:func-closure)は、一般には関数閉包とも言われ、関数の参照(Vimにおいてはfuncref)を作る際に外側のスコープを閉じ込めた物です。閉じ込められた値は関数が呼ばれた際に関数の中からのみアクセスできます。

```vim
function SetKeyLambda(key)
  let s:gethash = {->sha256(a:key)}
endfunction

function SetKeyFunction(key)
  function s:_gethash() closure
    return sha256(a:key)
  endfunction
  let s:gethash = funcref('s:_gethash')
endfunction

function GetHash()
  return s:gethash()
endfunction
```

このようにしてやると万一スクリプトローカル変数にアクセスされても、keyにsha256をかけるfuncrefしか取得できなくなります。

今回はsha256しかかけていませんが、繋ぐ先を署名器にしてやれば安全に署名したりできるはずです。これはとても便利ですね。

:::message alert
繋ぐ先を普通のVim script関数にしてしまうとそこを置き換えられてしまうため、注意して扱う必要があります。
いずれにせよVim scriptは何でもできる言語なので悪意あるコードには注意すべきだと筆者は考えます。
また、値は平文でメモリに載るためデバッガで割り込みをかける等の手段で頑張れば見ることができます。
そのため、万が一にでも漏らしたらいけない値に対しては別の手段を検討した方がいいと思います。
:::

[^vital]: vital.vimには[これをするモジュール](https://github.com/vim-jp/vital.vim/blob/master/autoload/vital/__vital__/Vim/ScriptLocal.vim)が存在します。
