---
title: "vim.ui.selectの話(とdressing.nvimとか)"
emoji: "🔍"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["neovim"]
published: false
---

# yay

Neovimには`vim.ui.select`というAPIがあります。helpful.vimによると0.6.0からあるそうです。
何かを選んで、その対象に対して処理をするという、プラグインを書いていると割と欲しくなる処理を抽象化したものになります。

```lua
select({items}, {opts}, {on_choice})
```

fzfのVim script APIなどを叩いたことある人ならなんとなく見覚えのある定義をしていると思います。`items`にリストを渡し、それを何かしらのセレクターで選び、選んだ物が`on_choice`に渡される。そして`items`の扱いは`opts`に渡すパラメータにより制御される。といったインターフェースが定義されています。

# 使ってみる

```lua
vim.ui.select({ 'apple', 'banana', 'orange' }, {}, function(item, index)
  vim.cmd('redraw')
  print(('あなたは%d番目の%sを選択しました'):format(index, item))
end)
```

無設定のNeovimで上記のLuaスクリプトを実行してみます。個々の`item`の型は本来何でもいいのですが、`opts`に何も指定しない場合は文字列に変換されて表示されることになっているので今回はそのまま文字列を渡します。

![select](/images/nvim_ui_select/default1.png)

すると画面に指示が出てくるので指示に従って項目を選びます。試しに真ん中のbananaを選んでみようということで2と打って`<Enter>`を押してみます。すると画面に以下のように出力されます。

![banana](/images/nvim_ui_select/default2.png)

`on_choice`に渡した関数が実行されていること、選択した`item`の中身と番号がちゃんと渡されていることが分かります。

キャンセルもできます。が、nilが渡ってくるので上の例だと落ちてしまうため修正します。

```lua
vim.ui.select({ 'apple', 'banana', 'orange' }, {}, function(item, index)
  vim.cmd('redraw')
  if item == nil then
    print('キャンセルされた模様です')
  else
    print(('あなたは%d番目の%sを選択しました'):format(index, item))
  end
end)
```

これを走らせて指示に従い`q`と打つとこうなります。

![banana](/images/nvim_ui_select/default_cancel.png)

# で、これどこで使われてるの？

`vim.ui.select`はプラグインから使うのを想定したAPIなので基本的にはプラグインを導入するか自前でコードを書いて使うことになります。ですが例外として組み込みLSPのようなNeovimで追加された組み込みプラグインでも使われています。
導入方法については割愛しますが、適切にセットアップした上で先程のコードに対してCodeActionを発動すると上で直接呼んだ時のような表示が出ます。

![codeaction](/images/nvim_ui_select/default_codeaction.png)

# さあ、着替えよう

helpを見ると一部に`item shape. Plugins reimplementing vim.ui.select may wish to use this to infer the structure or semantics of items, or the context in which select() was called.`と書かれているように、このAPIはセレクターUIを提供するプラグインが置き換えることを前提として設計されています。というわけで早速置き換えてみます。
置き換えに使えるプラグインはいくつかありますが、今回は設定の簡潔さ、安定性、人気などの理由から[dressing.nvim](https://github.com/stevearc/dressing.nvim)を選びました。[^1]

```lua
-- addは適宜使用しているプラグインマネージャの物に読み替えてください
add('stevearc/dressing.nvim')
-- dressing.nvimはバックエンドが複数選べるが、とりあえずtelescopeを使ってみるので一緒に導入しておく
add('nvim-lua/plenary.nvim')
add('nvim-telescope/telescope.nvim')

require('dressing').setup {
  select = {
    enabled = true,
    backend = { 'telescope' },
  },
}
```

正しく導入できていれば呼び出した際の表示がこのようになります。

![dressing_telescope](/images/nvim_ui_select/dressing_telescope.png)

CodeActionもこうなります。注釈も出せるようになっており(`sumneko_lua`の部分)セレクターが対応していたら表示されます。

![dressing_telescope_codeaction](/images/nvim_ui_select/dressing_telescope_codeaction.png)

vim-lspの時はこの部分の入れ替えはできず`quickpick`固定だったため、個人的にはこれができるのはとても嬉しいです。

バックエンドは他にもあり、例えばちょっとした選択にファジーファインダーなんて仰々しい物は必要ないという人は`dressing.nvim`組み込みのメニューだけ提供するUIを選択したりもできます。(`backend`に`builtin`を指定すると使えます。普通にVimのバッファなので検索などのVimで使える移動手段で選択が可能です)

![dressing_builtin](/images/nvim_ui_select/dressing_builtin.png)


[^1]: telescopeであれば公式でtelescope-ui-select.nvimが提供されていますが、キャンセルした際に`on_choice`が呼ばれないという問題があったため導入を見送りました。dressing.nvimのtelescopeバックエンドであれば正しく呼ばれます。
