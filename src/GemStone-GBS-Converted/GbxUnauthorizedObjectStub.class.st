Class {
	#name : 'GbxUnauthorizedObjectStub',
	#superclass : 'GbxObjectStub',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'faulting' }
GbxUnauthorizedObjectStub >> faultToLevel: levelOrNil session: session delegate: delegate
[
	"A 32-bit server will just give another nil-class report on an attempt to unstub, 
	and a 64-bit server with unauthorized object stubs enabled will give a report for the stub. 
	What we're after is an error from the server if we still do not have read access to the object,
	so we use evaluateBlock to force the issue."

	| level blockSource |
	level := levelOrNil == nil
				ifTrue: [session defaultGStoSTLevel]
				ifFalse: [levelOrNil].
	"When unauthorized object stubs are enabled on the server, it will happily just send back another stub report, so 
	we find the class of the object. If it's an unauthorized object stub we still can't read it, so we generate an error."
	blockSource := '[:object | | objClass | 
					objClass := Reflection classOf: object. 
					objClass = UnauthorizedObjectStub 
						ifTrue: [ SecurityError new
									_number: 2115;
									signal: (object __asString add: '' could not be read.'')]
						ifFalse: [object]]'.
	session
		evaluateBlock: blockSource
		withArguments: (Array with: delegate)
		context: nil
		toLevel: level
]

{ #category : 'GBS private' }
GbxUnauthorizedObjectStub class >> gbsReplicatorClass
[

	^GbxUnauthorizedObjectReplicator
]

