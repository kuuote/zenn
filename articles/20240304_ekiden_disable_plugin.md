---
title: "Vim側の組み込みプラグインを無効化するハック"
emoji: "🔌"
type: "tech"
topics: ["vim"]
publication_name: "vim_jp"
published: false
---

# はじめに

Vim のカスタマイズをしていると~~主に netrw とか netrw とか netrw とか~~本体側に存在するプラグインが邪魔になることがあります。

正攻法で無効化する方法はいくつかありますが、それぞれ問題点もあります。

- 組み込みプラグイン自体を削除する
  - インストール時に細工をすることになるので行儀がいいとは言えない
  - 自力でビルドすることがほぼ前提となる
- `--noplugins` フラグを使う
  - 読み込んで欲しいプラグインを逆に列挙することになる
    - `:runtime` コマンドを使う
  - 起動する度にフラグを渡さなければならない
- `g:loaded_xxx` 変数を使う
  - プラグインの数だけ書く必要がある
  - 慣習でしか無いので行儀の悪い物(Neovim の組み込みがそう)があれば機能しない

そこでちょっとしたハックを使い、組み込みプラグインだけを無効化する方法を提案します。

# 実装と注意点

```vim
let s:save_rtp = &runtimepath
set rtp-=$VIMRUNTIME
autocmd SourcePre */plugin/* ++once let &runtimepath = s:save_rtp
```

こちらを vimrc の末尾に書けば機能します。ただし何でもいいのでユーザー側で `plugin` 以下に読み込まれるスクリプトを1つでも置く必要があります。

# 何をやっているのか

help の [load-plugins](https://vim-jp.org/vimdoc-ja/starting.html#load-plugins) を読むと分かりますが、Vimは vimrc の読み込みの直後に `:runtime! plugin/**/*.vim` を実行することによりプラグインの読み込みを行っています。
このコマンドは実行されたタイミングの ['runtimepath'](https://vim-jp.org/vimdoc-ja/options.html#'runtimepath') を参照し、その中から glob パターンにマッチするスクリプトを読み込みます。
そのため、その直前に Vim のランタイムディレクトリを `'runtimepath'` から抜くと本体側のプラグインは読み込まれません。しかし、ランタイムディレクトリにはプラグイン以外にも重要なスクリプトが存在しており、このままだと困ります。
そこで [SourcePre](https://vim-jp.org/vimdoc-ja/autocmd.html#SourcePre) イベントを使用し、なるべく早いタイミングで差し戻すことにより、副作用を防ぐというのがやりたいことになります。何かしらスクリプトが必要なのは SourcePre イベントを起こすためです。
