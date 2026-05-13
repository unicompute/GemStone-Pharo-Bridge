Class {
	#name : 'GbsMaglevRuntimeProxy',
	#superclass : 'GbsProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemote: bodyString [
	session ifNil: [ ^ nil ].
	^ (GbsRemoteCommand
		blockBody: bodyString
		argumentNames: #('obj')
		argumentScripts: { GbsRemoteScriptBuilder objectForOop: self oop })
		executeAndFetchObjectIn: session
]

{ #category : 'private' }
GbsMaglevRuntimeProxy >> executeAgainstRemoteReturningOop: bodyString [
	session ifNil: [ ^ nil ].
	^ (GbsRemoteCommand
		blockBody: bodyString
		argumentNames: #('obj')
		argumentScripts: { GbsRemoteScriptBuilder objectForOop: self oop })
		executeAndReturnOopIn: session
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
