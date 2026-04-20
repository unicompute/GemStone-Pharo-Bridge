Class {
	#name : 'GbsRemoteExecBlockObject',
	#superclass : 'GbsRemoteProcObject',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'querying' }
GbsRemoteExecBlockObject >> bindingDisplayString [
	^ 'execBlock'
]

{ #category : 'invocation' }
GbsRemoteExecBlockObject >> callWithArguments: anArray [
	| argumentCount expectedArity |
	argumentCount := anArray ifNil: [ 0 ] ifNotNil: [ anArray asArray size ].
	expectedArity := self arity.
	(expectedArity isInteger and: [ expectedArity >= 0 and: [ argumentCount ~= expectedArity ] ])
		ifTrue: [ self error: 'ExecBlock expects ', expectedArity asString, ' argument(s).' ].
	^ super callWithArguments: anArray
]

{ #category : 'testing' }
GbsRemoteExecBlockObject >> isExecBlock [
	^ true
]

{ #category : 'testing' }
GbsRemoteExecBlockObject >> isLambdaLike [
	^ true
]
