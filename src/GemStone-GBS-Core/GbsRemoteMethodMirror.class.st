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

{ #category : 'private' }
GbsRemoteMethodMirror >> classExpression [
	^ session repository classExpressionFor: classReference
]

{ #category : 'private' }
GbsRemoteMethodMirror >> behaviorExpression [
	^ self classSide
		ifTrue: [ 'cls class' ]
		ifFalse: [ 'cls' ]
]

{ #category : 'querying' }
GbsRemoteMethodMirror >> exists [
	^ self methodMetadata notNil
]

{ #category : 'accessing' }
GbsRemoteMethodMirror >> methodMetadata [
	^ methodMetadata ifNil: [
		methodMetadata := session executeScriptAndFetchObject: self methodMetadataScript ]
]

{ #category : 'private' }
GbsRemoteMethodMirror >> methodMetadataScript [
	| selectorScript selectorStringScript |
	selectorScript := session marshalArgumentToScript: self selector asSymbol.
	selectorStringScript := session marshalArgumentToScript: self selector asString.
	^ String streamContents: [ :stream |
		stream nextPutAll: '| cls behavior meth source protocol ownerName packageName methodVersions versionIndex sourceLocation | cls := '.
		stream nextPutAll: self classExpression.
		stream nextPutAll: '. cls ifNil: [ nil ] ifNotNil: [ behavior := '.
		stream nextPutAll: self behaviorExpression.
		stream nextPutAll: '. meth := behavior compiledMethodAt: '.
		stream nextPutAll: selectorScript.
		stream nextPutAll: ' ifAbsent: [ nil ]. meth ifNil: [ nil ] ifNotNil: ['.
		stream nextPutAll: ' protocol := [ behavior categoryOfSelector: '.
		stream nextPutAll: selectorScript.
		stream nextPutAll: ' ] on: Error do: [ nil ].'.
		stream nextPutAll: ' protocol ifNil: [ protocol := ''as yet unclassified'' ].'.
		stream nextPutAll: ' source := [ meth sourceString ] on: Error do: [ [ meth sourceCode ] on: Error do: [ [ meth printString ] on: Error do: [ nil ] ] ].'.
		stream nextPutAll: ' ownerName := cls name asString.'.
		self classSide ifTrue: [
			stream nextPutAll: ' ownerName := ownerName , '' class''.' ].
		stream nextPutAll: ' packageName := [ (behavior respondsTo: #package) ifTrue: [ behavior package ifNil: [ nil ] ifNotNil: [ behavior package name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ].'.
		stream nextPutAll: ' methodVersions := [ (behavior respondsTo: #allVersionsOf:) ifTrue: [ behavior allVersionsOf: '.
		stream nextPutAll: selectorScript.
		stream nextPutAll: ' ] ifFalse: [ #() ] ] on: Error do: [ #() ].'.
		stream nextPutAll: ' versionIndex := (methodVersions isNil or: [ methodVersions isEmpty ]) ifTrue: [ nil ] ifFalse: [ [ methodVersions indexOf: meth ] on: Error do: [ nil ] ].'.
		stream nextPutAll: ' sourceLocation := [ meth sourcePositionAsString ] on: Error do: [ nil ].'.
		stream nextPutAll: ' sourceLocation ifNil: [ sourceLocation := ownerName , ''>>'' , '.
		stream nextPutAll: selectorStringScript.
		stream nextPutAll: ' ].'.
		stream nextPutAll: ' Array with: meth asOop with: ownerName with: '.
		stream nextPutAll: selectorStringScript.
		stream nextPutAll: ' with: protocol asString with: source with: packageName with: sourceLocation with: versionIndex with: (methodVersions ifNil: [ nil ] ifNotNil: [ methodVersions size ]) ] ]'
	]
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
	^ session executeScriptAndFetchObject: self versionEntriesScript
]

{ #category : 'private' }
GbsRemoteMethodMirror >> versionEntriesScript [
	| selectorScript |
	selectorScript := session marshalArgumentToScript: self selector asSymbol.
	^ String streamContents: [ :stream |
		stream nextPutAll: '| cls behavior sel versions entries meth src label | cls := '.
		stream nextPutAll: self classExpression.
		stream nextPutAll: '. cls ifNil: [ #() ] ifNotNil: [ behavior := '.
		stream nextPutAll: self behaviorExpression.
		stream nextPutAll: '. sel := '.
		stream nextPutAll: selectorScript.
		stream nextPutAll: '. entries := OrderedCollection new. versions := [ (behavior respondsTo: #allVersionsOf:) ifTrue: [ behavior allVersionsOf: sel ] ifFalse: [ #() ] ] on: Error do: [ #() ]. versions isEmpty ifTrue: [ meth := behavior compiledMethodAt: sel ifAbsent: [ nil ]. meth ifNotNil: [ src := [ meth sourceString ] on: Error do: [ [ meth sourceCode ] on: Error do: [ '''' ] ]. src isEmpty ifFalse: [ entries add: (Array with: ''version 1'' with: src) ] ] ] ifFalse: [ 1 to: versions size do: [ :ix | meth := versions at: ix. src := [ meth sourceString ] on: Error do: [ [ meth sourceCode ] on: Error do: [ '''' ] ]. label := ''version '', ix asString. entries add: (Array with: label with: src) ] ]. entries asArray ]'
	]
]
