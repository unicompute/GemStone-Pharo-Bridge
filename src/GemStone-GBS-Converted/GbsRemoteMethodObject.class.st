Class {
	#name : 'GbsRemoteMethodObject',
	#superclass : 'Object',
	#instVars : [
		'mirror',
		'receiverProxy'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsRemoteMethodObject class >> on: aSession class: aClassOrName selector: aSelector classSide: aBoolean [
	^ self
		onMirror: (GbsRemoteMethodMirror
			on: aSession
			class: aClassOrName
			selector: aSelector
			classSide: aBoolean)
]

{ #category : 'argument parsing' }
GbsRemoteMethodObject class >> argumentsFromInput: inputString expectedCount: argumentCount [
	| trimmed value |
	trimmed := inputString
		ifNil: [ '' ]
		ifNotNil: [ inputString asString trimBoth ].
	trimmed isEmpty ifTrue: [
		^ argumentCount = 0
			ifTrue: [ #() ]
			ifFalse: [ self error: 'Expected ', argumentCount asString, ' argument(s).' ] ].
	value := [ Smalltalk compiler evaluate: trimmed ]
		on: Error
		do: [ :ex | self error: 'Could not parse arguments: ', ex messageText ].
	^ self normalizedArgumentsFromValue: value expectedCount: argumentCount
]

{ #category : 'argument parsing' }
GbsRemoteMethodObject class >> normalizedArgumentsFromValue: value expectedCount: argumentCount [
	argumentCount = 0 ifTrue: [ ^ #() ].
	argumentCount = 1 ifTrue: [
		((value isArray) or: [ value isKindOf: OrderedCollection ]) ifTrue: [
			value size = 1 ifTrue: [ ^ value asArray ] ].
		^ { value } ].
	((value isArray) or: [ value isKindOf: OrderedCollection ]) ifFalse: [
		self error: 'Enter a Smalltalk array with ', argumentCount asString, ' arguments.' ].
	value size = argumentCount ifFalse: [
		self error: 'Expected ', argumentCount asString, ' arguments but got ', value size asString, '.' ].
	^ value asArray
]

{ #category : 'argument parsing' }
GbsRemoteMethodObject class >> defaultArgumentInputForCount: argumentCount [
	argumentCount <= 1 ifTrue: [ ^ '' ].
	^ '#()'
]

{ #category : 'argument parsing' }
GbsRemoteMethodObject class >> invocationPromptForSelector: aSelector argumentCount: argumentCount [
	argumentCount = 0 ifTrue: [
		^ 'Invoke ', aSelector asString, ' in GemStone?' ].
	argumentCount = 1 ifTrue: [
		^ 'Enter 1 argument for ', aSelector asString, ' as a Smalltalk expression:' ].
	^ 'Enter ', argumentCount asString, ' arguments for ', aSelector asString, ' as a Smalltalk array or OrderedCollection:'
]

{ #category : 'instance creation' }
GbsRemoteMethodObject class >> onMirror: aRemoteMethodMirror [
	^ self
		onMirror: aRemoteMethodMirror
		receiver: nil
]

{ #category : 'instance creation' }
GbsRemoteMethodObject class >> onMirror: aRemoteMethodMirror receiver: aReceiverProxy [
	^ self new
		mirror: aRemoteMethodMirror;
		receiverProxy: aReceiverProxy;
		yourself
]

{ #category : 'binding' }
GbsRemoteMethodObject >> bindTo: aReceiver [
	^ self class
		onMirror: mirror
		receiver: (self normalizedReceiverProxyFrom: aReceiver)
]

{ #category : 'querying' }
GbsRemoteMethodObject >> argumentCount [
	^ self selector numArgs
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> call [
	^ self callWithArguments: #()
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> callOn: aReceiver [
	^ self
		callOn: aReceiver
		arguments: #()
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> callOn: aReceiver arguments: anArray [
	| targetProxy |
	targetProxy := self normalizedReceiverProxyFrom: aReceiver.
	^ self session
		forwardRemoteMessage: (Message selector: self selector arguments: anArray asArray)
		forOop: targetProxy oop
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> callWithArguments: anArray [
	| targetProxy |
	targetProxy := self effectiveReceiverProxy.
	^ self session
		forwardRemoteMessage: (Message selector: self selector arguments: anArray asArray)
		forOop: targetProxy oop
]

{ #category : 'querying' }
GbsRemoteMethodObject >> classHistory [
	^ mirror classHistory
]

{ #category : 'querying' }
GbsRemoteMethodObject >> classMirror [
	^ mirror classMirror
]

{ #category : 'querying' }
GbsRemoteMethodObject >> classReference [
	^ mirror classReference
]

{ #category : 'querying' }
GbsRemoteMethodObject >> categoryName [
	^ self protocol
]

{ #category : 'querying' }
GbsRemoteMethodObject >> classSide [
	^ mirror classSide
]

{ #category : 'comparing' }
GbsRemoteMethodObject >> = anObject [
	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ self session == anObject session
		and: [ self ownerName = anObject ownerName
		and: [ self selector = anObject selector
		and: [ self classSide = anObject classSide
		and: [ self receiverOopForIdentity = anObject receiverOopForIdentity ] ] ] ]
]

{ #category : 'private' }
GbsRemoteMethodObject >> effectiveReceiverProxy [
	receiverProxy ifNotNil: [ ^ receiverProxy ].
	self classSide ifTrue: [ ^ self classMirror proxy ].
	self error: 'Remote instance method is not bound to a receiver.'
]

{ #category : 'querying' }
GbsRemoteMethodObject >> exists [
	^ mirror exists
]

{ #category : 'comparing' }
GbsRemoteMethodObject >> hash [
	^ { self session identityHash. self ownerName. self selector. self classSide. self receiverOopForIdentity } hash
]

{ #category : 'testing' }
GbsRemoteMethodObject >> isClassSide [
	^ self classSide
]

{ #category : 'testing' }
GbsRemoteMethodObject >> isBound [
	^ receiverProxy ~~ nil
]

{ #category : 'testing' }
GbsRemoteMethodObject >> isInstanceSide [
	^ self classSide not
]

{ #category : 'querying' }
GbsRemoteMethodObject >> name [
	^ String streamContents: [ :stream |
		self ownerName ifNotNil: [ stream nextPutAll: self ownerName ].
		stream
			nextPutAll: '>>';
			nextPutAll: self selector asString ]
]

{ #category : 'accessing' }
GbsRemoteMethodObject >> methodMetadata [
	^ mirror methodMetadata
]

{ #category : 'accessing' }
GbsRemoteMethodObject >> mirror [
	^ mirror
]

{ #category : 'accessing' }
GbsRemoteMethodObject >> mirror: aRemoteMethodMirror [
	mirror := aRemoteMethodMirror
]

{ #category : 'private' }
GbsRemoteMethodObject >> normalizedReceiverProxyFrom: aReceiver [
	| candidate candidateSession candidateOop |
	aReceiver ifNil: [ self error: 'Receiver must not be nil.' ].
	candidate := aReceiver.
	(aReceiver respondsTo: #proxy) ifTrue: [
		| proxy |
		proxy := aReceiver proxy.
		proxy ifNotNil: [ candidate := proxy ] ].
	candidateSession := (candidate respondsTo: #session)
		ifTrue: [ candidate session ]
		ifFalse: [ nil ].
	(candidateSession notNil and: [ candidateSession ~~ self session ]) ifTrue: [
		self error: 'Receiver belongs to a different GemStone session.' ].
	candidateOop := (candidate respondsTo: #oop)
		ifTrue: [ candidate oop ]
		ifFalse: [ nil ].
	candidateOop ifNil: [
		self error: 'Receiver must be a remote GemStone object or proxy.' ].
	^ self session objectForOop: candidateOop
]

{ #category : 'querying' }
GbsRemoteMethodObject >> numberOfVersions [
	^ mirror numberOfVersions
]

{ #category : 'querying' }
GbsRemoteMethodObject >> oop [
	^ mirror oop
]

{ #category : 'querying' }
GbsRemoteMethodObject >> ownerName [
	^ mirror ownerName
]

{ #category : 'querying' }
GbsRemoteMethodObject >> ownerProxy [
	^ self classMirror
		ifNil: [ nil ]
		ifNotNil: [ :each | each proxy ]
]

{ #category : 'querying' }
GbsRemoteMethodObject >> packageName [
	^ mirror packageName
]

{ #category : 'printing' }
GbsRemoteMethodObject >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self ownerName;
			nextPutAll: '>>';
			nextPutAll: self selector asString.
		self isBound ifTrue: [
			stream
				nextPutAll: ' @';
				nextPutAll: self receiver oop printString ] ]
]

{ #category : 'querying' }
GbsRemoteMethodObject >> protocol [
	^ mirror protocol
]

{ #category : 'printing' }
GbsRemoteMethodObject >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self ownerName;
		nextPutAll: '>>';
		nextPutAll: self selector asString.
	self isBound ifTrue: [
		aStream
			nextPutAll: ' @';
			nextPutAll: self receiver oop printString ].
	aStream nextPut: $)
]

{ #category : 'querying' }
GbsRemoteMethodObject >> proxy [
	^ mirror proxy
]

{ #category : 'accessing' }
GbsRemoteMethodObject >> receiver [
	^ receiverProxy
]

{ #category : 'binding' }
GbsRemoteMethodObject >> rebindTo: aReceiver [
	^ self bindTo: aReceiver
]

{ #category : 'private' }
GbsRemoteMethodObject >> receiverOopForIdentity [
	^ receiverProxy
		ifNil: [ nil ]
		ifNotNil: [ receiverProxy oop ]
]

{ #category : 'accessing' }
GbsRemoteMethodObject >> receiverProxy: aReceiverProxy [
	receiverProxy := aReceiverProxy
]

{ #category : 'querying' }
GbsRemoteMethodObject >> selector [
	^ mirror selector
]

{ #category : 'accessing' }
GbsRemoteMethodObject >> session [
	^ mirror session
]

{ #category : 'querying' }
GbsRemoteMethodObject >> sourceCode [
	^ mirror sourceCode
]

{ #category : 'querying' }
GbsRemoteMethodObject >> sourceLocation [
	^ mirror sourceLocation
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> value [
	^ self call
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> value: anArgument [
	^ self callWithArguments: { anArgument }
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> value: firstArgument value: secondArgument [
	^ self callWithArguments: { firstArgument. secondArgument }
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> value: firstArgument value: secondArgument value: thirdArgument [
	^ self callWithArguments: { firstArgument. secondArgument. thirdArgument }
]

{ #category : 'binding' }
GbsRemoteMethodObject >> unbind [
	^ self class
		onMirror: mirror
		receiver: nil
]

{ #category : 'invocation' }
GbsRemoteMethodObject >> valueWithArguments: anArray [
	^ self callWithArguments: anArray
]

{ #category : 'querying' }
GbsRemoteMethodObject >> version [
	^ mirror version
]

{ #category : 'querying' }
GbsRemoteMethodObject >> versionEntries [
	^ mirror versionEntries
]
