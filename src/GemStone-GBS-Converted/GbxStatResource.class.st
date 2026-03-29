Class {
	#name : 'GbxStatResource',
	#superclass : 'Object',
	#instVars : [
		'instanceId',
		'stats'
	],
	#classInstVars : [
		'statDescriptors'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxStatResource class >> addStatDescriptor: aGbxStatDescriptor [
	statDescriptors ifNil: [ statDescriptors := OrderedCollection new ].
	statDescriptors add: aGbxStatDescriptor.
	aGbxStatDescriptor setId: statDescriptors size - 1
]

{ #category : 'instance creation' }
GbxStatResource class >> new [
	self statDescriptors.
	^ super new initializeStatistics
]

{ #category : 'archiving' }
GbxStatResource class >> numberOfDescriptors [
	^ self statDescriptors size
]

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeDescription [
	^ self resourceTypeName
]

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeId [
	^ self subclassResponsibility
]

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeName [
	^ self subclassResponsibility
]

{ #category : 'accessing' }
GbxStatResource class >> statDescriptors [
	statDescriptors ifNil: [ self initialize ].
	^ statDescriptors ifNil: [ statDescriptors := OrderedCollection new ]
]

{ #category : 'archiving' }
GbxStatResource class >> writeDescriptorInformationOn: statArchiver [
	self statDescriptors do: [ :desc | desc writeToArchiver: statArchiver ]
]

{ #category : 'archiving' }
GbxStatResource >> closedArchive [
	stats do: [ :stat | stat closedArchive ]
]

{ #category : 'reflective operations' }
GbxStatResource >> doesNotUnderstand: aMessage [
	| selectorString statName |

	selectorString := aMessage selector asString.
	(selectorString beginsWith: 'inc')
		ifTrue: [
			statName := self statNameForIncrementSelector: selectorString.
			(self hasStatNamed: statName) ifTrue: [
				^ self
					incrementStatNamed: statName
					by: (aMessage arguments ifEmpty: [ 1 ] ifNotEmpty: [ aMessage arguments first ]) ] ].
	(aMessage arguments isEmpty and: [ self hasStatNamed: selectorString ])
		ifTrue: [ ^ self valueOfStatNamed: selectorString ].
	((aMessage arguments size = 1)
		and: [ selectorString last = $: ]
		and: [ self hasStatNamed: selectorString allButLast ])
		ifTrue: [ ^ self setStatNamed: selectorString allButLast value: aMessage arguments first ].
	^ super doesNotUnderstand: aMessage
]

{ #category : 'testing' }
GbxStatResource >> hasStatNamed: statName [
	^ statName notNil and: [ self lookupDescriptorNamed: statName ] notNil
]

{ #category : 'initialize-release' }
GbxStatResource >> initializeStatistics [
	stats := OrderedCollection new.
	^ self
]

{ #category : 'archiving' }
GbxStatResource >> instanceDescription [
	^ self subclassResponsibility
]

{ #category : 'archiving' }
GbxStatResource >> instanceId [
	^ instanceId
]

{ #category : 'archiving' }
GbxStatResource >> instanceId: anInteger [
	instanceId := anInteger
]

{ #category : 'accessing' }
GbxStatResource >> incrementStatNamed: statName by: delta [
	| stat |

	stat := self statNamed: statName ifAbsent: [
		self lookupDescriptorNamed: statName ifNil: [ ^ self ].
		self newGbxStatFor: statName value: 0 ].
	stat incValue: delta.
	^ stat value
]

{ #category : 'initialize-release' }
GbxStatResource >> initializeZeroStatisticsFromDescriptors [
	self class statDescriptors do: [ :descriptor |
		self newGbxStatFor: descriptor name value: 0 ]
]

{ #category : 'accessing' }
GbxStatResource >> lookupDescriptorNamed: statName [
	^ self class statDescriptors
		detect: [ :each | each name = statName ]
		ifNone: [ nil ]
]

{ #category : 'initialize-release' }
GbxStatResource >> newGbxStatFor: statName value: initialValue [
	| desc stat |

	desc := self lookupDescriptorNamed: statName.
	desc ifNil: [ ^ nil ].
	stat := GbxStat newWithDescription: desc value: initialValue.
	stats add: stat.
	^ stat
]

{ #category : 'printing' }
GbxStatResource >> printOn: aStream [
	aStream
		nextPutAll: 'a ';
		nextPutAll: self class name;
		nextPutAll: ': ';
		nextPutAll: self instanceDescription
]

{ #category : 'accessing' }
GbxStatResource >> reinitializeStats [
	stats do: [ :stat |
		stat
			setValue: 0;
			closedArchive ]
]

{ #category : 'accessing' }
GbxStatResource >> setStatNamed: statName value: aValue [
	| stat |

	stat := self statNamed: statName ifAbsent: [
		self lookupDescriptorNamed: statName ifNil: [ ^ aValue ].
		self newGbxStatFor: statName value: 0 ].
	stat value: aValue.
	^ aValue
]

{ #category : 'accessing' }
GbxStatResource >> statNameForIncrementSelector: selectorString [
	| bareSelector |

	bareSelector := selectorString copyFrom: 4 to: selectorString size.
	(bareSelector notEmpty and: [ bareSelector last = $: ]) ifTrue: [
		bareSelector := bareSelector allButLast ].
	bareSelector isEmpty ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
		stream nextPut: bareSelector first asLowercase.
		bareSelector size > 1 ifTrue: [ stream nextPutAll: bareSelector allButFirst ] ]
]

{ #category : 'accessing' }
GbxStatResource >> statNamed: statName [
	^ self statNamed: statName ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxStatResource >> statNamed: statName ifAbsent: absentBlock [
	^ stats
		detect: [ :each | each name = statName ]
		ifNone: absentBlock
]

{ #category : 'accessing' }
GbxStatResource >> stats [
	^ stats
]

{ #category : 'accessing' }
GbxStatResource >> valueOfStatNamed: statName [
	| stat |

	stat := self statNamed: statName ifAbsent: [ ^ 0 ].
	^ stat value
]

{ #category : 'archiving' }
GbxStatResource >> writeSampleTo: statArchive [
	stats do: [ :stat | stat writeSampleTo: statArchive ]
]
