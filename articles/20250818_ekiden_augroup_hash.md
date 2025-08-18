---
title: "Vimのaugroup名に `#` は使ってはいけない"
emoji: "#️⃣"
type: "tech"
topics: ["vim"]
publication_name: "vim_jp"
published: true
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2025-08-18の記事です。
前回の記事は[Sirasagi62](https://zenn.dev/sirasagi62)さんの[イケてるGo版JSX,templを知っているか!?(feat. neovimでの設定)](https://zenn.dev/sirasagi62/articles/0f873debabf232)でした。フロントやってなくて使ったことはないですが面白い見た目だなと思いました。

私は vimrc で使う augroup の一部に `vimrc#ddu` みたいな `#` 区切りを使っていました。これは autoload 関数からの着想です。
単純に augroup として使うだけならこれは上手く行きます。しかし `exists()` の help を見ると次のように書いてあります。[^vimdoc-ja]

```
#event		このイベントに対する自動コマンド定義
#event#pattern	このイベントとパターンに対する自動コマ
        ンド定義(パターンは文字そのままに解釈
        され、自動コマンドのパターンと1文字ず
        つ比較される)
#group		自動コマンドグループが存在するか
#group#event	このグループとイベントに対して自動コマ
        ンドが定義されているか
#group#event#pattern
        このグループ、イベント、パターンに対す
        る自動コマンド定義
##event		このイベントに対する自動コマンドがサ
        ポートされているか
```

これを見ると明らかにパターン区切りと記号が衝突しています。まあ vimrc だし大丈夫かーと思っていたのですが、先日[vimrc読書会](https://vim-jp.org/reading-vimrc/)で[Omochiceさんのvimrc](https://github.com/omochice/dotfiles)を読んでいた際に同じようなタイプの augroup 名を使われてるのを見て、これ大丈夫なのかという話になりました。
駅伝のネタにもなるんじゃない？という話もあり検証してみたら初手でこれはやっちゃだめなパターンだということが分かりました。[^anti]

具体的には

```vim
augroup vimrc#test
  autocmd!
  autocmd User test echo 42
augroup END
augroup vimrc.test
  autocmd!
  autocmd User test echo 42
augroup END
echo exists('#vimrc#test')
echo exists('#vimrc.test')
```

こちらの Vim script の結果が

```
0
1
```

となり、両方とも 1(真)を期待したいのですが、明らかに結果が違います。
上のケースは恐らく `#event#pattern` ないしは `#group#event` として処理されています。

`exists()` で使えないので `#` は使ってはいけないということがわかりました。いかがでしたか？ :q

[^vimdoc-ja]: [vimdoc-ja](https://github.com/vim-jp/vimdoc-ja)の翻訳をお借りしています
[^anti]: 執筆時点ではこの話は書いていませんが、vimrc読書会でよく見る失敗をまとめた[vimrcアンチパターン](https://github.com/vim-jp/reading-vimrc/wiki/vimrc%E3%82%A2%E3%83%B3%E3%83%81%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3)というまとめがあります
