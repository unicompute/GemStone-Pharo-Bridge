Extension { #name : 'TextAttribute' }

{ #category : '*GbsToolsOverrides-Extensions' }
TextAttribute >> value
[

	^self text gbxDelegate ifNil: [self text] ifNotNil: [:obj | obj]
]

