---
title: "Nix Flakesの参照で<nixpkgs>を固定する方法"
emoji: "❄"
type: "tech"
topics: ["nix"]
published: true
---

Nixのイディオムに次のような物があります。

```nix
{
  pkgs ? import <nixpkgs> { },
}:
```

これは、`pkgs`を要素に含むかもしれないAttrSetを引数に取り、含んでいたらそれを、無ければ`import <nixpkgs> { }`の結果を使うという物です。`nix-build`は関数を返すファイルを読むとAttrSetを渡して呼び出してくれるので、このような書き方をすると外部からも呼び出せるけどそのまま使うこともできるビルド定義が作れます。

この`<nixpkgs>`ですが、`$NIX_PATH`で指定されている場所もしくは、引数`-I`で渡した場所から検索されます。
この場所は普通にインストールすると`nix-channel`で管理される場所を指しており、チャンネルを更新することで管理を行いますが、Nix FlakesでNixOSなどの設定を管理している場合、そちらと同じバージョンを指していると便利なことがあります。

そこで、Nix Flakes経由で`<nixpkgs>`の指定を固定する方法をNixOS編とhome-manager編の2通り紹介します。

# NixOS
NixOSの場合、Nix Flakes経由でビルドするだけでこの設定が適用されるようになっています。
flake.nixの`nixosSystem`経由でNixOSの設定を定義すると次の設定が差し込まれます。

https://github.com/NixOS/nixpkgs/blob/a79cfe0ebd24952b580b1cf08cd906354996d547/flake.nix#L74

この設定は下記のモジュールで処理され、最終的に`NIX_PATH=nixpkgs=flake:nixpkgs`という環境変数と次に示す`/etc/nix/registry.json`(minifyされてるのでjqで展開しています)に展開されます。

https://github.com/NixOS/nixpkgs/blob/a79cfe0ebd24952b580b1cf08cd906354996d547/nixos/modules/misc/nixpkgs-flake.nix
https://github.com/NixOS/nixpkgs/blob/a79cfe0ebd24952b580b1cf08cd906354996d547/nixos/modules/config/nix-flakes.nix

```json
{
  "flakes": [
    {
      "exact": true,
      "from": {
        "id": "nixpkgs",
        "type": "indirect"
      },
      "to": {
        "path": "/nix/store/j33wzkzndh41cyyy7i18bqm1srlv84cq-source",
        "type": "path"
      }
    }
  ],
  "version": 2
}
```

この設定の下で`<nixpkgs>`を参照するとビルドした時と同じnixpkgsが呼び出されます。

# そもそもこれは何をやっているのか
flake registryのpin(`nix registry pin`コマンドでできる物と同じ)及び`<nixpkgs>`の参照先をflakeに向けることを行っています。

flake参照は `github:nixos/nixpkgs?ref=nixos-unstable#hello`と書かなくて`nixpkgs#hello` のように名前だけで指定できますが、この名前と実際の定義の紐付けを行っているのがflake registryになります。
デフォルトで参照される設定は https://channels.nixos.org/flake-registry.json に置いてありますが、リビジョンの設定がされておらず、常に最新を指すようになっています。
そこで上記の設定を行うと、定義が上書きされ、参照されるリビジョンが固定されます。

そして`NIX_PATH`には`flake:nixpkgs`のようにflake参照を設定できるので[^commit]、`nixpkgs=flake:nixpkgs`を設定することにより`<nixpkgs>`が`flake:nixpkgs`を指すようになります。

# home-manager
home-managerには上の設定自体はありませんが、flake registryを設定するためのモジュールがあるので以下のモジュールを定義すると同じことができます。(モジュールを使うのが面倒であれば自前で`registry.json`を出力する式を書くという手もあります)

```nix
{
  pkgs,
  ...
}:
{
  nix = {
    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
    registry = {
      nixpkgs = {
        from = {
          type = "indirect";
          id = "nixpkgs";
        };
        to = {
          type = "path";
          # pkgs.pathでnixpkgsのrootが取れる
          # そのまま文字列にすると謎のコピーが走ることがあるのでtoStringをかける
          path = "${builtins.toString pkgs.path}";
        };
      };
    };
  };
} 
```

この記述は下記の処理でそのままJSONに変換されて `~/.config/nix/registry.json` に配置されます。

https://github.com/nix-community/home-manager/blob/662fa98bf488daa82ce8dc2bc443872952065ab9/modules/misc/nix.nix#L292-L299

[^commit]: [このコミット](https://github.com/NixOS/nix/commit/fd0ed7511818ba871dc3e28796ec1d0ca57b22ec)で入ったらしい
