Class {
	#name : 'GbsNamespaceScopedMethodQuery',
	#superclass : 'Object',
	#instVars : [
		'session',
		'namespace',
		'mode',
		'queryValue',
		'references',
	'title'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsNamespaceScopedMethodQuery class >> session: aSession namespace: aNamespaceMirror mode: aSymbol queryValue: aValue references: aCollection title: aString [
	^ self new
		session: aSession;
		namespace: aNamespaceMirror;
		mode: aSymbol;
		queryValue: aValue;
		references: aCollection;
		title: aString;
		yourself
]

{ #category : 'querying' }
GbsNamespaceScopedMethodQuery >> count [
	^ self references size
]

{ #category : 'querying' }
GbsNamespaceScopedMethodQuery >> isEmpty [
	^ self references isEmpty
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> mode [
	^ mode ifNil: [ #references ]
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> mode: aSymbol [
	mode := aSymbol ifNil: [ #references ] ifNotNil: [ aSymbol asSymbol ]
]

{ #category : 'querying' }
GbsNamespaceScopedMethodQuery >> methodMirrorForReference: referenceString [
	| split classPart selectorPart classSide className classMirror |
	referenceString ifNil: [ ^ nil ].
	(referenceString includesSubstring: '>>') ifFalse: [ ^ nil ].
	split := referenceString findString: '>>' startingAt: 1.
	classPart := (referenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (referenceString copyFrom: split + 2 to: referenceString size) trimBoth.
	selectorPart isEmpty ifTrue: [ ^ nil ].
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	className isEmpty ifTrue: [ ^ nil ].
	classMirror := session classMirrorOf: className.
	classMirror ifNil: [ ^ nil ].
	^ classSide
		ifTrue: [ classMirror classMethodMirrorAt: selectorPart asSymbol ]
		ifFalse: [ classMirror methodMirrorAt: selectorPart asSymbol ]
]

{ #category : 'querying' }
GbsNamespaceScopedMethodQuery >> methodMirrors [
	^ self references collect: [ :each |
		[ self methodMirrorForReference: each ]
			on: Error
			do: [ :ex | nil ] ]
]

{ #category : 'querying' }
GbsNamespaceScopedMethodQuery >> methodObjectForReference: referenceString [
	| split classPart selectorPart classSide className |
	referenceString ifNil: [ ^ nil ].
	(referenceString includesSubstring: '>>') ifFalse: [ ^ nil ].
	split := referenceString findString: '>>' startingAt: 1.
	classPart := (referenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (referenceString copyFrom: split + 2 to: referenceString size) trimBoth.
	selectorPart isEmpty ifTrue: [ ^ nil ].
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	className isEmpty ifTrue: [ ^ nil ].
	^ classSide
		ifTrue: [ session classMethodObjectForClassNamed: className selector: selectorPart asSymbol ]
		ifFalse: [ session methodObjectForClassNamed: className selector: selectorPart asSymbol ]
]

{ #category : 'querying' }
GbsNamespaceScopedMethodQuery >> methodObjects [
	^ self references collect: [ :each |
		[ self methodObjectForReference: each ]
			on: Error
			do: [ :ex | nil ] ]
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> namespace [
	^ namespace
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> namespace: aNamespaceMirror [
	namespace := aNamespaceMirror
]

{ #category : 'printing' }
GbsNamespaceScopedMethodQuery >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self title;
		nextPut: $)
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> queryValue [
	^ queryValue
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> queryValue: anObject [
	queryValue := anObject
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> references [
	^ references ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> references: aCollection [
	references := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> session [
	^ session
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> title [
	^ title ifNil: [ 'Namespace Query' ]
]

{ #category : 'accessing' }
GbsNamespaceScopedMethodQuery >> title: aString [
	title := aString ifNil: [ 'Namespace Query' ] ifNotNil: [ aString asString ]
]
