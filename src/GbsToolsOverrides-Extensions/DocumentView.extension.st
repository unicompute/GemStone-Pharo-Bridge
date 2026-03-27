Extension { #name : 'DocumentView' }

{ #category : '*GbsToolsOverrides-Extensions' }
DocumentView >> triggerCursorEvent: aCursorEvent flow: aFlowSegment
[
	controller ifNil: [^self].
	"Handle this in both VW 8 and 9.
	 VW 9.x uses:
		(controller hasCommandEvent: aCursorEvent) ifFalse: [^self].
	 VW 8.x uses:
		(controller hasActionEvent: aCursorEvent) ifFalse: [^self]."
	(controller respondsTo: #hasCommandEvent:)
		ifTrue: [(controller hasCommandEvent: aCursorEvent) ifFalse: [^self]]
		ifFalse: [(controller hasActionEvent: aCursorEvent) ifFalse: [^self]].
	controller handleEvent: ((CommandEvent commandID: aCursorEvent)
				propertyAt: #view put: self;
				propertyAt: #flow put: aFlowSegment;
				yourself)
]

