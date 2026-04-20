Class {
	#name : 'GbsRemoteProcObject',
	#superclass : 'Object',
	#instVars : [
		'session',
		'proxy',
		'metadata'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRemoteProcObject class >> on: aSession oop: anOop [
	| procObject procClass |
	procObject := self new
		session: aSession;
		proxy: (aSession objectForOop: anOop);
		yourself.
	self == GbsRemoteProcObject ifFalse: [ ^ procObject ].
	procClass := self procClassForMetadata: procObject metadata.
	^ procClass == self
		ifTrue: [ procObject ]
		ifFalse: [ procClass
			on: aSession
			oop: anOop
			metadata: procObject metadata ]
]

{ #category : 'instance creation' }
GbsRemoteProcObject class >> on: aSession object: anObject [
	| oopValue |
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #oop)
		ifFalse: [ ^ nil ].
	oopValue := anObject oop.
	oopValue ifNil: [ ^ nil ].
	^ self on: aSession oop: oopValue
]

{ #category : 'instance creation' }
GbsRemoteProcObject class >> on: aSession oop: anOop metadata: aMetadataArray [
	^ self new
		session: aSession;
		proxy: (aSession objectForOop: anOop);
		metadata: aMetadataArray;
		yourself
]

{ #category : 'instance creation' }
GbsRemoteProcObject class >> procClassForMetadata: aMetadataArray [
	((aMetadataArray at: 3 ifAbsent: [ false ]) == true) ifTrue: [
		^ GbsRemoteExecBlockObject ].
	^ self
]

{ #category : 'querying' }
GbsRemoteProcObject >> arity [
	| raw |
	raw := self metadataAt: 2.
	raw ifNil: [ ^ nil ].
	^ [ raw asInteger ] on: Error do: [ nil ]
]

{ #category : 'querying' }
GbsRemoteProcObject >> bindingDisplayString [
	self isExecBlock ifTrue: [ ^ 'execBlock' ].
	^ 'proc'
]

{ #category : 'querying' }
GbsRemoteProcObject >> bindingObject [
	^ GbsRemoteBindingObject
		on: self session
		procObject: self
		metadata: self metadata
]

{ #category : 'invocation' }
GbsRemoteProcObject >> call [
	^ self callWithArguments: #()
]

{ #category : 'invocation' }
GbsRemoteProcObject >> callWithArguments: anArray [
	| targetProxy |
	targetProxy := self proxy.
	targetProxy ifNil: [ self error: 'Remote proc is not available.' ].
	^ self session
		forwardRemoteMessage: (Message selector: #call arguments: anArray asArray)
		forOop: targetProxy oop
]

{ #category : 'querying' }
GbsRemoteProcObject >> className [
	^ self metadataAt: 1
]

{ #category : 'printing' }
GbsRemoteProcObject >> displayString [
	| nameText arityText |
	nameText := self className.
	nameText ifNil: [ nameText := 'Proc' ].
	arityText := self arity.
	arityText := arityText
		ifNil: [ '?' ]
		ifNotNil: [ arityText asString ].
	^ nameText asString , ' [arity=' , arityText , ']'
]

{ #category : 'printing' }
GbsRemoteProcObject >> closureIdentityString [
	^ self bindingObject closureIdentityString
]

{ #category : 'querying' }
GbsRemoteProcObject >> exists [
	^ self proxy notNil
]

{ #category : 'testing' }
GbsRemoteProcObject >> isExecBlock [
	^ self metadataAt: 3 ifAbsent: [ false ]
]

{ #category : 'testing' }
GbsRemoteProcObject >> isProc [
	^ self exists
]

{ #category : 'testing' }
GbsRemoteProcObject >> isLambdaLike [
	^ false
]

{ #category : 'querying' }
GbsRemoteProcObject >> localNames [
	^ self bindingObject localNames
]

{ #category : 'querying' }
GbsRemoteProcObject >> metadata [
	metadata ifNil: [
		metadata := session executeScriptAndFetchObject: self metadataScript ].
	^ metadata
]

{ #category : 'private' }
GbsRemoteProcObject >> metadataAt: anIndex [
	^ self metadataAt: anIndex ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsRemoteProcObject >> metadataAt: anIndex ifAbsent: aBlock [
	| valueArray |
	valueArray := self metadata.
	valueArray ifNil: [ ^ aBlock value ].
	^ valueArray at: anIndex ifAbsent: aBlock
]

{ #category : 'private' }
GbsRemoteProcObject >> metadataScript [
	^ String streamContents: [ :stream |
		stream nextPutAll: '['.
		stream nextPutAll: ' | obj clsName arityValue isExec sourceLocation sourceText receiverObj receiverOop bindingContext localNames localOops localDisplays names values limit localValue | '.
		stream nextPutAll: 'obj := Object _objectForOop: '.
		stream nextPutAll: self oop asString.
		stream nextPutAll: '. '.
		stream nextPutAll: 'obj ifNil: [ ^ nil ]. '.
		stream nextPutAll: 'clsName := [ obj class name asString ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'arityValue := [ obj arity ] on: Error do: [ [ obj numArgs ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'isExec := clsName notNil and: [ (clsName = ''ExecBlock'') or: [ clsName beginsWith: ''ExecBlock'' ] ]. '.
		stream nextPutAll: 'sourceLocation := [ obj sourcePositionAsString ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'sourceText := [ obj sourceString ] on: Error do: [ [ obj sourceCode ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'receiverObj := [ (obj respondsTo: #receiver) ifTrue: [ obj receiver ] ifFalse: [ (obj respondsTo: #selfValue) ifTrue: [ obj selfValue ] ifFalse: [ nil ] ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'receiverOop := receiverObj ifNil: [ nil ] ifNotNil: [ [ Reflection oopOf: receiverObj ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'bindingContext := [ (obj respondsTo: #context) ifTrue: [ obj context ] ifFalse: [ (obj respondsTo: #homeContext) ifTrue: [ obj homeContext ] ifFalse: [ nil ] ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'localNames := OrderedCollection new. localOops := OrderedCollection new. localDisplays := OrderedCollection new. '.
		stream nextPutAll: 'bindingContext ifNotNil: [ [ names := (bindingContext respondsTo: #tempNames) ifTrue: [ bindingContext tempNames ] ifFalse: [ #() ]. values := (bindingContext respondsTo: #temps) ifTrue: [ bindingContext temps ] ifFalse: [ #() ]. limit := names size min: values size. 1 to: limit do: [ :i | localValue := [ values at: i ] on: Error do: [ nil ]. localNames add: ((names at: i) asString). localOops add: (localValue ifNil: [ nil ] ifNotNil: [ [ Reflection oopOf: localValue ] on: Error do: [ nil ] ]). localDisplays add: (localValue ifNil: [ nil ] ifNotNil: [ [ localValue printString ] on: Error do: [ nil ] ]) ] ] on: Error do: [ ] ]. '.
		stream nextPutAll: 'Array with: clsName with: arityValue with: isExec with: sourceLocation with: sourceText with: receiverOop with: localNames asArray with: localOops asArray with: localDisplays asArray'.
		stream nextPutAll: ' ] value'
	]
]

{ #category : 'querying' }
GbsRemoteProcObject >> oop [
	proxy ifNil: [ ^ nil ].
	^ proxy oop
]

{ #category : 'querying' }
GbsRemoteProcObject >> receiverOop [
	^ self bindingObject receiverOop
]

{ #category : 'querying' }
GbsRemoteProcObject >> receiverProxy [
	^ self bindingObject receiverProxy
]

{ #category : 'printing' }
GbsRemoteProcObject >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsRemoteProcObject >> proxy [
	^ proxy
]

{ #category : 'accessing' }
GbsRemoteProcObject >> proxy: aProxy [
	proxy := aProxy
]

{ #category : 'querying' }
GbsRemoteProcObject >> sourceCode [
	^ self metadataAt: 5
]

{ #category : 'querying' }
GbsRemoteProcObject >> sourceLocation [
	^ self metadataAt: 4
]

{ #category : 'testing' }
GbsRemoteProcObject >> hasCapturedLocals [
	^ self bindingObject hasCapturedLocals
]

{ #category : 'printing' }
GbsRemoteProcObject >> text [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self displayString;
			cr;
			nextPutAll: self bindingObject text ]
]

{ #category : 'accessing' }
GbsRemoteProcObject >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteProcObject >> session: aSession [
	session := aSession
]

{ #category : 'converting' }
GbsRemoteProcObject >> toProc [
	^ self
]

{ #category : 'invocation' }
GbsRemoteProcObject >> value [
	^ self call
]

{ #category : 'invocation' }
GbsRemoteProcObject >> value: argOne [
	^ self callWithArguments: (Array with: argOne)
]

{ #category : 'invocation' }
GbsRemoteProcObject >> value: argOne value: argTwo [
	^ self callWithArguments: (Array with: argOne with: argTwo)
]

{ #category : 'invocation' }
GbsRemoteProcObject >> value: argOne value: argTwo value: argThree [
	^ self callWithArguments: (Array
		with: argOne
		with: argTwo
		with: argThree)
]
