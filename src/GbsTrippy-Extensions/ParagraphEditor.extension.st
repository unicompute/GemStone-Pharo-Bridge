Extension { #name : 'ParagraphEditor' }

{ #category : '*GbsTrippy-Extensions' }
ParagraphEditor >> gbxDoItReceiver
[
	"the trippy inspector needs to be able to return the delegate for gs-actions and the localObject when available"

	^self evaluator gbxDoItReceiver
]

