Extension { #name : 'PartVisit' }

{ #category : '*GbsToolsOverrides-Extensions' }
PartVisit >> displayString
[

	| result obj |
	result := WriteStream on: (String new: 20).
	(self ownerPart notNil and: [self ownerPart partName notNil])
		ifTrue: 
			[result nextPutAll: self ownerPart partName.
			result nextPutAll: ': '].	"GBS: make sure we get the inspection wrapper if needed"
	obj := Tools.Trippy.Inspector wrappedOrNot: self object.
	obj basicPrintOn: result.
	^result contents
]

