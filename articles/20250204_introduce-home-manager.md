---
title: "home-manager入門"
emoji: "🏠"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["nix"]
published: true
---

[home-manager](https://github.com/nix-community/home-manager)は、Nixを使ってユーザーの環境を管理するためのツールです。NixOSの仕組みを流用して作られているため、設定の書き方や使い方はNixOSに似ています。

基本機能として以下の機能を持っています。
- 宣言的なパッケージ導入
  - 内部では `nix-env` あるいは `nix profile` で管理され、これらで導入したパッケージと同じ扱いになります
- Nix storeからのシンボリックリンク生成
  - いわゆるdotfilesのようなことができます。chezmoiの振る舞いに近いと思います
- 環境変数管理
  - 出力されるソースは下記のパスのいずれかにあるので、home-managerでシェルの設定を管理してない場合は自前で読み込む必要があります
    - `~/.nix-profile/etc/profile.d/hm-session-vars.sh`
    - `~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh`
    - `/etc/profiles/per-user/${id -nu}/etc/profile.d/hm-session-vars.sh`
更にNixOSと同様に、設定をNixで生成する機能も持っています。

# 導入

上のリンクから辿れるマニュアルに全て書いてあるので、その通りに行います。
本記事ではstandalone版を導入します。事前に、experimentalではあるものの事実上の標準になっているNix Flakesの機能を有効化しておくのをおすすめします。`~/.config/nix/nix.conf` に以下の記述を加えると有効化されます。

```
experimental-features = nix-command flakes
```

Nix Flakes版は以下のコマンドを叩くだけで完了します。

```
$ nix run home-manager/master -- init --switch
```


Nix Flakesを使わない場合はhome-managerのchannelを追加で導入した上で `nix-shell` 上でhome-managerを走らせます。

```
$ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
$ nix-channel --update
$ nix-shell -p home-manager
$ home-manager init --switch
```

`~/.config/home-manager` (initに引数を渡せばパスの変更が可能)以下にテンプレートが吐き出された後にプロファイルの切り替えが走ります。
必要であればnix-shellから抜けたりシェルの再起動をした後、グローバルで `home-manager` コマンドが使えるようになれば導入成功です。

# 次にやること
基本的に、生成された `home.nix` を編集し `home-manager switch` コマンドを叩くという操作を繰り返します。壊れた時に戻す操作を行いやすくするためにバージョン管理を行うことを強く推奨します。
パッケージ導入かシンボリックリンク生成のいずれかを行うのをおすすめします。

## パッケージ導入
`home.nix` の `home.packages` 以下に記述した式の通りにパッケージを導入する機能です。

生成された `home.nix` の `# pkgs.hello` のコメントアウトを外します。

```diff
--- a/home.nix
+++ b/home.nix
@@ -20,7 +20,7 @@
   home.packages = [
     # # Adds the 'hello' command to your environment. It prints a friendly
     # # "Hello, world!" when run.
-    # pkgs.hello
+    pkgs.hello
 
     # # It is sometimes useful to fine-tune packages, for example, by applying
     # # overrides. You can do that directly here, just don't forget the
```

その上で `home-manager switch` を実行すると `hello` コマンドが使えるようになります。
コメントアウトを戻した上で再び `home-manager switch` を実行すると `hello` コマンドが使えなくなります。
パッケージの導入状況が宣言した通りに展開されるため、考えるべき状態が減り便利です。

## シンボリックリンク生成
`home.nix` の `home.file` 以下に記述した式の通りにホームディレクトリ以下にシンボリックリンクを生成する機能です。

例えば、以下の記述を行うと、Emacsのddskkというパッケージ用に、nixpkgsにあるSKK辞書を使うように指示する設定が `$HOME/.skk.el` に出力されます。

```nix
home.file = {
  ".skk.el".text = ''
    (setq skk-large-jisyo "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L")
  '';
};
```

derivationの出力(つまりパッケージの中身)を含むNix store内のファイルを配置することもできます。

```nix
home.file = {
  ".vimrc".source = ./vimrc;
  "bin/git-save".source = pkgs.writeShellScript "git-save" ''
    git add -A ; git commit -m save
  '';
};
```

このように、Nixの評価結果を利用できるのが、他のdotfiles managerとは異なる特色です。慣れるとできることの幅がどんどん拡がっていくので強力だと思います。

# 応用:宣言的な設定
先程のhome-manager自体の導入で `home-manager` コマンドが使えるようになりましたが、これは生成された `home.nix` 内の `programs.home-manager.enable = true;` の記述により実現しています。
この設定は home-managerのリポジトリ内の[modules/programs/home-manager.nix](https://github.com/nix-community/home-manager/blob/7abcf59a365430b36f84eaa452a466b11e469e33/modules/programs/home-manager.nix)に定義されており、最終的に `home.packages` の宣言に展開されます。
home-managerではこのようなモジュールが多数定義されており、対応しているプログラムの設定であれば宣言で設定を記述できます。
何が設定できるかは[マニュアル](https://nix-community.github.io/home-manager/options.xhtml)に一覧がある他、[リポジトリ](https://github.com/nix-community/home-manager/tree/master/modules)を直接参照して確認できます。
