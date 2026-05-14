Class {
	#name : 'GbsRemoteMethodMirror',
	#superclass : 'Object',
	#instVars : [
		'session',
		'classReference',
		'selector',
		'classSide',
		'methodMetadata'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsRemoteMethodMirror class >> on: aSession class: aClassOrName selector: aSelector classSide: aBoolean [
	^ self new
		session: aSession;
		classReference: aClassOrName;
		selector: aSelector;
		classSide: aBoolean;
		yourself
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> classReference [
	^ classReference
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> classReference: aClassOrName [
	classReference := aClassOrName
]

{ #category : 'converting' }
GbsRemoteMethodMirror >> asMethodObject [
	^ GbsRemoteMethodObject onMirror: self
]

{ #category : 'converting' }
GbsRemoteMethodMirror >> asUnboundMethodObject [
	^ GbsRemoteUnboundMethodObject onMirror: self
]

{ #category : 'binding' }
GbsRemoteMethodMirror >> bindTo: aReceiver [
	^ self asMethodObject bindTo: aReceiver
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> classSide [
	^ classSide == true
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> classSide: aBoolean [
	classSide := aBoolean == true
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> exists [
	^ self methodMetadata notNil
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> methodMetadata [
	^ methodMetadata ifNil: [
		methodMetadata := self
			fetchMethodBody: self methodMetadataCommandBody
			literalAssignments: (Dictionary new
				at: 'selectorValue' put: self selector asSymbol;
				at: 'selectorString' put: self selector asString;
				at: 'classSideValue' put: self classSide;
				yourself)
			oopAssignments: Dictionary new ]
]

{ #category : 'private' }
GbsRemoteMethodMirror >> methodMetadataCommandBody [
	^ '| behavior meth source protocol ownerName packageName methodVersions versionIndex sourceLocation |
cls ifNil: [ nil ] ifNotNil: [
	behavior := classSideValue ifTrue: [ cls class ] ifFalse: [ cls ].
	meth := behavior compiledMethodAt: selectorValue ifAbsent: [ nil ].
	meth ifNil: [ nil ] ifNotNil: [
		protocol := [ behavior categoryOfSelector: selectorValue ] on: Error do: [ nil ].
		protocol ifNil: [ protocol := ''as yet unclassified'' ].
		source := [ meth sourceString ] on: Error do: [ [ meth sourceCode ] on: Error do: [ [ meth printString ] on: Error do: [ nil ] ] ].
		ownerName := cls name asString.
		classSideValue ifTrue: [ ownerName := ownerName , '' class'' ].
		packageName := [ (behavior respondsTo: #package) ifTrue: [ behavior package ifNil: [ nil ] ifNotNil: [ behavior package name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ].
		methodVersions := [ (behavior respondsTo: #allVersionsOf:) ifTrue: [ behavior allVersionsOf: selectorValue ] ifFalse: [ #() ] ] on: Error do: [ #() ].
		versionIndex := (methodVersions isNil or: [ methodVersions isEmpty ]) ifTrue: [ nil ] ifFalse: [ [ methodVersions indexOf: meth ] on: Error do: [ nil ] ].
		sourceLocation := [ meth sourcePositionAsString ] on: Error do: [ nil ].
		sourceLocation ifNil: [ sourceLocation := ownerName , ''>>'' , selectorString ].
		Array with: meth asOop with: ownerName with: selectorString with: protocol asString with: source with: packageName with: sourceLocation with: versionIndex with: (methodVersions ifNil: [ nil ] ifNotNil: [ methodVersions size ]) ] ]'
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> oop [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 1
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> classHistory [
	^ session classHistoryOf: (self classMirror proxy ifNil: [ classReference ])
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> classMirror [
	^ session classMirrorOf: (classReference ifNil: [ self ownerName ])
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> numberOfVersions [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 9 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> ownerName [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 2
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> packageName [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 6 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> protocol [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 4
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> proxy [
	| oopValue |
	oopValue := self oop.
	oopValue ifNil: [ ^ nil ].
	^ session objectForOop: oopValue
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> selector [
	^ selector
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> selector: aSelector [
	selector := aSelector asSymbol
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> sourceCode [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 5 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> sourceLocation [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 7 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> version [
	| metadata |
	metadata := self methodMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 8 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> versionEntries [
	^ self
		fetchMethodBody: self versionEntriesCommandBody
		literalAssignments: (Dictionary new
			at: 'selectorValue' put: self selector asSymbol;
			at: 'classSideValue' put: self classSide;
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'private' }
GbsRemoteMethodMirror >> versionEntriesCommandBody [
	^ '| behavior sel versions entries meth src label | cls ifNil: [ #() ] ifNotNil: [ behavior := classSideValue ifTrue: [ cls class ] ifFalse: [ cls ]. sel := selectorValue. entries := OrderedCollection new. versions := [ (behavior respondsTo: #allVersionsOf:) ifTrue: [ behavior allVersionsOf: sel ] ifFalse: [ #() ] ] on: Error do: [ #() ]. versions isEmpty ifTrue: [ meth := behavior compiledMethodAt: sel ifAbsent: [ nil ]. meth ifNotNil: [ src := [ meth sourceString ] on: Error do: [ [ meth sourceCode ] on: Error do: [ '''' ] ]. src isEmpty ifFalse: [ entries add: (Array with: ''version 1'' with: src) ] ] ] ifFalse: [ 1 to: versions size do: [ :ix | meth := versions at: ix. src := [ meth sourceString ] on: Error do: [ [ meth sourceCode ] on: Error do: [ '''' ] ]. label := ''version '', ix asString. entries add: (Array with: label with: src) ] ]. entries asArray ]'
]

{ #category : 'private' }
GbsRemoteMethodMirror >> fetchMethodBody: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	^ session repository
		fetchClassReference: classReference
		variableName: 'cls'
		body: bodyString
		literalAssignments: literalDictionary
		oopAssignments: oopDictionary
]
