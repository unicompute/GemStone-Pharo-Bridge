Class {
	#name : 'GbsMaglevRuntimeProxy',
	#superclass : 'GbsProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemote: bodyString [
	session ifNil: [ ^ nil ].
	^ session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: '[:obj | ';
			nextPutAll: bodyString;
			nextPutAll: ' ] value: (Object _objectForOop: ';
			nextPutAll: self oop asString;
			nextPutAll: ')' ])
]

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemoteReturningOop: bodyString [
	session ifNil: [ ^ nil ].
	^ session executeScriptAndReturnOop: (String streamContents: [ :stream |
		stream
			nextPutAll: '[:obj | ';
			nextPutAll: bodyString;
			nextPutAll: ' ] value: (Object _objectForOop: ';
			nextPutAll: self oop asString;
			nextPutAll: ')' ])
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
