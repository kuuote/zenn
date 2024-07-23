---
title: "クリップボードを使わずにVimのインスタンス間でレジスタを共有する"
emoji: "📋"
type: "tech"
topics: ["vim"]
publication_name: "vim_jp"
published: true
---

この記事は、[Vim駅伝](https://vim-jp.org/ekiden/)の2024年7月24日の記事です。

Vim では yank(一般に言うコピーに当たる操作)したものは、Vim 内部のレジスタと呼ばれる格納域に保存されます。レジスタは Vim インスタンスのメモリに配置されるため、インスタンス間で独立しています。`viminfo` という仕組みにより保存はできますが、通常Vimの起動時にしか読み込まれません。
ですが、時にインスタンスを越えて共有したくなる時があります。一般的なデスクトップ環境では OS のクリップボードを使用してデータのやりとりができますが、時にクリップボードが使用できない環境があります。(例えば Linux ではクリップボードの動作を X11 に依存しているため SSH 先の Headless 環境等では利用できない)[^neovim]
本記事ではそういった環境でも Vim script 関数を使いファイル経由でレジスタを共有する方法を紹介します。

# getreginfo()
`getreginfo()` という関数を使うと、レジスタの中身と種類(char, line, block)を復元可能な形でダンプできます。
ダンプされた物は普通の Vim script の値なので `json_encode()` を通すと文字列に変換できファイルに書き出せる形になります。
後は `writefile()` に渡せば保存できます。
コードにするとこのようになります。

```vim
let s:path = '/tmp/vimyank'

function vimrc#feat#clipboard#save() abort
  call writefile([json_encode(getreginfo())], s:path)
  echo 'save register to clipboard'
endfunction
```

# setreg()
`setreg()` を使えば `getreginfo()` で取得したレジスタの内容をそのまま書き戻せます。
保存とは逆に `readfile()` と `json_decode()` を通して `setreg()` に渡します。
コードにするとこのようになります。

```vim
let s:path = '/tmp/vimyank'

function vimrc#feat#clipboard#load() abort
  call setreg(v:register, readfile(s:path)->join()->json_decode())
  echo 'restore register from clipboard'
endfunction
```

# mapping
後は適当にマッピングなりしてやれば完成です。

```vim
nnoremap <Space>p <Cmd>call vimrc#feat#clipboard#load()<CR>
nnoremap <Space>y <Cmd>call vimrc#feat#clipboard#save()<CR>
```

少々手間は増えますが、レジスタの共有に使える他にも不意にレジスタが破壊された時のための退避場所としても有用だと思います。

[^neovim]: Neovim はクリップボードの仕組みが柔軟なためそちらを利用できますが、気が向いたら追記します。
