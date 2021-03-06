------------------------------------------------------------

                 codic 辞書データについて

------------------------------------------------------------

1. 辞書の種類について

	codic の辞書には、ネーミング辞書とIT英語辞書の２つがあり、
	一般的な表現では、それぞれ和英辞書、英和辞書に相当します。
	ネーンミング辞書は、ユーザーからの投稿情報を含んでいます。
	※ IT英語辞書については、現在編集中の v2.1 以降が配布対象
	となります。

2. 辞書データについて

	codic の辞書データは、entry と translation の２つの
	テーブルから構成されます。２つのテーブルは、エントリID
	で関連します。

	+-------------+      +----------------+
	| entry       |      | translation    |
	+-------------+      +----------------+
	| entry_id    |--+   | translation_id |
	|             |  +-->| entry_id       |
	+-------------+      +----------------+


	辞書データには、ユーザー情報など一部は含まれていません。


3. CSVフィールド

	naming-entry.csv
	+----+-------------+---------------------------------+
	| No.|             |                                 |
	+----+-------------+---------------------------------+
	| 1  | エントリID  | 辞書エントリに付与されるID      |
	| 2  | 見出し語    |                                 |
	+----+-------------+---------------------------------+

	naming-translation.csv
	+----+-------------+---------------------------------+
	| No.|             |                                 |
	+----+-------------+---------------------------------+
	| 1  | 訳語ID      | 訳語エントリに付与されるID      |
	| 2  | エントリID  |                                 |
	| 3  | 品詞        | ユーザー投稿の品詞              |
	| 4  | 解説        | ユーザー投稿の解説              |
	| 5  | 投票数      | サイト上に表示される投票数      |
	+----+-------------+---------------------------------+

	english-entry.csv
	+----+-------------+---------------------------------+
	| No.|             |                                 |
	+----+-------------+---------------------------------+
	| 1  | エントリID  | 辞書エントリに付与されるID      |
	| 2  | 見出し語    |                                 |
	| 3  | IPA         |                                 |
	| 4  | カナ読み    |                                 |
	| 5  | 複数形      |                                 |
	| 6  | 形容詞変化  | 比較級,最上級                   |
	| 7  | 動詞変化    | 三人称,現在分詞,過去,(過去分詞) |
	+----+-------------+---------------------------------+

	english-translation.csv
	+----+-------------+---------------------------------+
	| No.|             |                                 |
	+----+-------------+---------------------------------+
	| 1  | 訳語ID      | 訳語エントリに付与されるID      |
	| 2  | エントリID  |                                 |
	| 3  | 品詞        | 品詞                            |
	| 4  | 分野        | 分野やカテゴリ　例）computing   |
	| 4  | 訳語        | 訳語                            |
	| 5  | 解説        | 解説文                          |
	+----+-------------+---------------------------------+

4. ライセンス

	codic の辞書データは、クリエイティブ・コモンズライセンス
	（CC BY-SA 3.0）によってライセンスされます。

	http://creativecommons.org/licenses/by-sa/3.0/deed.ja

