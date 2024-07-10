---
title: "systemd-resolvedを使っている時にNixをインストールしようとすると通信に失敗する際の解決法"
emoji: "❄"
type: "tech"
topics: ["nix"]
published: true
---

systemd-resolvedを使っている環境で、何もせずにNixをインストールしようとすると、チャンネルの取得時にホストの解決に失敗し、以下の表示が繰り返し出ます。

```
warning: error: unable to download 'https://nixos.org/channels/nixpkgs-unstable': Couldn't resolve host name (6);
```

色々試していたのですが全然解決せず、ダメ元で `Couldn't resolve host name` と `Nix` で検索をかけたら一発で同じ問題の[Issue](https://github.com/NixOS/nix/issues/6770)がヒットしました。

そこに書いてある通りに `sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf` を実行した所無事ホストの解決に成功するようになりました。

# 原因

もしかしなくても `systemd-resolved` の設定不足です。ちゃんとマニュアルや[ArchWiki](https://wiki.archlinux.jp/index.php/Systemd-resolved#DNS)を読みましょう。
ArchWikiの該当部分には、下の引用のように、原因と解決方法(丁度上で行った物)が載っています。

> glibc の getaddrinfo(3) (または同等のもの)に依存するソフトウェアは、デフォルトで nss-resolve(8) が使用可能な場合、/etc/nsswitch.conf を使用するように設定されているため、そのまま使用できます。

> ウェブブラウザ や GnuPG など、/etc/resolv.conf を直接読み取るソフトウェアにドメイン名前解決を提供するために、systemd-resolved にはファイルを処理するための 4 つの異なるモード( スタブ、スタティック、アップリンク そしてフォーリン )があります。それらは、systemd-resolved(8) § /ETC/RESOLV.CONF で説明されています。ここでは推奨モード、すなわち、/run/systemd/resolve/stub-resolv.conf を使用するスタブモードにのみ注目します。

> /run/systemd/resolve/stub-resolv.conf には唯一の DNS サーバとしてのローカルスタブ 127.0.0.53 と検索ドメインのリストが含まれています。これは、systemd-resolved で管理された設定をすべてのクライアントに伝達する推奨の操作モードです。これを使用するには、/etc/resolv.conf をそのシンボリックリンクに置き換えます。 

> `# ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`

# 〆
- エラーが出るならちゃんと検索しましょう。
- ドキュメントはちゃんと読みましょう。

以上。
