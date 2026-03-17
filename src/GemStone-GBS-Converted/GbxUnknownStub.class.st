Class {
	#name : 'GbxUnknownStub',
	#superclass : 'GbxObjectStub',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'faulting' }
GbxUnknownStub >> faultToLevel: levelOrNil session: session delegate: delegate
[
	"Lazy faulting support.  Cause this stub to fault in from the repository to the specified level.
	If this unknown stub was created because of delayed finalization of the ServerMap, it might or might not be in the server's export set,
	so in order to fault it we might have to remove it from the export set.
	This may be slow, but it should be rare and must be safe in a 64-bit server.
	With a 32-bit server, it is correct for it to be in and remain in the export set."
	"Sender must hold sessionProtect"

	| level |
	level := levelOrNil == nil
				ifTrue: [session defaultGStoSTLevel]
				ifFalse: [levelOrNil].
	session
		evaluateBlock: '
				[:theObject | 
				System remove: theObject fromGciSet: 39.
				theObject]'
		withArguments: (Array with: delegate)
		context: nil
		toLevel: level
]

