Class {
	#name : 'GbxObjectStub',
	#superclass : 'GbxAbstractProxy',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'GBS private' }
GbxObjectStub >> gbxBecomeForwarder
[

	^self gbxBecome: GbsForwarder new
]

{ #category : 'faulting' }
GbxObjectStub >> fault
[
	"Lazy faulting support.  Cause this stub to fault in from the repository to the specified level."

	self faultToLevel: nil
]

{ #category : 'faulting' }
GbxObjectStub >> faultToLevel: levelOrNil session: session delegate: delegate
[
	"Sender must hold sessionProtect"

	| serverTraversal level |
	level := levelOrNil == nil
				ifTrue: [session defaultGStoSTLevel]
				ifFalse: [levelOrNil].	"If the session is in flush, the active process must be flushing, 
					since it holds sessionProtect."
	serverTraversal := session newServerTraversal.
	serverTraversal
		rootDelegate: delegate;
		replicationLevel: level;
		execute
]

{ #category : 'faulting' }
GbxObjectStub >> gbxReportUnstubErrorInSession: session delegate: delegate 
[
	| gsCached hasHashingProblems |
	gsCached := session serverMap clientAtOop: delegate.
	hasHashingProblems := GBSM clientMap auditHashing.
	^self 
		gbxProxyError: '%1 wouldn''t fault. Delegate was %2, %3 is now the cached delegate.'
		with: self
		with: ((delegate respondsTo: #gbxDebugPrintString) 
				ifTrue: [delegate gbxDebugPrintString]
				ifFalse: [delegate])
		with: self gbxDelegate
]

{ #category : 'faulting' }
GbxObjectStub >> faultToLevel: levelOrNil
[
	"Lazy faulting support.  Cause this stub to fault in from the repository to the specified level."

	| delegate session |
	delegate := self gbxDelegate.
	"Until we get the session semaphore, we could become faulted by another thread at any moment.
	Until then, be careful to only send messages that both replicates and stubs understand."
	delegate isNil
		ifTrue: 
			[self gbxProxyError: 'Defunct %1 - unconnected' with: self gbxBasicClass.
			^self].
	session := delegate validateSessionForProxy: self.
	session isNil ifTrue: [^self].
	session sessionCritical: 
			[self zzzisStub ifFalse: [^self].	"Might have been faulted while trying to get semaphore."
			self faultToLevel: levelOrNil session: session delegate: delegate.
			self zzzisStub
				ifTrue: [self gbxReportUnstubErrorInSession: session delegate: delegate]]
]

{ #category : 'faulting' }
GbxObjectStub >> faultPolicy
[

	"Lazy faulting employs GbxStubs.  Since I'm already a stub, #lazy is the most appropriate answer."

	^#lazy
]

{ #category : 'Object GBS methods' }
GbxObjectStub >> updateFromGS
[

	"Stubs are lazy faulters - do nothing."
]

{ #category : 'Object GBS methods' }
GbxObjectStub >> gbxUpdateFromDelegate: aGSObject
[

	"Do nothing - stubs are lazy faulters"
]

{ #category : 'Object GBS methods' }
GbxObjectStub >> gbxUpdateAsForwarder: aBoolean fromDelegate: delegate 
[
	"Private to GBS.
	Sender must hold session's sessionProtect."

	aBoolean 
		ifTrue: 
			["I need to become a forwarder"

			self asForwarder
			"The receiver is now the forwarder"]
		ifFalse: 
			["Stubs are already set up to be replicate objects"

			self gbxUpdateFromDelegate: delegate]
]

{ #category : 'Object GBS methods' }
GbxObjectStub >> gbxIsThisLastReport: report
[

	"If we intended to instantiate this object during replication, it would
	 have been turned into a non-stub object by now"
	^true
]

{ #category : 'Object GBS methods' }
GbxObjectStub >> zzzisStub
[

	"Identify this object as a stub.  The GBS avoids sending #class for this purpose, because if an application sends any common or user-defined message to this object (such as #class), it should cause 'unstubbing' through the #doesNotUnderstand: trap.  Hence, the uncommon selector for this method."

	^true
]

{ #category : 'Object GBS methods' }
GbxObjectStub >> asForwarder
[
	"GBS. Answer the receiver--which will become a forwarder."

	| delegate session |
	self gbxAssertImmutable.
	delegate := self gbxDelegate.
	"Until we get the session semaphore, we could become faulted by another thread at any moment.
	Until then, be careful to only send messages that both replicates and stubs understand."
	delegate isNil
		ifTrue: 
			[self gbxProxyError: 'Defunct %1 - unconnected' with: self gbxBasicClass.
			^self].
	session := delegate validateSessionForProxy: self.
	session isNil ifTrue: [^self].
	session sessionCritical: 
			[self zzzisStub
				ifTrue: 
					["Until we acquire the session semaphore, another thread could have made me
					a forwarder, or unstubbed me."
					session addClampedObject: self withDelegate: delegate].
			self gbxBecomeForwarder]
]

{ #category : 'caching' }
GbxObjectStub >> gbxExistingOrSpecialDelegateInSession: aGSSession
[
	"Return the cached proxy if it is from aGSSession, otherwise nil."

	| del |
	del := self gbxValidateDelegateAndSession.
	del isNil
		ifTrue: 
			[^self
				gbxProxyError: 'Defunct - A proxy for the stub should exist at this point'].
	^del forSession: aGSSession
]

{ #category : 'caching' }
GbxObjectStub >> asGSObjectInSession: aGSSession 
[
	"Return the cached proxy if it is from aGSSession.  Otherwise, punt to faulted object"

	| del |
	del := self gbxValidateDelegateAndSession.
	del isNil 
		ifTrue: 
			[^self 
				gbxProxyError: 'Defunct - A proxy for the stub should exist at this point'].
	del := del forSession: aGSSession.
	^del isNil 
		ifTrue: 
			["This stub represents an object from a different 
					 session.  Fault it in so the client object can be
					 stored in aSession."

			self fault asGSObjectInSession: aGSSession]
		ifFalse: [del]
]

{ #category : 'proxy support' }
GbxObjectStub >> gbxPerform: selector withArguments: anArray 
[
	"Send the receiver the keyword message indicated by the arguments. The argument
	selector is the selector of the message. The arguments of the message are the
	elements of anArray. Invoke messageNotUnderstood: if the number of
	arguments expected by the selector is not the same as the length of
	anArray."

	GbsConfiguration current stubDebugging 
		ifTrue: 
			[self gbsMessenger 
				comment: 'Faulting %1 to send %2.'
				with: self gbxDelegate
				with: selector].
	self fault zzzisStub 
		ifTrue: 
			[| delegate |
			delegate := self gbxDelegate.
			self 
				gbxProxyError: '%1 wouldn''t fault. Delegate was %2, %3 is now the cached delegate.'
				with: self
				with: delegate gbxDebugPrintString
				with: delegate].
	^self perform: selector withArguments: anArray	"no longer is a stub"
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> = anObject 
[
	"GBS. Fix for BUG18312--no unstubbing when #= sent in VA. Without
	 method, VA treats #= as #==."

	self == anObject ifTrue: [^true].
	GbsConfiguration current stubDebugging ifFalse: [^self fault = anObject].
	^[self fault = anObject] on: GbsError hostErrorSignal
		do: [:ex | ex return: false]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> printString
[
	"This is implemented to send #printString to the faulted object instead of #printOn:
	 just in case application code overrides #printString instead of #printOn:."

	| delegate |
	delegate := self gbxDelegate.
	^delegate isNil
		ifTrue: [self basicPrintString]
		ifFalse: 
			[delegate session hasCriticalAccess
				ifTrue: 
					[self gbxDebugPrintString	"we are already doing server execution, possibly in traversal, 
												which means that an attempt to go to the server might be bad"]
				ifFalse: 
					[delegate session sessionCritical: 
							[(GbsConfiguration current stubDebugging or: [self fault zzzisStub])
								ifTrue: [self gbxDebugPrintString]
								ifFalse: [self printString	"already faulted"]]]]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> gbxPrintOn: aStream
[

	self fault printOn: aStream.
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> isBehavior
[
	"Uses #remotePerform: to reduce faulting by tools."

	| delegate |
	delegate := self gbxDelegate.
	delegate == nil ifTrue: [^false].
	delegate := delegate forAnySingleSession.
	delegate gbxIsGSDefunct ifTrue: [^false].
	^Otrue = (delegate remotePerform: #isBehavior)
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> yourself
[

	"Fault before returning self"

	^self fault
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> instVarAt: index 
[
	"Answer with a fixed variable in an object.  The numbering of the variables
	corresponds to the named instance variables.  Fail if the index is not an
	Integer or is not the index of a fixed variable."

	^GbsConfiguration current stubDebugging 
		ifTrue: [self gbxInstVarAt: index]
		ifFalse: [self fault instVarAt: index]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> basicSize
[
	"Answer the number of indexable fields in the receiver. This value is the
	same as the largest legal subscript. Do not override in any subclass."

	^(GbsConfiguration current stubDebugging or: [ self gbxIsGSDefunct ])
		ifTrue: [self gbxBasicSize]
		ifFalse: [self fault basicSize]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> basicAt: index 
[
	"Answer the value of an indexable field in the receiver.  Fail if the
	argument index is not an Integer or is out of bounds."

	^GbsConfiguration current stubDebugging 
		ifTrue: [self gbxBasicAt: index]
		ifFalse: [self fault basicAt: index]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> maxPrint
[
	"Answer the maximum number of characters to print with printOn:."

	^GbsConfiguration current stubDebugging 
		ifTrue: [super maxPrint]
		ifFalse: [self fault maxPrint]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> basicAt: index put: value 
[
	"Store the second argument value in the indexable field of the receiver
	indicated by index. Fail if the index is not an Integer or is out of bounds. Or
	fail if the value is not of the right type for this kind of collection. Answer
	the value that was stored. Do not override in a subclass."

	^GbsConfiguration current stubDebugging 
		ifTrue: [self gbxBasicAt: index put: value]
		ifFalse: [self fault basicAt: index put: value]
]

{ #category : 'Object kernel methods' }
GbxObjectStub >> printOn: aStream 
[
	"Any errors while printing will have the error message
	 printed on aStream."

	GbsConfiguration current stubDebugging 
		ifTrue: [self gbxDebugPrintOn: aStream]
		ifFalse: [self gbxPrintOn: aStream]
]

{ #category : 'debugging' }
GbxObjectStub class >> debugWhile: aBlock 
[
	| saveDebugState |
	^
	[saveDebugState := GbsConfiguration current stubDebugging: true.
	aBlock value] 
			ensure: [GbsConfiguration current stubDebugging: saveDebugState]
]

{ #category : 'instance creation' }
GbxObjectStub class >> newFromReport: report
[
	"Create an instance of one of my subclasses, which one depending on the backend class implementation. "
	"The sender must hold the session protect of the session to which this stub is to belong."

	| implCode inst size |
	implCode := report objImpl.
	implCode == Special
		ifTrue: 
			[^self gbsMessenger
				error: 'Attempting to create a stub for a special object'].
	implCode == Bytes
		ifTrue: 
			["Byte stubs will always be zero-sized"
			inst := GbxByteStub new: 0]
		ifFalse: 
			["We don't know what client class the stub would be if unstubbed. Guess that its size is 
			simply the number of named instvars plus the number of indexable instvars on the server. 
			This will be correct for many classes."
			size := report namedSize + report idxSize.
			inst := GbxPointerStub basicNew: size].
	^inst
]

{ #category : 'instance creation' }
GbxObjectStub class >> newOfClass: aClass fromReport: report
[
	"Create an instance of one of my subclasses, which one depending on the backend class implementation. "
	"The sender must hold the session protect of the session to which this stub is to belong."

	| implCode inst idxSize |
	implCode := report objImpl.
	implCode == Special
		ifTrue: [^self gbsMessenger error: 'Attempting to create a stub for a special object'].
	implCode == Bytes
		ifTrue: 
			["Byte stubs will always be zero-sized"
			inst := GbxByteStub new: 0]
		ifFalse: 
			[idxSize := aClass gbxIndexableSizeFromReport: report.
			aClass isVariable ifTrue: [inst := aClass basicNew: idxSize] ifFalse: [inst := aClass basicNew].
			inst gbxChangeClassTo: GbxPointerStub].
	^inst
]

{ #category : 'instance creation' }
GbxObjectStub class >> stubObject: anObject forDelegate: delegate freeSlots: freeSlots
[
	"Turn anObject into a stub."
	"Sender must hold delegate's session's sessionProtect."
	"delegate session connectST: anObject toGS: delegate."

	GbsConfiguration current assertionChecks
		ifTrue: 
			[self gbsMessenger
				deny: (anObject gbxDelegate forSession: delegate session) isNil
				failure: 'GBSM is stubbing an object that isn''t already in the caches.'].
	anObject gbxCanBeStubbed
		ifFalse: 
			[self gbsMessenger
				error: 'Attempt to stub an object which should not be stubbed.'].
	anObject gbxBasicClass isBits
		ifTrue: 
			[GbxByteStub stubObject: anObject forDelegate: delegate freeSlots: freeSlots]
		ifFalse: 
			[GbxPointerStub
				stubObject: anObject
				forDelegate: delegate
				freeSlots: freeSlots]
]

{ #category : 'private' }
GbxObjectStub class >> changeObjectToStub: anObject 
[
	"Change anObject's class to the receiver."

	anObject gbxAssertImmutable.
	
	[anObject
		gbxIgnoreFutureChanges;
		gbxChangeClassTo: self;
		gbxTrapFutureChanges] 
			valueUnpreemptively.
	^anObject
]

