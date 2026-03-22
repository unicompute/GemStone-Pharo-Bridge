Extension { #name : 'Class' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> asGSObjectInSession: aGbsSession [
	self == Class ifTrue: [
		| gsClass |
		gsClass := Smalltalk at: #GsClass ifAbsent: [ nil ].
		gsClass notNil ifTrue: [ ^ gsClass asGSObjectInSession: aGbsSession ] ].
	^ aGbsSession gemStoneClassFor: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> freeSlotsOnStubbing [
	^ GbsConfiguration current freeSlotsOnStubbing
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> gbsReplicatorClass [
	self subclassResponsibility
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> gbsReplicatorClassInSession: aSession [
	^ self gbsReplicatorClass
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> gbxServerClassInstVarNames [
	^ self class instVarNames
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> gbxServerClassVarNames [
	^ self classVarNames
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> gbxServerInstVarNames [
	^ self instVarNames
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> indexableValues [
	^ GbsBuffer new
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> instancesAreUnique [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> namedValues [
	| ans |
	ans := GbsBuffer new: self class instSize.
	Object class instSize + 1 to: ans size do: [ :i |
		ans at: i put: (self instVarAt: i) ].
	^ ans
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> newFromGSObjectReport: report [
	^ self isVariable
		ifTrue: [ self basicNew: (self gbxIndexableSizeFromReport: report) ]
		ifFalse: [ self basicNew ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Class >> newFromGSObjectReport: report inSession: aSession [
	^ self newFromGSObjectReport: report
]
