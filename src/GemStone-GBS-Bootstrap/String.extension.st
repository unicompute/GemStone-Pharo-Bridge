Extension { #name : 'String' }

{ #category : '*GemStone-GBS-Bootstrap' }
String >> asQualifiedReference
[
	^ BindingReference pathString: self
]
