Extension { #name : #'Interval' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Interval class >> instVarMap [
	"Private.  GBS.  GemStone replication support."

	^super instVarMap, #(
		(start from)
		(stop to)
		(step by) )
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Interval >> gbxDebugPrintOn: aStream [

	self printOn: aStream
]

{ #category : '*GemStone-GBS-Converted-comparing' }
Interval >> gbxOverlaps: anInterval [
	"Answer true if anInterval's range overlaps mine, in the real number 
	sense. Actually having common entries is not required."

	^(self first between: anInterval first and: anInterval last) or: 
			[(self last between: anInterval first and: anInterval last) or: 
					[(anInterval first between: self first and: self last) 
						or: [anInterval last between: self first and: self last]]]
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Interval class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Interval class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Interval class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Interval >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Interval >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Interval >> isRunningUnderAssertingVM [
	^false
]

