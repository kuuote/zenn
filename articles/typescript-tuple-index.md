---
title: "TypeScriptで2つのタプル型からオブジェクトの型を作る"
emoji: "🔃"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["typescript"]
published: true
---

[とあるコミュニティ](https://vim-jp.org/docs/chat.html)[^1]で2つのタプルの型からオブジェクトを作れないかという質問があって色々やってたらそれっぽいのが出来上がったのでメモしておきます。[^2]

# 課題

```typescript
const FOO_COLUMNS = ["id", "name", "flag"] as const;
type FooColumnTypes = [number, string, boolean];
```
を
```typescript
type FooTableRow = {
  id: number,
  name: string,
  flag: boolean
};
```
に変形したい

# 回答

```typescript
const FOO_COLUMNS = ["id", "name", "flag"] as const;
type FooColumnTypes = [number, string, boolean];
type FooIndex = Exclude<keyof typeof FOO_COLUMNS, keyof unknown[]>;
type FooTableRow = {
  [P in FooIndex as typeof FOO_COLUMNS[P]]: FooColumnTypes[P];
};
```

# で、これ何やってるの？

`FOO_COLUMNS`からインデックスの番号を抽出した上でそれぞれの要素にインデックスアクセスしてマッピングしています。

TypeScriptのタプルはそれぞれのインデックスの型と長さが指定されたArrayの型として表現されています。そこからインデックス部分だけを抽出できればMapped Typesでごにょごにょできるはずです。キーのUnionは`keyof`で抜き出せるので後は型を抽出できればいいわけです。というわけで[Extract<T, U>](https://typescriptbook.jp/reference/type-reuse/utility-types/extract)を使って書いてみたのですが、上手く行きません。

```typescript
type FooIndex = Extract<keyof typeof FOO_COLUMNS, number>;
```

この例だとFooIndexは`number`になってしまいます。しかし推論の結果は番号で得られるので(エラーを起こすとわかる)何かしらの方法はあるはずと調べていたらTypeScriptの[とあるissue](https://github.com/microsoft/TypeScript/issues/32917#issuecomment-521650100)に行き着きました。そこに書いてあったコメントによると[Exclude<T, U>](https://typescriptbook.jp/reference/type-reuse/utility-types/exclude)を使うと正しくリテラル型が得られるよとのことでした。という訳でこのように書き直してみました。
```typescript
type FooIndex = Exclude<keyof typeof FOO_COLUMNS, keyof unknown[]>;
```

配列の型はlengthを含む配列由来のキーを全て持っていて、それをタプルから引き去るとインデックスのキーだけが残るという寸法です。これを試した所上手く行きました。後はMapped Typesで変形するだけです。

```typescript
type FooTableRow = {
  [P in FooIndex as typeof FOO_COLUMNS[P]]: FooColumnTypes[P];
};
```

キーのremapの仕方がなかなか分からなくて(TypeScript4.1で増えた仕様らしいので仕方ないかも)調べるのに苦労しましたが[Key Remappingのまとめ](https://qiita.com/ryokkkke/items/7b16c238377b3b57d77f)を書いで下さっていた方がいて助かりました。

# さいごに

一応目的は達成できそうなコードは書けましたが、私の拙いTypeScriptちからではジェネリクスにすることはできませんでした。(特定の長さを持つタプルのジェネリックな表現方法が分からなかった)
一方でこの話が出てきたコミュニティ、[vim-jp](https://vim-jp.org/docs/chat.html)では再帰的な型定義を駆使しジェネリクスで動く物を作られた方々もいました。
私から見て素晴らしいと感じるエンジニアが多数所属しており、元々Vimのコミュニティではありますが中には関係なく参加されている方もいます。興味がある方は是非参加してみてください。

[^1]: テキストエディタのコミュニティのはずなんですが、あらゆる話題で盛り上がっていてJavaScriptに関するチャンネルも活発です
[^2]: 原題はジェネリクスでやることだったのでこれはレギュレーション違反ですね
