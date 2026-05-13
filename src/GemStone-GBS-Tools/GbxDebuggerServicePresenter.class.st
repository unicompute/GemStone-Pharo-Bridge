Class {
	#name : 'GbxDebuggerServicePresenter',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'stack' }
GbxDebuggerServicePresenter class >> notifierStackStringOfSize: n for: service [
	| contexts stream label |
	contexts := service contextList.
	label := service label.
	contexts ifEmpty: [ ^ label ifNil: [ '' ] ].
	stream := WriteStream on: String new.
	stream
		nextPutAll: (label ifNil: [ 'Debugger' ]);
		cr.
	1 to: (n min: contexts size) do: [ :i |
		| ctx |
		ctx := contexts at: i.
		stream
			tab;
			nextPutAll: ((ctx respondsTo: #printString) ifTrue: [ ctx printString ] ifFalse: [ ctx asString ]);
			cr ].
	^ stream contents
]

{ #category : 'context' }
GbxDebuggerServicePresenter class >> pendingMessageForContext: currentContext [
	| receiver selector numArgs message messageClass |
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #pdpWillSend) ifTrue: [
		currentContext pdpWillSend ifFalse: [ ^ nil ] ].
	receiver := (currentContext respondsTo: #gbxPeekForReceiver)
		ifTrue: [ currentContext gbxPeekForReceiver ]
		ifFalse: [ currentContext receiver ].
	selector := (currentContext respondsTo: #peekForSelector)
		ifTrue: [ currentContext peekForSelector ]
		ifFalse: [ nil ].
	selector ifNil: [ ^ nil ].
	numArgs := selector numArgs.
	messageClass := Smalltalk at: #MessageSend ifAbsent: [ ^ nil ].
	messageClass ifNil: [ ^ nil ].
	message := messageClass receiver: receiver selector: selector arguments: (Array new: numArgs).
	1 to: numArgs do: [ :i | message argumentAt: i put: currentContext ].
	^ message
]

{ #category : 'converting' }
GbxDebuggerServicePresenter class >> presenterTextFrom: aValue [
	aValue ifNil: [ ^ '' ].
	(aValue isString or: [ aValue isSymbol ]) ifTrue: [ ^ aValue asString ].
	(aValue respondsTo: #asLocalString) ifTrue: [ ^ aValue asLocalString asString ].
	(aValue respondsTo: #asString) ifTrue: [ ^ aValue asString ].
	^ aValue printString
]

{ #category : 'context' }
GbxDebuggerServicePresenter class >> recomputeContextListFor: service [
	| contextStackPolicy currentContext contexts refreshed |
	contextStackPolicy := service contextStackPolicy.
	currentContext := service currentContext.
	contextStackPolicy ifNil: [
		service updateSourceMapFromCurrentContext.
		service notifyContextChanged.
		^ service ].
	contextStackPolicy computeContextList.
	contexts := contextStackPolicy contextList.
	currentContext isNil
		ifTrue: [ contexts ifNotEmpty: [ :list | service currentContext: list first ] ]
		ifFalse: [
			refreshed := contexts
				detect: [ :each | (each == currentContext) or: [ each = currentContext ] ]
				ifNone: [ nil ].
			refreshed
				ifNil: [ contexts ifNotEmpty: [ :list | service currentContext: list first ] ]
				ifNotNil: [ service currentContext: refreshed ] ].
	service updateSourceMapFromCurrentContext.
	service notifyContextChanged
]

{ #category : 'stack' }
GbxDebuggerServicePresenter class >> stackForCopySimpleFor: service [
	| contexts stream label |
	contexts := service contextList.
	label := service label.
	contexts ifEmpty: [ ^ label ifNil: [ '' ] ].
	stream := WriteStream on: String new.
	stream
		nextPutAll: (label ifNil: [ 'Debugger' ]);
		cr;
		cr.
	1 to: contexts size do: [ :i |
		| ctx |
		ctx := contexts at: i.
		stream
			nextPutAll: i asString;
			nextPutAll: '. ';
			nextPutAll: ((ctx respondsTo: #printString) ifTrue: [ ctx printString ] ifFalse: [ ctx asString ]);
			cr ].
	^ stream contents
]
