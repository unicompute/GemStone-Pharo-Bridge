Extension { #name : 'Set' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> goodSizeFrom: requestedSize [
	| size |
	size := requestedSize max: 3.
	size even ifTrue: [ size := size + 1 ].
	[ self gbxIsPrime: size ] whileFalse: [ size := size + 2 ].
	^ size
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> gbxIsPrime: anInteger [
	| limit factor |
	anInteger = 2 ifTrue: [ ^ true ].
	(anInteger < 2 or: [ anInteger even ]) ifTrue: [ ^ false ].
	limit := anInteger sqrt truncated.
	factor := 3.
	[ factor <= limit ] whileTrue: [
		(anInteger \\ factor) = 0 ifTrue: [ ^ false ].
		factor := factor + 2 ].
	^ true
]
