Extension { #name : 'Part' }

{ #category : '*GbsToolsOverrides-Extensions' }
Part >> text
[

	^
	[| obj wrappedOrNot |
	obj := self value.
	wrappedOrNot := (GemStone.Gbs.GbxReflection shouldBeWrapped: obj)
				ifTrue: [GemStone.Gbs.GbxInspectionWrapper on: obj]
				ifFalse: [obj].
	GemStone.Gbs.GbxReflection
		send: #gbxDebugPrintString
		to: wrappedOrNot
		ifNotUnderstood: 
			[wrappedOrNot printString	"VW inspector sends #printString, so we won't fail any worse than they do."]]
			toolSafeIn: 2 seconds
			else: 
				[:ex |
				#ErrorPrintingObject << #dialogs >> '[Error printing the object: <1s>]'
					expandMacrosWith: ex description]
]

