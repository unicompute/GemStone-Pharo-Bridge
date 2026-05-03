Class {
	#name : 'GbsRemoteBindingObject',
	#superclass : 'Object',
	#instVars : [
		'session',
		'procObject',
		'metadata'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRemoteBindingObject class >> on: aSession procObject: aProcObject metadata: aMetadataArray [
	^ self new
		session: aSession;
		procObject: aProcObject;
		metadata: aMetadataArray;
		yourself
]

{ #category : 'querying' }
GbsRemoteBindingObject >> capturedLocalCount [
	^ self localNames size
]

{ #category : 'querying' }
GbsRemoteBindingObject >> defaultEvaluationFileName [
	| location |
	location := self sourceLocation.
	location ifNil: [ ^ '<binding>' ].
	location := location asString.
	(location includes: $:) ifFalse: [ ^ location ].
	^ location copyUpToLast: $:
]

{ #category : 'querying' }
GbsRemoteBindingObject >> defaultEvaluationLineNumber [
	| location line |
	location := self sourceLocation.
	location ifNil: [ ^ 1 ].
	location := location asString.
	(location includes: $:) ifFalse: [ ^ 1 ].
	line := [ (location copyAfterLast: $:) asInteger ]
		on: Error
		do: [ 1 ].
	^ line ifNil: [ 1 ]
]

{ #category : 'printing' }
GbsRemoteBindingObject >> displayString [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'binding'.
		self sourceLocation ifNotNil: [
			stream
				nextPutAll: ' @ ';
				nextPutAll: self sourceLocation asString ].
		stream
			nextPutAll: ' locals=';
			nextPutAll: self capturedLocalCount printString.
		self methodDefTargetDisplayString ifNotNil: [
			stream
				nextPutAll: ' target=';
				nextPutAll: self methodDefTargetDisplayString asString ].
		self forModuleEval ifTrue: [
			stream nextPutAll: ' module-eval' ].
		self receiverOop ifNotNil: [
			stream
				nextPutAll: ' receiver=';
				nextPutAll: self receiverOop printString ] ]
]

{ #category : 'printing' }
GbsRemoteBindingObject >> closureIdentityString [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'binding'.
		self sourceLocation ifNotNil: [
			stream
				nextPutAll: '@';
				nextPutAll: self sourceLocation asString ].
		self lexicalPathDisplayString ifNotNil: [
			stream
				nextPutAll: ' in ';
				nextPutAll: self lexicalPathDisplayString asString ].
		self methodDefTargetDisplayString ifNotNil: [
			stream
				nextPutAll: ' target=';
				nextPutAll: self methodDefTargetDisplayString asString ] ]
]

{ #category : 'evaluation' }
GbsRemoteBindingObject >> evaluate: aString [
	^ self
		evaluate: aString
		fileName: self defaultEvaluationFileName
		lineNumber: self defaultEvaluationLineNumber
]

{ #category : 'evaluation' }
GbsRemoteBindingObject >> evaluate: aString fileName: aFileName lineNumber: aLineNumber [
	| sourceText lineValue |
	session ifNil: [ ^ nil ].
	procObject ifNil: [ ^ nil ].
	sourceText := aString
		ifNil: [ '' ]
		ifNotNil: [ aString asString ].
	lineValue := aLineNumber
		ifNil: [ 1 ]
		ifNotNil: [ [ aLineNumber asInteger ] on: Error do: [ 1 ] ].
	^ session executeScriptAndFetchObject: (self
		evaluationScriptFor: sourceText
		fileName: aFileName
		lineNumber: lineValue)
]

{ #category : 'private' }
GbsRemoteBindingObject >> evaluationScriptFor: aString fileName: aFileName lineNumber: aLineNumber [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[
		| obj binding result |
		obj := Object _objectForOop: '.
		stream nextPutAll: procObject oop asString.
		stream nextPutAll: '.
		obj ifNil: [ ^ nil ].
		binding := [ (obj respondsTo: #binding)
			ifTrue: [ obj binding ]
			ifFalse: [ nil ] ] on: Error do: [ nil ].
		binding ifNil: [ ^ nil ].
		result := binding
			perform: #eval
			withArguments: { '.
		stream nextPutAll: (session marshalArgumentToScript: aString).
		stream nextPutAll: ' . '.
		stream nextPutAll: (session marshalArgumentToScript: (aFileName ifNil: [ '<binding>' ] ifNotNil: [ aFileName asString ])).
		stream nextPutAll: ' . '.
		stream nextPutAll: (session marshalArgumentToScript: aLineNumber).
		stream nextPutAll: ' }.
		result
	] value' ]
]

{ #category : 'private' }
GbsRemoteBindingObject >> bindingScriptForBody: bodyString [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[
		| obj binding result |
		obj := Object _objectForOop: '.
		stream nextPutAll: procObject oop asString.
		stream nextPutAll: '.
		obj ifNil: [ ^ nil ].
		binding := [ (obj respondsTo: #binding)
			ifTrue: [ obj binding ]
			ifFalse: [ nil ] ] on: Error do: [ nil ].
		binding ifNil: [ ^ nil ].
		'.
		stream nextPutAll: bodyString.
		stream nextPutAll: '
	] value' ]
]

{ #category : 'private' }
GbsRemoteBindingObject >> executeBindingQuery: bodyString [
	session ifNil: [ ^ nil ].
	procObject ifNil: [ ^ nil ].
	^ session executeScriptAndFetchObject: (self bindingScriptForBody: bodyString)
]

{ #category : 'private' }
GbsRemoteBindingObject >> executeBindingOopQuery: bodyString [
	session ifNil: [ ^ nil ].
	procObject ifNil: [ ^ nil ].
	^ session executeScriptAndReturnOop: (self bindingScriptForBody: bodyString)
]

{ #category : 'testing' }
GbsRemoteBindingObject >> hasCapturedLocals [
	^ self localNames isEmpty not
]

{ #category : 'testing' }
GbsRemoteBindingObject >> hasLexicalPath [
	^ self lexicalPathDisplayString notNil
]

{ #category : 'testing' }
GbsRemoteBindingObject >> hasMethodDefTarget [
	^ self methodDefTargetDisplayString notNil
]

{ #category : 'testing' }
GbsRemoteBindingObject >> hasReceiver [
	^ self receiverOop notNil
]

{ #category : 'querying' }
GbsRemoteBindingObject >> forModuleEval [
	| raw |
	raw := self executeBindingQuery: 'result := [ (binding respondsTo: #forModuleEval)
			ifTrue: [ binding forModuleEval ]
			ifFalse: [ false ] ] on: Error do: [ false ].
		result'.
	raw ifNil: [ ^ false ].
	(raw == true or: [ raw == false ]) ifTrue: [ ^ raw ].
	^ raw asString asLowercase trimBoth = 'true'
]

{ #category : 'querying' }
GbsRemoteBindingObject >> localAssociations [
	| names oops displays |
	names := self localNames.
	oops := self localValueOops.
	displays := self localValueDisplayStrings.
	^ (1 to: names size) collect: [ :index |
		names at: index -> (self
			localValueAt: index
			oops: oops
			displays: displays) ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> localNames [
	| names |
	names := self metadataAt: 7 ifAbsent: [ #() ].
	^ names ifNil: [ #() ] ifNotNil: [ names asArray ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> localValueNamed: aName [
	| localName |
	aName ifNil: [ ^ nil ].
	localName := aName asString.
	(self localNames includes: localName) ifFalse: [ ^ nil ].
	^ self evaluate: localName
]

{ #category : 'actions' }
GbsRemoteBindingObject >> setLocalNamed: aName to: anObject [
	^ self
		setLocalNamed: aName
		toExpression: (session marshalArgumentToScript: anObject)
]

{ #category : 'actions' }
GbsRemoteBindingObject >> setLocalNamed: aName toExpression: anExpressionString [
	| localName expressionText |
	aName ifNil: [ ^ nil ].
	localName := aName asString.
	(self localNames includes: localName) ifFalse: [ ^ nil ].
	expressionText := anExpressionString
		ifNil: [ 'nil' ]
		ifNotNil: [ anExpressionString asString ].
	^ self evaluate: localName , ' = (' , expressionText , ')'
]

{ #category : 'private' }
GbsRemoteBindingObject >> localValueAt: anIndex oops: oopArray displays: displayArray [
	| oopValue |
	oopValue := oopArray at: anIndex ifAbsent: [ nil ].
	oopValue := [ oopValue asInteger ] on: Error do: [ oopValue ].
	(oopValue isInteger and: [ oopValue > 20 ]) ifTrue: [
		^ session objectForOop: oopValue ].
	^ displayArray at: anIndex ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> localValueDisplayStrings [
	| values |
	values := self metadataAt: 9 ifAbsent: [ #() ].
	^ values ifNil: [ #() ] ifNotNil: [ values asArray ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> localValueOops [
	| values |
	values := self metadataAt: 8 ifAbsent: [ #() ].
	^ values ifNil: [ #() ] ifNotNil: [ values asArray ]
]

{ #category : 'accessing' }
GbsRemoteBindingObject >> metadata [
	^ metadata ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRemoteBindingObject >> metadata: aCollection [
	metadata := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'private' }
GbsRemoteBindingObject >> metadataAt: anIndex ifAbsent: aBlock [
	^ self metadata at: anIndex ifAbsent: aBlock
]

{ #category : 'printing' }
GbsRemoteBindingObject >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsRemoteBindingObject >> procObject [
	^ procObject
]

{ #category : 'accessing' }
GbsRemoteBindingObject >> procObject: aProcObject [
	procObject := aProcObject
]

{ #category : 'querying' }
GbsRemoteBindingObject >> receiverOop [
	| raw |
	raw := self metadataAt: 6 ifAbsent: [ nil ].
	raw ifNil: [ ^ nil ].
	^ [ raw asInteger ] on: Error do: [ nil ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> receiverProxy [
	| oopValue |
	oopValue := self receiverOop.
	(oopValue isInteger and: [ oopValue > 20 ]) ifFalse: [ ^ nil ].
	^ session objectForOop: oopValue
]

{ #category : 'querying' }
GbsRemoteBindingObject >> selfProxy [
	^ self receiverProxy
]

{ #category : 'accessing' }
GbsRemoteBindingObject >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteBindingObject >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsRemoteBindingObject >> sourceLocation [
	^ procObject
		ifNil: [ nil ]
		ifNotNil: [ procObject sourceLocation ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> lexicalPathDisplayString [
	^ self executeBindingQuery: 'result := [ (binding respondsTo: #lexicalPath)
			ifTrue: [ | path |
				path := binding lexicalPath.
				path ifNil: [ nil ] ifNotNil: [ path printString ] ]
			ifFalse: [ nil ] ] on: Error do: [ nil ].
		result'
]

{ #category : 'querying' }
GbsRemoteBindingObject >> lexicalScopeAssociations [
	^ self localAssociations
]

{ #category : 'querying' }
GbsRemoteBindingObject >> lexicalScopeNames [
	^ self localNames
]

{ #category : 'printing' }
GbsRemoteBindingObject >> scopeSummaryLines [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Binding: ';
			nextPutAll: self displayString.
		self lexicalPathDisplayString ifNotNil: [
			stream
				cr;
				nextPutAll: 'Lexical Path: ';
				nextPutAll: self lexicalPathDisplayString asString ].
		self methodDefTargetDisplayString ifNotNil: [
			stream
				cr;
				nextPutAll: 'Method Target: ';
				nextPutAll: self methodDefTargetDisplayString asString ].
		self receiverOop ifNotNil: [
			stream
				cr;
				nextPutAll: 'Receiver OOP: ';
				nextPutAll: self receiverOop printString ].
		self localAssociations ifNotEmpty: [ :associations |
			stream cr; nextPutAll: 'Locals:'.
			associations do: [ :each |
				stream
					cr;
					nextPutAll: each key asString;
					nextPutAll: ' => ';
					nextPutAll: each value printString ] ] ]
]

{ #category : 'querying' }
GbsRemoteBindingObject >> methodDefTargetDisplayString [
	^ self executeBindingQuery: 'result := [ (binding respondsTo: #methodDefTarget)
			ifTrue: [ | target |
				target := binding methodDefTarget.
				target ifNil: [ nil ] ifNotNil: [ target printString ] ]
			ifFalse: [ nil ] ] on: Error do: [ nil ].
		result'
]

{ #category : 'querying' }
GbsRemoteBindingObject >> methodDefTargetOop [
	^ self executeBindingOopQuery: 'result := [ (binding respondsTo: #methodDefTarget)
			ifTrue: [ binding methodDefTarget ]
			ifFalse: [ nil ] ] on: Error do: [ nil ].
		result'
]

{ #category : 'querying' }
GbsRemoteBindingObject >> methodDefTargetProxy [
	| oopValue |
	oopValue := self methodDefTargetOop.
	(oopValue isInteger and: [ oopValue > 20 ]) ifFalse: [ ^ nil ].
	^ session objectForOop: oopValue
]

{ #category : 'printing' }
GbsRemoteBindingObject >> text [
	^ self scopeSummaryLines
]
