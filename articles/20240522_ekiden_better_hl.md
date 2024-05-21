---
title: "HとLをいい感じにするマッピングをvimrc読書会で見つけたので魔改造してみた"
emoji: "↕"
type: "tech"
topics: ["vim"]
publication_name: "vim_jp"
published: true
---

この記事は、[Vim駅伝](https://vim-jp.org/ekiden/)の2024年5月22日の記事です。

[vimrc読書会](https://vim-jp.org/reading-vimrc/)で、[habamaxさんのvimrc](https://github.com/habamax/.vim)を読んでいた時に、[面白いマッピング](https://github.com/habamax/.vim/blob/54756e195b175f18de8f3b230612fa356c39c73a/plugin/mappings.vim#L134-L153)を見付けました。

```vim
vim9script
# better PgUp/PgDn
def MapL()
    var line = line('.')
    normal! L
    if line == line('$')
        normal! zb
    elseif line == line('.')
        normal! zt
    endif
enddef
def MapH()
    var line = line('.')
    normal! H
    if line == line('.')
        normal! zb
    endif
enddef

noremap L <ScriptCmd>MapL()<CR>
noremap H <ScriptCmd>MapH()<CR>
```

![a](/images/20240522/a.webp)

このように、このマッピングは、`H`や`L`を実行し、カーソルが動かなければページをずらすという動きを、`L`についてはファイルの末尾だと表示の調整をします。


この`H,L`と`<PageUp>,<PageDown>`[^pagedown]を合わせるというアイデアは面白いものの、双方が交互に働くため連続でページ移動したい時に打鍵数が増えてしまい、あまり嬉しくありません。
なので、自分が使いやすいように次に示すように考えて改善することにしました。

- ページ移動が行われた際にカーソルを寄せれば連続でページ移動ができるのではないか
- 末尾の表示調整は欲しいけど一発で実行された方が嬉しい
  - サクラエディタでページスクロールをする際、末尾に差し掛かると表示位置だけが動くのが理想的
- ついでに移動した際に桁位置リセットしたいよね

というのを盛り込んだ結果こうなりました。

![b](/images/20240522/b.webp)

```vim
" based from https://github.com/habamax/.vim/blob/5ae879ffa91aa090efedc9f43b89c78cf748fb01/plugin/mappings.vim?plain=1#L152
" HLとPageDown/PageUpを共用する
function s:pagedown() abort
  let line = line('.')
  let topline = winsaveview().topline
  normal! L
  if line == line('.')
    " 末尾にいたらPageDown
    normal! ztL
  endif
  if line('.') == line('$')
    " 行末に来たらウィンドウの末尾と最下行を合わせる
    normal! z-
    if winsaveview().topline != topline
      " サクラエディタ風の挙動
      " 既に行末にいる場合以外は元の行末にカーソルを置く
      execute line
    else
    endif
  endif
  normal! 0
endfunction

function s:pageup() abort
  let line = line('.')
  let topline = winsaveview().topline
  normal! H
  if line == line('.')
    " 先頭にいたらPageUp
    normal! zbH
  endif
  let newtopline = winsaveview().topline
  if newtopline == 1 && topline != newtopline
    " 上と同じく
    execute line
  endif
  normal! 0
endfunction

nnoremap <Space>j <Cmd>call <SID>pagedown()<CR>
nnoremap <Space>k <Cmd>call <SID>pageup()<CR>
```

元々`H`や`L`は使ってなくて潰していたくらいなんですが、見た位置に飛べるというのは思いの外便利で、実装してみてよかったと思います。

[^pagedown]: 厳密には違いますが、似たような動きです。
