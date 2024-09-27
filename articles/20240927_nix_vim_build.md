---
title: "NixOSで最新のVimをビルドする"
emoji: "❄"
type: "tech"
topics: ["nix"]
publication_name: "vim_jp"
published: true
---

# TL;DR🦌

https://zenn.dev/kawarimidoll/articles/0a4ec8bab8a8ba
全面的に上記の記事を参考にしておりNixOS用にまとめ直しているだけです。足りない情報は各自で補足して頂くか、あるいは私に文句を言えば生えてきます。
また、前提知識は断りなく省略しているため、以下の記事や[公式のマニュアル](https://nixos.org/learn/)を読むことをおすすめします。

https://zenn.dev/asa1984/books/nix-introduction
https://zenn.dev/asa1984/books/nix-hands-on

下記のような定義を `configuration.nix` に導入するとビルドできます。

```nix
let
  # pkgsがnixpkgsへの参照であることを仮定
  vim-latest = pkgs.vim.overrideAttrs (oldAttrs: {
    version = "latest";
    src = pkgs.fetchFromGitHub {
      owner = "vim";
      repo = "vim";
      # ビルドしたいタグあるいはコミットハッシュをrevに書く
      rev = "v9.x.xxxx";
      # 一度ビルドを走らせて、出力されたハッシュと置き換える
      # これはダミーハッシュを書いてるけど空文字列でもいい
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    # 以下は筆者がif_luaを使っているため定義しているので必要無ければ消して大丈夫
    configureFlags = oldAttrs.configureFlags ++ [
      "--enable-luainterp"
      "--with-lua-prefix=${pkgs.lua}"
      "--enable-fail-if-missing"
    ];
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.lua ];
  });
in
{
  environment.systemPackages = [
    vim-latest
  ];
}
```

# はじめに

Vimmer が新しい開発環境で一番重要視することは Vim のビルドができることです。[要出典]
Vim 自体のビルドは難しい物ではなく、一般的な環境では依存ライブラリさえ集めれば簡単にビルドを通せます。Linux 環境においてはツールチェーンの導入自体が容易なこともあり、基本的に困ることはありません。

しかし最近おすすめされて導入した NixOS では、構成が特殊なこともあり同じやり方では上手く行きません。筆者は、gcc や make が無い(nix で導入できる)、ncurses が見つからない(これも nix で導入できる)、Lua の組み込みが上手く行かない(nix で導入できるしライブラリは見つかるものの、起動時に SEGV する)などの現象に遭遇して心が折れ、同じ方法を取るのは諦めました。

そうなると、Nix のやり方に従ってパッケージを作成し、ビルドする必要があります。具体的に何をどうやればいいのかを紹介していきます。

# パッケージとは

Nix の世界においては原理上バイナリパッケージを区別するための仕組みが必要ないため[^substituter]、パッケージというのは全てビルド手順を記した Nix 式から生成される derivation を指します。
今回の最終目的は、Vim の最新版をビルドする derivation を作成することになります。

# パッケージの上書き

1 から書いてもいいのですが、既存の物を再利用するのが楽です。なので Nixpkgs にある Vim のパッケージを利用します。定義は[リポジトリ](https://github.com/NixOS/nixpkgs)から頑張って探すか、[公式提供されている検索](https://search.nixos.org/packages)を使ってSource経由でアクセスできます。
執筆時点では、[ここ](https://github.com/NixOS/nixpkgs/blob/944b2aea7f0a2d7c79f72468106bc5510cbf5101/pkgs/applications/editors/vim/common.nix)に定義があります。
今回はバージョンを切り替えればいいだけなので `version` 及び `src` 属性を上書きしたらいいです。
コピペしてもいいですが、折角なのでもっと筋のいい方法を取りましょう。
Nixpkgsのstdenvを使用して作成されたパッケージには、`override`や`overrideAttrs`などの便利なメソッドが生えています。今回は属性の上書きなので`overrideAttrs`を使用します。

```nix
pkgs.vim.overrideAttrs (oldAttrs: {
  version = "latest";
  src = pkgs.fetchFromGitHub {
    owner = "vim";
    repo = "vim";
    rev = "v9.x.xxxx";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
})
```

上記のように、元になるパッケージの AttrSet を受け取り、上書きする AttrSet を返す関数を渡すと、新しいパッケージが作成されます。


`version`については、ストアパスの生成にそのまま使われるため、古いバージョンのままだと混乱するため上書きするだけです。とりあえずlatestにしておいて大丈夫です。
`rec`指定子と組み合わせ、ビルドしたいバージョンをこちらに指定して`src`に渡すことも可能です。

```nix
pkgs.vim.overrideAttrs (oldAttrs: rec {
  version = "v9.x.xxxx";
  src = pkgs.fetchFromGitHub {
    owner = "vim";
    repo = "vim";
    rev = version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
})
```

`src`は元の定義では`fetchFromGitHub`というGitHubからソースツリーを引っ張ってくる関数を使用しているため、引き続きこちらを使用します。
こちらは nixpkgs で提供されるライブラリなので`pkgs.fetchFromGitHub`として参照できます。
以下のステップで書き換えます。

1. `rev`をビルドしたいバージョンのタグもしくはコミットハッシュに置き換え、`hash`に空文字列か意味の無いハッシュを指定する
2. パッケージをどこかで参照した後に一旦ビルドを回す[^lazy]
3. エラーになって落ちるので、出力されたハッシュを`hash`にコピペする

上記の作業で最新の Vim のパッケージができたので、後は他のパッケージ同様に扱うだけです。今回の例では`environment.systemPackages`に渡しています。

# Flake

ここまでの作業を行えば、新しい Vim が使えてとても幸せなのですが、上記のやり方には Vim の激しい更新に追い付くのが困難という欠点があります。
Vim は、歴史がありますが、未だなお開発の盛んなソフトウェアで、激しい時には毎日のように、数コミット積まれるといったことがざらにあります。その度に手でバージョンを切り替えるのは大変な作業です。
更新を間引くなり[nvfetcher](https://github.com/berberman/nvfetcher)のような外部のソフトウェアを使うなりのやりようはありますが、今回は Flake という Nix に実験的に搭載されている仕組み[^flake]を使用します。

Flake は、さながらプログラミング言語のパッケージマネージャのように、入力を記述して操作するとバージョンをその時点での最新に固定してくれます。通常は別の Flake を入力に取りますが、フラグを指定すると任意の非 Flake ソースを取り込んでビルドのソースとして扱えます。

```nix
{
  inputs = {
    vim-src = {
      flake = false;
      url = "github:vim/vim";
    };
  };

  outputs =
    { vim-src }:
    {
      # この中ではfetchFromGitHubの結果と同様に扱える
    };
}
```

このように、面倒なプロセスを経ることなく新しいバージョンを指定できる他、`nix flake update` コマンドを叩けば一発でその時点の最新を指すように更新してくれます。 これで圧倒的に楽になりますね。
今回は、例が多いので、実際に私が使っている設定でどのように入力を引き回しているかを貼っておきます。

https://github.com/kuuote/nixconf/blob/612cd263b5f07ae9fccf0cf56d1879ab7a5d84f2/flake.nix#L10-L11
https://github.com/kuuote/nixconf/blob/612cd263b5f07ae9fccf0cf56d1879ab7a5d84f2/flake.nix#L29
https://github.com/kuuote/nixconf/blob/612cd263b5f07ae9fccf0cf56d1879ab7a5d84f2/latitude/default.nix#L26
https://github.com/kuuote/nixconf/blob/612cd263b5f07ae9fccf0cf56d1879ab7a5d84f2/nixos/feat/vim.nix#L25

# 〆

私は Nix を始めて一番最初にこれをやろうとして、kawarimidoll さんに紹介してもらった上記の記事を見様見真似で NixOS 向けに書き直してみたり、Flake が何なのかが理解できずに通常版に書き直してみたり、パッケージ一覧に`overrideAttrs`を直接書く時、括弧で括らないと怒られるのを知らなくて無駄に overlay じゃないと駄目と思って使ってみたりと色々と遠回りしましたが、結果的に Nix に習熟できてよい体験だったなと思います。
折角ここまで辿り着いたので、当時の私が知りたかった知識について記述しておきました。
ちなみに、kawarimidoll さんの記事が nix-darwin 向けに書かれていることから分かる通り、パッケージの仕組みは NixOS 以外でも同じため流用できます。

Nix は全てが Nix 言語で書かれたテキストを元に動作します。そのため何をするにしてもテキストエディタの出番があります。最新のエディタで気持ちよく編集していきましょう。
Happy Vimming!!

[^substituter]: 代わりに Substituter という仕組みがあります。詳しくは[こちら](https://zenn.dev/asa1984/books/nix-introduction/viewer/07-binary-cache)を参照ください
[^lazy]: Nix言語は非正格評価の言語なので、宣言しても参照されないとそもそも評価されません
[^flake]: 実験的と言いつつデファクトスタンダートみたいな物になっていますが
