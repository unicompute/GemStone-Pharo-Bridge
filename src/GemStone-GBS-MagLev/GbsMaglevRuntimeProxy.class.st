Class {
	#name : 'GbsMaglevRuntimeProxy',
	#superclass : 'GbsProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemote: bodyString [
	^ self
		executeAgainstRemote: bodyString
		literalBindings: Dictionary new
]

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemote: bodyString literalBindings: literalDictionary [
	session ifNil: [ ^ nil ].
	^ session fetchRemoteCommand: (GbsRemoteCommand
		blockBody: bodyString
		literalBindings: literalDictionary
		oopBindings: (Dictionary new
			at: 'obj' put: self oop;
			yourself))
]

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemoteReturningOop: bodyString [
	session ifNil: [ ^ nil ].
	^ session returnRemoteCommandOop: (GbsRemoteCommand
		blockBody: bodyString
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'obj' put: self oop;
			yourself))
]

{ #category : 'printing' }
GbsMaglevRuntimeProxy >> printOn: aStream [
	aStream
		nextPutAll: 'a';
		nextPutAll: self class name;
		nextPutAll: '(oop: '.
	aStream print: self oop.
	aStream nextPut: $)
]
