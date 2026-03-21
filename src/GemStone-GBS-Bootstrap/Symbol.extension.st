Extension { #name : 'Symbol' }

{ #category : '*GemStone-GBS-Bootstrap' }
Symbol >> asQualifiedReference
[
	^ BindingReference pathString: self asString
]
