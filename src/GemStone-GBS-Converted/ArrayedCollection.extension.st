Extension { #name : #'ArrayedCollection' }

{ #category : '*GemStone-GBS-Converted-GemStone-extensions' }
ArrayedCollection class >> gbxWith: firstObject with: secondObject with: thirdObject with: fourthObject with: fifthObject [
	"Answer a new instance of ArrayedCollection, containing the four 
	arguments as the elements."

	| newCollection |
	newCollection := self new: 5.
	newCollection at: 1 put: firstObject.
	newCollection at: 2 put: secondObject.
	newCollection at: 3 put: thirdObject.
	newCollection at: 4 put: fourthObject.
	newCollection at: 5 put: fifthObject.
	^newCollection
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ArrayedCollection class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ArrayedCollection class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ArrayedCollection class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ArrayedCollection >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ArrayedCollection >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ArrayedCollection >> isRunningUnderAssertingVM [
	^false
]

