Class {
	#name : #'GbsSynchronizationError',
	#superclass : #'GbsInterfaceError',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'compatibility - raising' }
GbsSynchronizationError class >> raiseWith: aGbsSession

	^self raiseWith: aGbsSession
		errorString: 'The current server operation didn''t complete. The server and client may no longer be synchronized. Errors or inconsistent behavior may result unless you log out and back in.'

