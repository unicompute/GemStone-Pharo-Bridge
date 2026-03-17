Class {
	#name : #'GbxServerCallResult',
	#superclass : #'Object',
	#instVars : [ #'alteredCompleted' #'alteredPairs' #'dirtyOops' #'gsError' #'resultOop' #'serverInterface' #'session' #'immediateOops' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private' }
GbxServerCallResult >> processAlteredSymbolsBuffer
	1 to: alteredPairs size
		by: 2
		do: 
			[:i | 
			session swizzleAlteredOops: (Array with: (alteredPairs at: i)
						with: (alteredPairs at: i + 1))]

{ #category : #'private' }
GbxServerCallResult >> processDirtyOopBuffer
	"Dirty oops are those of mapped objects that have been modified on the server.
	If it's a replicate and it's a lazy faulter, stub it. If it's immediate or the top-level result,
	add it to the immediate faulting list to be replicated immediately.
	Note that there's an exception for client forwarders, we *never* want to update a client 
	object from a client forwarder."
	"Sender must hold my session's sessionProtect."

	dirtyOops do: 
			[:dirtyDelegate |
			| clientObj |
			clientObj := session lookupOop: dirtyDelegate.
			(clientObj == NotCachedToken or: [clientObj zzzisForwarder])
				ifFalse: 
					[(clientObj faultPolicy = #lazy and: [dirtyDelegate ~~ resultOop])
						ifTrue: [clientObj gbxUpdateFromDelegate: dirtyDelegate]
						ifFalse: [immediateOops add: dirtyDelegate]]]

{ #category : #'accessing' }
GbxServerCallResult >> dirtyOops
	^dirtyOops

{ #category : #'accessing' }
GbxServerCallResult >> alteredPairs: anObject
	alteredPairs := anObject

{ #category : #'accessing' }
GbxServerCallResult >> resultOrError
	
	^gsError == nil
		ifTrue: [resultOop]
		ifFalse: [gsError]

{ #category : #'accessing' }
GbxServerCallResult >> resultOop: anObject
	resultOop := anObject

{ #category : #'accessing' }
GbxServerCallResult >> alteredCompleted: anObject
	alteredCompleted := anObject

{ #category : #'accessing' }
GbxServerCallResult >> gsError: anObject
	gsError := anObject

{ #category : #'accessing' }
GbxServerCallResult >> serverInterface: anObject
	serverInterface := anObject

{ #category : #'accessing' }
GbxServerCallResult >> dirtyOops: anObject
	dirtyOops := anObject

{ #category : #'testing' }
GbxServerCallResult >> hasGSError
	
	^gsError ~~ nil

{ #category : #'testing' }
GbxServerCallResult >> isFatalError
	
	gsError == nil ifTrue: [^false].
	^gsError isFatalError

{ #category : #'serverInterface interface' }
GbxServerCallResult >> processDirtyAndAltered
	"Process any dirty objects and server objects that were returned from the storeTravDo. Answer
	my collection of immediate oops, which the sender should re-replicate from the server. "
	"Sender must hold my session's accessProtect."

	self
		processDirtyOopBuffer;
		processAlteredSymbolsBuffer.
	[alteredCompleted] whileFalse: 
			[serverInterface fetchAlteredObjectsInto: self.
			self
				processDirtyOopBuffer;
				processAlteredSymbolsBuffer].
	^immediateOops

{ #category : #'initialize-release' }
GbxServerCallResult >> initializeForServerInterface: aServerInterface 
	serverInterface := aServerInterface.
	session := serverInterface session.
	immediateOops := OrderedCollection new: 500

{ #category : #'instance creation' }
GbxServerCallResult class >> serverInterface: aServerInterface 
	^self new initializeForServerInterface: aServerInterface

