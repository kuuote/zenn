---
title: "Vimで素早く作業を再開する"
emoji: "⤴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vim"]
published: true
---

:::message
この記事は [Vim Advent Calendar 2022(その2)](https://qiita.com/advent-calendar/2022/vim) の 11 日目の記事です
:::

私は普段テキストを編集するのにVimを使っています。このエディタは一瞬で起動するので[^1]作業の区切りなどにカジュアルに終了させています。こうするとエディタの内部に状態が溜まらずいつも同じ状態で作業ができるので気持ちがいいのですが、作業の状態は全て吹き飛んでしまいます。
毎回作業の再開の度にファイルを開き直したりするのは大変ですが、幸いVimには最後に作業していた場所に飛ぶために使える機能がいくつかあるので紹介します。ついでに私が使ってるプラグインを使った方法も少し書いておきます。

# 組み込み機能

## session

今回紹介する機能の中では分かりやすい方だと思います。
タブごとに何を開いてるのか、どの位置にウィンドウがあるのか等の情報を再現するためのスクリプトを作成してくれます。
デフォルトでかなり多くの情報を保存してくれるのですが、プラグインを使っていると残念ながら競合してしまいます。設定で調整はできるのですが、そこまで必要なことをあまりしていなく私は使っていません。設定さえちゃんと書けば便利だと思います。

## oldfiles

いわゆる「最近使ったファイル」です。前回に終了した時までに開いていたファイルが起動時に読み込まれ、`:browse oldfiles`でアクセスできます。便利な機能ではあるのですが、起動時の状態で固定されてしまうなどの欠点もあります。私は似たような事を行うMRUプラグインを導入して使っています。

![oldfiles](/images/vimadvent2022/oldfiles.png)
スクリーンショットにも映っていますが、プラグインの作る一時的なバッファが記録されてしまうという欠点もあります。

## mark

マークはカーソルの位置を手動または自動(特殊なマークの場合)で記録してその位置にジャンプできる機能ですが、特殊なマークの1つにバッファを抜けた際の位置が自動で記録される物があります。(`'"`)手で飛んでもいいですが、`:h last-position-jump`で紹介されている方法を使うとバッファを開いた瞬間にこの位置まで移動できるようになります。[^2]

```vim
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif
```

`oldfiles`と組み合わせると一瞬で元々開いていた場所に飛べます。

## changelist

Vimはファイルが編集される度、変更された位置を記録しています。組み込みでジャンプコマンド(`g;`と`g,`)が存在している他、終了した時にもこの位置リストは記録されるため、最後に編集していた位置というより関心の高いであろう場所にも一瞬で飛べます。

# プラグイン編

## mr.vim

https://github.com/lambdalisue/mr.vim
MRU(Most Recently Used, 最近使った物)を実現するためのプラグインとして私はmr.vimを使っています。このプラグインは以下の3種類の情報を記録してくれます。
- MRU (Most Recently Used files)
- MRW (Most Recently Written files)
- MRR (Most Recent git Repositories.)

どれも有用なのですが、私は2番目のMRWを中心に使っています。最近使ったファイルだと開いただけのファイルも記録されていますが、最近書き込んだファイルだと、編集したファイルという取り分け関心の高い物が並んでおり、かなりの正確さで欲しい物にアクセスできると感じます。[^3]

このプラグインはUIを提供しておらず、公式には[mr-quickfix.vim](https://github.com/lambdalisue/mr-quickfix.vim)が存在しますが、私は[ddu.vim](https://zenn.dev/shougo/articles/ddu-vim-beta)と組み合わせて使うための[ソース](https://github.com/kuuote/ddu-source-mr)を自作して使っています。[^4]

![ddu.vim](/images/vimadvent2022/ddu.png)

## gin.vim

https://github.com/lambdalisue/gin.vim
こちらもmr.vim同様ありすえさん作のプラグインでgitリポジトリを操作するための機能を提供する物になります。(gin.vimは開発中のため前身である[gina.vim](https://github.com/lambdalisue/gina.vim)の方がいいかもしれません)その中の機能の1つ、`GinDiff`を使うとdiffの存在する場所、即ち編集した場所に素早く飛べます。

![gin.vim](/images/vimadvent2022/gin.png)

見た目は普通のdiffバッファですが、飛びたい位置にカーソルを載せてEnterを押すことでファイルのdiffの指す位置に飛べます

## ddu-source-git_diff

https://github.com/kuuote/ddu-source-git_diff
![ddu-source-git_diff](https://raw.githubusercontent.com/kuuote/files/main/ddu-source-git_diff.png)

上に書いた`Gindiff`相当の機能をddu.vimのソースとして実装したものです。安定性はgin.vimには及ばないとは思いますが、プレビューやアクションなどのddu.vim由来の機能を利用できます。

[^1]: 設定によります。プラグインを導入すると一般には遅くなりますが、高速化に興味がある方は[3日目のdelphinusさんの記事](https://qiita.com/delphinus/items/fb905e452b2de72f1a0f)などを読むといいと思います。
[^2]: defaults.vimに記述されているためvimrcを書かないかdefaults.vimを読み込む設定を書くと有効化されます。このスクリプトはそれなりに設定を変えてしまうので、vimrcを書く場合はvimrcの中に直接このautocmdを書いた方がいいと思います。
[^3]:このMRWというアイデアは元々rbtnnさんの[vim-mrw](https://github.com/rbtnn/vim-mrw)というプラグインで実装されていた物です
[^4]:oldfilesソースとbufferソースを組み合わせると再現できそうな気もしているので自由研究の課題にしておこうと思います
