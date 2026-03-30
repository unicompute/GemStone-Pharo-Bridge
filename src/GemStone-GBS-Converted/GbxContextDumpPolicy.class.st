Class {
	#name : 'GbxContextDumpPolicy',
	#superclass : 'Object',
	#instVars : [
		'stack',
		'stream',
		'errorMessage',
		'verbose'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxContextDumpPolicy >> actualNumberToDump [
	^ stack ifNil: [ 0 ] ifNotNil: [ stack size ]
]

{ #category : 'accessing' }
GbxContextDumpPolicy >> copyStackString [
	stream := WriteStream on: String new.
	errorMessage ifNotNil: [
		stream nextPutAll: errorMessage asString.
		stream cr; cr ].
	(verbose ifNil: [ false ])
		ifTrue: [ self printVerboseStack ]
		ifFalse: [ self printSimpleStack ].
	^ stream contents
]

{ #category : 'accessing' }
GbxContextDumpPolicy >> errorMessage: aString [
	errorMessage := aString
]

{ #category : 'private' }
GbxContextDumpPolicy >> printContext: aContext count: anInteger verbose: aBoolean [
	stream
		nextPutAll: anInteger asString;
		nextPutAll: '. ';
		nextPutAll: (self shortDescriptionFor: aContext).
	aBoolean ifTrue: [
		| extras |
		extras := self verboseFragmentsFor: aContext.
		extras isEmpty ifFalse: [
			stream nextPutAll: ' ['.
			stream nextPutAll: (', ' join: extras).
			stream nextPut: $] ] ].
	stream cr
]

{ #category : 'visitor printing' }
GbxContextDumpPolicy >> printProxy: anObject [
	(anObject respondsTo: #gbxDebugPrintOn:)
		ifTrue: [ anObject gbxDebugPrintOn: stream ]
		ifFalse: [ stream nextPutAll: anObject printString ]
]

{ #category : 'printing' }
GbxContextDumpPolicy >> printSimpleStack [
	1 to: self actualNumberToDump do: [ :index |
		self printContext: (stack at: index) count: index verbose: false ]
]

{ #category : 'private printing' }
GbxContextDumpPolicy >> printVerboseStack [
	1 to: self actualNumberToDump do: [ :index |
		self printContext: (stack at: index) count: index verbose: true ]
]

{ #category : 'accessing' }
GbxContextDumpPolicy >> stack: aCollection [
	stack := aCollection ifNil: [ #() ]
]

{ #category : 'private' }
GbxContextDumpPolicy >> shortDescriptionFor: aContext [
	(aContext respondsTo: #methodClass) ifTrue: [
		| className selector |
		className := [ aContext methodClass ] on: Error do: [ nil ].
		selector := [ aContext selector ] on: Error do: [ nil ].
		(className notNil or: [ selector notNil ]) ifTrue: [
			^ String streamContents: [ :s |
				className ifNotNil: [ s nextPutAll: className asString ].
				selector ifNotNil: [
					className ifNotNil: [ s nextPutAll: '>>' ].
					s nextPutAll: selector asString ] ] ] ].
	(aContext respondsTo: #printString) ifTrue: [ ^ aContext printString ].
	^ aContext asString
]

{ #category : 'accessing' }
GbxContextDumpPolicy >> verbose: aBoolean [
	verbose := aBoolean
]

{ #category : 'private' }
GbxContextDumpPolicy >> verboseFragmentsFor: aContext [
	| fragments |
	fragments := OrderedCollection new.
	(aContext respondsTo: #processOop) ifTrue: [
		| oop |
		oop := [ aContext processOop ] on: Error do: [ nil ].
		oop ifNotNil: [ fragments add: 'process=', oop asString ] ].
	(aContext respondsTo: #receiverClassOrUnknown) ifTrue: [
		| receiverName |
		receiverName := [ aContext receiverClassOrUnknown ] on: Error do: [ nil ].
		receiverName ifNotNil: [ fragments add: 'receiver=', receiverName asString ] ].
	(aContext respondsTo: #selfOop) ifTrue: [
		| selfOop |
		selfOop := [ aContext selfOop ] on: Error do: [ nil ].
		selfOop ifNotNil: [ fragments add: 'selfOop=', selfOop asString ] ].
	^ fragments asArray
]
