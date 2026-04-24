Extension { #name : 'GbxContextListPolicy' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbxContextListPolicy >> buildContextListFromServerContexts: serverContexts [
	| allContexts topServerContext firstClientContext marker |
	allContexts := OrderedCollection new.
	allContexts addAll: (serverContexts ifNil: [ #() ]).

	topServerContext := allContexts
		ifEmpty: [ nil ]
		ifNotEmpty: [ allContexts first ].
	topServerContext ifNotNil: [
		firstClientContext := self firstClientContextAbove: topServerContext.
		firstClientContext ifNotNil: [
			marker := self matchingServerCallMarkerForServerContext: topServerContext.
			allContexts addAll: (self
				clientContextsStartingAt: firstClientContext
				upToContextExclusive: marker) ] ].

	glueIsHidden
		ifTrue: [ contextList := self filterOutGlue: allContexts ]
		ifFalse: [ contextList := allContexts ].
	^ contextList
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxContextListPolicy >> updateContextListFromServerContexts: serverContexts [
	self buildContextListFromServerContexts: serverContexts.
	debugger updateStackList: self contextList
]
