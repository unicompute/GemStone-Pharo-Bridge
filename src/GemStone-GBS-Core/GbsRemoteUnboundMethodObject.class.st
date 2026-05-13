Class {
	#name : 'GbsRemoteUnboundMethodObject',
	#superclass : 'Object',
	#instVars : [
		'mirror'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsRemoteUnboundMethodObject class >> on: aSession class: aClassOrName selector: aSelector classSide: aBoolean [
	^ self
		onMirror: (GbsRemoteMethodMirror
			on: aSession
			class: aClassOrName
			selector: aSelector
			classSide: aBoolean)
]

{ #category : 'instance creation' }
GbsRemoteUnboundMethodObject class >> onMirror: aRemoteMethodMirror [
	^ self new
		mirror: aRemoteMethodMirror;
		yourself
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> argumentCount [
	^ self selector numArgs
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> arity [
	^ self argumentCount
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> bindingDisplayString [
	^ 'unbound'
]

{ #category : 'binding' }
GbsRemoteUnboundMethodObject >> bindTo: aReceiver [
	^ (GbsRemoteMethodObject onMirror: mirror)
		bindTo: aReceiver
]

{ #category : 'compiling' }
GbsRemoteUnboundMethodObject >> compileProtocol [
	^ self protocol ifNil: [ 'as yet unclassified' ]
]

{ #category : 'compiling' }
GbsRemoteUnboundMethodObject >> correctedCompileResponseForSource: sourceText [
	^ self
		executeCompileBody: self correctedCompileCommandBody
		source: sourceText
]

{ #category : 'private' }
GbsRemoteUnboundMethodObject >> correctedCompileCommandBody [
	^ '| behavior oldSel protocol result newSel |
	cls ifNil: [ ^ ''ERROR|Class not found'' ].
	behavior := classSideValue ifTrue: [ cls class ] ifFalse: [ cls ].
	oldSel := selectorValue.
	protocol := protocolValue ifNil: [ ''as yet unclassified'' ].
	result := [ behavior compileMethod: sourceValue category: protocol ] on: Error do: [ :ex | ''ERROR|'', ex description ].
	(result isString and: [ result beginsWith: ''ERROR|'' ]) ifTrue: [ ^ result ].
	(result isKindOf: Array) ifTrue: [ ^ ''ERROR|Compilation failed'' ].
	newSel := [ result selector ] on: Error do: [ oldSel ].
	(newSel ~= oldSel and: [ behavior includesSelector: oldSel ]) ifTrue: [
		[ behavior removeSelector: oldSel ] on: Error do: [ :ex | ] ].
	''OK'''
]

{ #category : 'compiling' }
GbsRemoteUnboundMethodObject >> executeCompileBody: bodyString source: sourceText [
	| raw |
	raw := [ self session repository
		fetchClassReference: mirror classReference
		variableName: 'cls'
		body: bodyString
		literalAssignments: (Dictionary new
			at: 'classSideValue' put: self isClassSide;
			at: 'protocolValue' put: self compileProtocol;
			at: 'selectorValue' put: self selector;
			at: 'sourceValue' put: (sourceText ifNil: [ '' ] ifNotNil: [ :each | each asString copyReplaceAll: String cr with: String lf ]);
			yourself)
		oopAssignments: Dictionary new ]
		on: Error
		do: [ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> classHistory [
	^ mirror classHistory
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> classMirror [
	^ mirror classMirror
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> classReference [
	^ mirror classReference
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> categoryName [
	^ self protocol
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> classSide [
	^ mirror classSide
]

{ #category : 'printing' }
GbsRemoteUnboundMethodObject >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self ownerName;
			nextPutAll: '>>';
			nextPutAll: self selector asString ]
]

{ #category : 'comparing' }
GbsRemoteUnboundMethodObject >> = anObject [
	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ self session == anObject session
		and: [ self ownerName = anObject ownerName
		and: [ self selector = anObject selector
		and: [ self classSide = anObject classSide ] ] ]
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> exists [
	^ mirror exists
]

{ #category : 'comparing' }
GbsRemoteUnboundMethodObject >> hash [
	^ { self session identityHash. self ownerName. self selector. self classSide } hash
]

{ #category : 'testing' }
GbsRemoteUnboundMethodObject >> isBound [
	^ false
]

{ #category : 'testing' }
GbsRemoteUnboundMethodObject >> isClassSide [
	^ self classSide
]

{ #category : 'testing' }
GbsRemoteUnboundMethodObject >> isInstanceSide [
	^ self classSide not
]

{ #category : 'accessing' }
GbsRemoteUnboundMethodObject >> methodMetadata [
	^ mirror methodMetadata
]

{ #category : 'accessing' }
GbsRemoteUnboundMethodObject >> mirror [
	^ mirror
]

{ #category : 'accessing' }
GbsRemoteUnboundMethodObject >> mirror: aRemoteMethodMirror [
	mirror := aRemoteMethodMirror
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> name [
	^ String streamContents: [ :stream |
		self ownerName ifNotNil: [ stream nextPutAll: self ownerName ].
		stream
			nextPutAll: '>>';
			nextPutAll: self selector asString ]
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> numberOfVersions [
	^ mirror numberOfVersions
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> oop [
	^ mirror oop
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> owner [
	^ self classMirror
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> ownerName [
	^ mirror ownerName
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> ownerProxy [
	^ self classMirror
		ifNil: [ nil ]
		ifNotNil: [ :each | each proxy ]
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> packageName [
	^ mirror packageName
]

{ #category : 'printing' }
GbsRemoteUnboundMethodObject >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self ownerName;
		nextPutAll: '>>';
		nextPutAll: self selector asString;
		nextPut: $)
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> protocol [
	^ mirror protocol
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> proxy [
	^ mirror proxy
]

{ #category : 'accessing' }
GbsRemoteUnboundMethodObject >> receiver [
	^ nil
]

{ #category : 'binding' }
GbsRemoteUnboundMethodObject >> rebindTo: aReceiver [
	^ self bindTo: aReceiver
]

{ #category : 'compiling' }
GbsRemoteUnboundMethodObject >> recompileResponseForSource: sourceText [
	^ self
		executeCompileBody: self recompileCommandBody
		source: sourceText
]

{ #category : 'private' }
GbsRemoteUnboundMethodObject >> recompileCommandBody [
	^ '| behavior protocol result |
	cls ifNil: [ ^ ''ERROR|Class not found'' ].
	behavior := classSideValue ifTrue: [ cls class ] ifFalse: [ cls ].
	protocol := protocolValue ifNil: [ ''as yet unclassified'' ].
	result := [ behavior compileMethod: sourceValue category: protocol ] on: Error do: [ :ex | ''ERROR|'', ex description ].
	(result isString and: [ result beginsWith: ''ERROR|'' ]) ifTrue: [ ^ result ].
	(result isKindOf: Array) ifTrue: [ ^ ''ERROR|Compilation failed'' ].
	''OK'''
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> selector [
	^ mirror selector
]

{ #category : 'accessing' }
GbsRemoteUnboundMethodObject >> session [
	^ mirror session
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> sourceCode [
	^ mirror sourceCode
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> sourceLocation [
	^ mirror sourceLocation
]

{ #category : 'binding' }
GbsRemoteUnboundMethodObject >> unbind [
	^ self
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> version [
	^ mirror version
]

{ #category : 'querying' }
GbsRemoteUnboundMethodObject >> versionEntries [
	^ mirror versionEntries
]
