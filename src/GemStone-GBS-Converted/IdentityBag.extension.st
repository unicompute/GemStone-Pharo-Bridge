Extension { #name : #'IdentityBag' }

{ #category : '*GemStone-GBS-Converted-instance-creation' }
IdentityBag class >> new: capacity [
	"GBS.  Answer a new instance of IdentityBag whose contents are empty."

	^self identityNew: capacity
]

{ #category : '*GemStone-GBS-Converted-instance-creation' }
IdentityBag class >> equalityNew: capacity [
	"GBS."

	^self shouldNotImplement
]

{ #category : '*GemStone-GBS-Converted-gemstone-support' }
IdentityBag >> preFaultWithReport: report inSession: session [

	"GBS.  Initialize the bag's capacity from the indexable size of the GemStone object"
	self initialize: (self class gbxIndexableSizeFromReport: report) type: IdentityDictionary
]

{ #category : '*GemStone-GBS-Converted-accessing' }
IdentityBag class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
IdentityBag class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
IdentityBag class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
IdentityBag >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
IdentityBag >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
IdentityBag >> isRunningUnderAssertingVM [
	^false
]

