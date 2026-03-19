Extension { #name : 'SortedCollection' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
SortedCollection class >> replicationSpec [
	^ super replicationSpec , #(#(#sortBlock #min 1) #(#indexable_part #min 1))
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SortedCollection >> indexableValueAt: index put: aValue [
	[ self size < index ] whileTrue: [ super addLast: nil ].
	super at: index put: aValue
]
