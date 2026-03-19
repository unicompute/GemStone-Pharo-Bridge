Extension { #name : 'SequenceableCollection' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
SequenceableCollection >> allItemsMatch: anArray [
	self size ~= anArray size ifTrue: [ ^ false ].
	self with: anArray do: [ :each :other |
		('*' , other , '*') match: each ifFalse: [ ^ false ] ].
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SequenceableCollection >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	self gbsMessenger deny: (self includes: self).
	self do: [ :each |
		(each gbxCanBeArgForUnsynchronizedOperationInSession: session)
			ifFalse: [ ^ false ] ].
	^ true
]
