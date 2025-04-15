---
title: "ddu.vimをどう使っているか 最近使ったファイル編"
emoji: "🖤"
type: "tech"
topics: ["vim", "denops"]
publication_name: "vim_jp"
published: true
---

[Neovimのファジーファインダーtelescope.nvimでよく使っているpicker集](https://blog.atusy.net/2025/03/25/nvim-telescope-pickers/)という記事(と作者の発言「みんなも任意のFFの推しソースの紹介書いてくれよな！」)を読んだり、先日[vim-jp Slack](https://vim-jp.org/docs/chat.html)の`#tech-shougoware`で「他の人の使い方参考にしたいよね、新たなアイディアが生まれるかもしれない」という話を聞いたりして、確かに人々のワークフロー見てみたいなあと思ったので、言いだしっぺの私から書いてみることにしました。

~~長いと書く方も読む方も飽きるので~~ 程良い長さの記事の方が読みやすいので何回かに区切って書こうと思います。初回は「最近使ったファイル編」です。

# 最近使ったファイルとはなんぞや？
本記事では、開いたファイルを時系列で記録し一覧する機能及びそのインターフェースを指します。例えば、Windowsユーザーであればスタートメニューの中にあるので使ったことがあるかもしれません。
開いたファイル、つまり関心のあるファイルが時系列に並んでいるので作業の再開をしたりする際に有用です。

# Vimにおける最近使ったファイル
Vimは組み込みでこの機能を持っており[v:oldfiles](https://vim-jp.org/vimdoc-ja/eval.html#v:oldfiles)という変数を通じてアクセスできます([この値を使用したddu source](https://github.com/Shougo/ddu-source-file_old)もあります)。しかしこの値は記述の通り起動時にviminfoから読み込まれる値でしかなく、単体ではそこまで使い勝手がいいものではありません。起動中も使うにはbuffer sourceなどと組み合わせるという手がありますが、私は複数のVimインスタンスを同時に立ち上げて作業をするスタイルなので、この手は選びませんでした。

# vim-mr
- 複数インスタンス間でデータを共有でき、齟齬が発生しない
- Vim scriptからアクセスできる
- 余計なことをせずシンプル
  - 中には頻度まで記録する物もあるが、反射で操作することがある以上は挙動の予測が困難な物は好みではない
  - UIも別にいらない

上記の要件を全部満たした実装が欲しくて適当に作ってる最中に完全に要件を満たした[vim-mr](https://github.com/lambdalisue/vim-mr)というプラグインを見つけたのでそれを使っています。
このプラグインは以下の要素を記録し、API経由でファイルリストを取得できます。
- MRU - 最近使ったファイル
- MRW - 最近書き込んだファイル
- MRR - 最近使ったファイルが属するGitリポジトリ
- MRD - 最近chdirしたディレクトリ

これの出力をddu.vimに流し込んでやると([ddu-source-mr](https://github.com/kuuote/ddu-source-mr)を作って使っています)ddu.vimで行える操作を全て行えるようになります。

:::details お試し設定を置いておきます
```vim
set nocompatible
if has('nvim')
  let s:path = expand('~/.local/share/nvim/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim')
else
  let s:path = expand('~/.vim/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim')
endif
if getftype(s:path) !=# 'file'
  call system(printf('curl -fLo %s --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim', s:path))
endif
packadd vim-jetpack
call jetpack#begin()
Jetpack 'https://github.com/tani/vim-jetpack'
Jetpack 'https://github.com/vim-denops/denops.vim'
Jetpack 'https://github.com/Shougo/ddu-kind-file'
Jetpack 'https://github.com/Shougo/ddu.vim'
Jetpack 'https://github.com/Shougo/ddu-ui-ff'
Jetpack 'https://github.com/lambdalisue/vim-mr'
Jetpack 'https://github.com/kuuote/ddu-source-mr'
call jetpack#end()

call ddu#custom#patch_global('ui', 'ff')

autocmd FileType ddu-ff nnoremap <buffer> <CR> <Cmd>call ddu#ui#do_action('itemAction', {'name': 'open'})<CR>
autocmd FileType ddu-ff nnoremap <buffer> c <Cmd>call ddu#ui#do_action('itemAction', {'name': 'cd'})<CR>

nnoremap mru <Cmd>call ddu#start({'sources': [{'name': 'mr', 'params': {'kind': 'mru'}}]})<CR>
nnoremap mrw <Cmd>call ddu#start({'sources': [{'name': 'mr', 'params': {'kind': 'mrw'}}]})<CR>
nnoremap mrr <Cmd>call ddu#start({'sources': [{'name': 'mr', 'params': {'kind': 'mrr'}}]})<CR>
nnoremap mrd <Cmd>call ddu#start({'sources': [{'name': 'mr', 'params': {'kind': 'mrd'}}]})<CR>
```
Vim/Neovim及びDenoが導入された状態で上記vimrcを読み込んでJetpackSyncを叩いて再起動するとmru,mrw,mrr,mrdというマッピングが作成され、これを叩くとddu.vimが起動します。
この状態で`<CR>`を叩くとファイルが開かれ、`c`を叩くとディレクトリに対してchdirを行えます。
:::

# プロジェクト単位で最近書き込んだファイルをやりたい
[ddu-source-file_rec](https://github.com/Shougo/ddu-source-file_rec)や[ddu-source-file_external](https://github.com/matsui54/ddu-source-file_external)などのソースを使えば特定のディレクトリ以下のファイルの一覧を再帰的に収集できます。
そしてファイルの変更日時はファイルシステムに記録されているので、それを利用してソートをすることで特定のディレクトリ以下のファイル一覧を最近書き込んだ順で得られます。([ddu-filter-sorter_mtime](https://github.com/kuuote/ddu-filter-sorter_mtime)を作って使っています)
なお、上記のvim-mrのように別で記録しているわけではないため、この方法はVim以外で作成したファイルにも使えます。

![project_mrw](/images/2025-04-16_sorter_mtime.png)

これは実際に動かしてみている図です。今編集している記事のファイルが一番上に並んでいます。
ddu.vimは、このように組み合わせを自分で作って工夫できるので、ハマるととても楽しいです。

:::details お試し設定
```vim
if has('nvim')
  let s:path = expand('~/.local/share/nvim/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim')
else
  let s:path = expand('~/.vim/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim')
endif
if getftype(s:path) !=# 'file'
  call system(printf('curl -fLo %s --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim', s:path))
endif
packadd vim-jetpack
call jetpack#begin()
Jetpack 'https://github.com/tani/vim-jetpack'
Jetpack 'https://github.com/vim-denops/denops.vim'
Jetpack 'https://github.com/Shougo/ddu-kind-file'
Jetpack 'https://github.com/Shougo/ddu-source-file_rec'
Jetpack 'https://github.com/Shougo/ddu-ui-ff'
Jetpack 'https://github.com/Shougo/ddu.vim'
Jetpack 'https://github.com/kuuote/ddu-filter-sorter_mtime'
call jetpack#end()

call ddu#custom#patch_global('ui', 'ff')
call ddu#custom#patch_global('sourceOptions', {'file_rec': {'sorters': ['sorter_mtime']}})

autocmd FileType ddu-ff nnoremap <buffer> <CR> <Cmd>call ddu#ui#do_action('itemAction', {'name': 'open'})<CR>

nnoremap <CR> <Cmd>call ddu#start({'sources': [{'name': 'file_rec'}]})<CR>
```
Vim/Neovim及びDenoが導入された状態で上記vimrcを読み込んでJetpackSyncを叩いて再起動すると`<CR>`というマッピングが作成され、これを叩くとddu.vimが起動し、起動したディレクトリ以下にあるファイルが最近書き込んだ順に列挙されます。
この状態で`<CR>`を叩くとファイルが開かれます。
:::

# :q
MRUは性質上、リストの1番目または上方の候補をそのまま選びますが、ノーマルモードで立ち上がるddu.vimでは自然に行えるため便利です。
また、上記の設定例は最低限しか書いていませんが、私は例えば[ddu-filter-matcher_substring](https://github.com/Shougo/ddu-filter-matcher_substring)や[ddu-filter-fzf](https://github.com/yuki-yano/ddu-filter-fzf)などの順序が残る絞り込みフィルターと組み合わせて絞り込んで使うこともあります。

ddu.vimは自分で全て設定を書く必要があり、難しい、敷居が高いなどの声がよく聞かれますが、上記の設定(は少なすぎますが)を見ると分かる通り、必要な物だけを書けるので使い方次第では意外と量が少なくシンプルな設定になります。

また、設定の自由度が高いため、思い付いたこと(例えば上記の`file_rec`と`sorter_mtime`を組み合わせるなど)を大抵実現できます。

ddu.vimに興味を持たれた方は[作者の記事](https://zenn.dev/shougo/articles/ddu-vim-beta)などを読んでみて頂ければ幸いです。
