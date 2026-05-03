Class {
	#name : 'GbsSessionStateSlot',
	#superclass : 'Object',
	#instVars : [
		'key',
		'label',
		'value',
		'diagnostics',
		'aliasNames',
		'wellKnown',
		'discoverySource',
		'tags'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionStateSlot class >> key: anInteger label: aString value: anObject diagnostics: aDiagnosticsFacade [
	^ self new
		key: anInteger;
		label: aString;
		value: anObject;
		diagnostics: aDiagnosticsFacade;
		yourself
]

{ #category : 'accessing' }
GbsSessionStateSlot >> diagnostics [
	^ diagnostics
]

{ #category : 'accessing' }
GbsSessionStateSlot >> diagnostics: aDiagnosticsFacade [
	diagnostics := aDiagnosticsFacade
]

{ #category : 'accessing' }
GbsSessionStateSlot >> discoverySource [
	^ discoverySource ifNil: [ #discovered ]
]

{ #category : 'accessing' }
GbsSessionStateSlot >> discoverySource: anObject [
	discoverySource := anObject ifNil: [ #discovered ] ifNotNil: [ anObject ]
]

{ #category : 'accessing' }
GbsSessionStateSlot >> aliasNames [
	^ aliasNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsSessionStateSlot >> aliasNames: aCollection [
	aliasNames := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'querying' }
GbsSessionStateSlot >> displayName [
	^ 'Key ', key printString, ' (', label, ')'
]

{ #category : 'querying' }
GbsSessionStateSlot >> exists [
	^ value notNil and: [ (value isKindOf: Error) not ]
]

{ #category : 'querying' }
GbsSessionStateSlot >> hasInspectableOop [
	^ self oop isInteger and: [ self oop > 20 ]
]

{ #category : 'querying' }
GbsSessionStateSlot >> hasAliasNamed: aString [
	aString ifNil: [ ^ false ].
	^ self aliasNames anySatisfy: [ :each | each = aString asString ]
]

{ #category : 'querying' }
GbsSessionStateSlot >> hasTag: aSymbolOrString [
	aSymbolOrString ifNil: [ ^ false ].
	^ self tags anySatisfy: [ :each |
		each asString = aSymbolOrString asString ]
]

{ #category : 'testing' }
GbsSessionStateSlot >> isCacheSlot [
	^ false
]

{ #category : 'testing' }
GbsSessionStateSlot >> isRegistrySlot [
	^ false
]

{ #category : 'testing' }
GbsSessionStateSlot >> isThreadStateSlot [
	^ false
]

{ #category : 'testing' }
GbsSessionStateSlot >> isWellKnown [
	^ wellKnown == true
]

{ #category : 'accessing' }
GbsSessionStateSlot >> key [
	^ key
]

{ #category : 'accessing' }
GbsSessionStateSlot >> key: anInteger [
	key := anInteger
]

{ #category : 'accessing' }
GbsSessionStateSlot >> label [
	^ label
]

{ #category : 'accessing' }
GbsSessionStateSlot >> label: aString [
	label := aString ifNil: [ 'Session State' ] ifNotNil: [ aString asString ]
]

{ #category : 'querying' }
GbsSessionStateSlot >> oop [
	^ (value respondsTo: #oop)
		ifTrue: [ value oop ]
		ifFalse: [ nil ]
]

{ #category : 'printing' }
GbsSessionStateSlot >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self summaryLine;
		nextPut: $)
]

{ #category : 'querying' }
GbsSessionStateSlot >> size [
	^ [
		((value respondsTo: #size) and: [ value class ~~ GbsProxy ])
			ifTrue: [ value size ]
			ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'querying' }
GbsSessionStateSlot >> summaryLine [
	^ diagnostics
		summaryLineFor: value
		label: self displayName
]

{ #category : 'querying' }
GbsSessionStateSlot >> slotKind [
	^ #sessionState
]

{ #category : 'accessing' }
GbsSessionStateSlot >> tags [
	^ tags ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsSessionStateSlot >> tags: aCollection [
	tags := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
GbsSessionStateSlot >> value [
	^ value
]

{ #category : 'accessing' }
GbsSessionStateSlot >> value: anObject [
	value := anObject
]

{ #category : 'accessing' }
GbsSessionStateSlot >> wellKnown [
	^ self isWellKnown
]

{ #category : 'accessing' }
GbsSessionStateSlot >> wellKnown: aBoolean [
	wellKnown := aBoolean == true
]
