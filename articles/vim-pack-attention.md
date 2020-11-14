---
title: "Vimのpackages機能を使う上での注意点"
emoji: "📦"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["vim"]
published: true
---

# はじめに
Vim 8 や Neovim には [packages](https://vim-jp.org/vimdoc-ja/repeat.html#packages) と呼ばれる組み込みのパッケージ管理機構が存在しています。これを使えば、プラグインマネージャーを導入せずとも所定の位置[^1]にプラグインを配置するだけで Vim が起動時に読み込んでくれるようになります。
ですが、仕組みが他のプラグインマネージャーと異なりいくつかハマりどころがあるので紹介しようと思います。

# 機能がシンプル
現代的なプラグインマネージャーは、必要なプラグインを宣言的に定義する、GitHub 等からプラグインを自動でインストールや更新する、更新された際に特定のコマンドを実行する、特定のマッピングやコマンドが実行されるタイミングまでプラグインのロードを遅らせる[^2]等の機能を持っていますが、packages にはそれらの機能は一切ありません。
存在するのは `{packpath}/{name}/start` 以下のプラグインを一括でロードする機能と `{packpath}/{name}/(start|opt)` 以下のプラグインを [:packadd](https://vim-jp.org/vimdoc-ja/repeat.html#:packadd) を実行したタイミングで読み込む機能だけになります。
そのため、それらの機能が欲しい場合は、自力で頑張って構築するか、[k-takata/minpac](https://github.com/k-takata/minpac) や [bennyyip/plugpac.vim](https://github.com/bennyyip/plugpac.vim) (先述した minpac のラッパープラグイン)等のプラグインマネージャーを別途使うことになります。

# 読み込まれるタイミングが他のプラグインマネージャーと違う
他のプラグインマネージャーから移行してきた人(特に minpac 等の他のプラグインマネージャーとインターフェースが似ている物を使う場合)がハマりがちなのですが、プラグインが読み込まれるタイミング自体(厳密には ['runtimepath'](https://vim-jp.org/vimdoc-ja/options.html#'runtimepath') に追加されるタイミング)が他のプラグインマネージャーより遅いです。
ほとんどのケースでは問題は起きませんが、設定で autoload 関数を使うプラグイン[^3]だと、設定の段階では ['runtimepath'](https://vim-jp.org/vimdoc-ja/options.html#'runtimepath') にプラグインが追加されていないため見付けられずにエラーが発生します。そのため、 [:packadd](https://vim-jp.org/vimdoc-ja/repeat.html#:packadd) を使い、`packadd! vim-hogehoge` のように検索パスに追加してから設定をする必要があります。

# プラグインの抜き差しが面倒
minpac 等に移行してきた人が勘違いしがちですが、`call minpac#add('foo/bar')` のような記述をしても、minpac 等にどのプラグインの管理をしてほしいかの指示になるだけでプラグインの読み込みに一切影響しません。例えば、minpac はデフォルトで `start` 以下にプラグインを配置しますが、先述した通り minpac への指示を記述していようがいまいが Vim が一括で読み込みます。opt に導入するように指示することで抜き差しが可能になりますが、この場合も [:packadd](https://vim-jp.org/vimdoc-ja/repeat.html#:packadd) を別途実行する必要があります。

# カラースキームの opt 読み込みが上手くいかないケースがある
[:colorscheme](https://vim-jp.org/vimdoc-ja/syntax.html#:colorscheme) コマンドでカラースキームを設定する際、Vimは ['packpath'](https://vim-jp.org/vimdoc-ja/options.html#'packpath') 内の `opt` ディレクトリの中まで検索して見つかれば読んでくれますが、この際に ['runtimepath'](https://vim-jp.org/vimdoc-ja/options.html#'runtimepath') への追加はしてくれないため autoload 関数を使うカラースキームの場合エラーが発生します。先述の問題同様、こちらも事前に [:packadd](https://vim-jp.org/vimdoc-ja/repeat.html#:packadd) を実行する必要があります。

# おわりに
自分自身は[Shougo/dein.vim](https://github.com/Shougo/dein.vim)[^4]に乗り換えようと思っていますが、[packages](https://vim-jp.org/vimdoc-ja/repeat.html#packages) が駄目というわけではなく、あまり複雑な事をしない方やシンプルな物が好きな方にとっては必要十分な機能が揃っていると思います。この記事が何かの参考になれば幸いです。

[^1]: ['packpath'](https://vim-jp.org/vimdoc-ja/options.html#'packpath')で指定できます
[^2]: 遅延ロード自体は可能です
[^3]: 設定するのに `call foo#bar('hoge')` のような呼び出しをさせるようなプラグイン
[^4]: プラグインを大量に導入したりする人向けに作られており高機能なプラグインマネージャー
