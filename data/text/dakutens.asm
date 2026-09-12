Dakutens:
	db "かが", "きぎ", "くぐ", "けげ", "こご"
	db "さざ", "しじ", "すず", "せぜ", "そぞ"
	db "ただ", "ちぢ", "つづ", "てで", "とど"
	db "はば", "ひび", "ふぶ", "へべ", "ほぼ"
	db "カガ", "キギ", "クグ", "ケゲ", "コゴ"
	db "サザ", "シジ", "スズ", "セゼ", "ソゾ"
	db "タダ", "チヂ", "ツヅ", "テデ", "トド"
IF DEF(_JAPAN)
	db "ハバ", "ヒビ", "フブ", "ヘベ", "ホボ"
ELSE
	; International ROMs retain the Japanese table, including this lowercase leftover pair.
	db "ハバ", "ヒビ", "フブ", "へべ", "ホボ"
ENDC
	db -1 ; end

Handakutens:
	db "はぱ", "ひぴ", "ふぷ", "へぺ", "ほぽ"
IF DEF(_JAPAN)
	db "ハパ", "ヒピ", "フプ", "ヘペ", "ホポ"
ELSE
	; Same international leftover as the original ROM data.
	db "ハパ", "ヒピ", "フプ", "へぺ", "ホポ"
ENDC
	db -1 ; end
