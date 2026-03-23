Class {
	#name : 'GbsForwarder',
	#superclass : 'GbxAbstractProxy',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'GBS private' }
GbsForwarder >> gbxBecomeForwarder
[
	"I'm already a forwarder."

	^self
]

{ #category : 'GBS private' }
GbsForwarder >> gbxDeepCopy
[
	"GBS private"

	"Used only for copy replication of delegates with cached forwarders.
	This is not supported, but return something that works."

	^self
]

{ #category : 'GBS private' }
GbsForwarder >> gbxDeepCopyCycles: cycles 
[
	"GBS private"

	^self
]

{ #category : 'debugging' }
GbsForwarder >> gbxIsGsBottomGlue: aSelector [
	"All forwarder sends are GemStone glue unless forwarder debugging is enabled."
	^ GbsConfiguration current forwarderDebugging not
]

{ #category : 'debugging' }
GbsForwarder >> gbxIsGsTopGlue: aSelector [
	"All forwarder sends are GemStone glue unless forwarder debugging is enabled."
	^ GbsConfiguration current forwarderDebugging not
]

{ #category : 'debugging' }
GbsForwarder >> gbxStepsIntoGemStone: aSelector showGlue: showGlue [
	^ showGlue not
]

{ #category : 'Object GBS methods' }
GbsForwarder >> gbxUpdateFromDelegate: aGSObject
[

	"Private.  This is now a forwarder for aGSObject"

	aGSObject session connectClient: self toServer: aGSObject
]

{ #category : 'Object GBS methods' }
GbsForwarder >> gbxUpdateAsForwarder: aBoolean fromDelegate: aGSObject 
[
	"Private to GBS.
	If aBoolean is true, I'm already a forwarder.
	Sender must hold session's sessionProtect"

	aBoolean 
		ifFalse: 
			["Become a Smalltalk replicate (non-forwarder)"

			self gbxBecome: Object new].
	self gbxUpdateFromDelegate: aGSObject
]

{ #category : 'Object GBS methods' }
GbsForwarder >> gbxIsThisLastReport: report
[

	"Private.  Forwarders don't replicate their contents"
	^true
]

{ #category : 'Object GBS methods' }
GbsForwarder >> instancesAreForwarders
[

	"Private.  If the class is a forwarder, its instances will be forwarders"
	^true
]

{ #category : 'Object GBS methods' }
GbsForwarder >> zzzisForwarder
[
	"Private"

	^true
]

{ #category : 'Object GBS methods' }
GbsForwarder >> gbxConnectingToMultipleSessions
[

	"Private.  The receiver is being connected to more than one GemStone session, which is not allowed for forwarders."

	self gbxProxyError: 'Attempt to associate a forwarder with more than one GemStone session'
]

{ #category : 'caching' }
GbsForwarder >> gbxExistingOrSpecialDelegateInSession: aGSSession
[

	"Return the receiver's delegate if it is from aGSSession.  Otherwise, raise an error."

	| delegate |
	delegate := self gbxValidateDelegateAndSession.
	delegate isNil ifTrue: [ ^nil ].
	delegate session = aGSSession
		ifFalse: [ ^self gbxProxyError: 'Copying forwarders between sessions is not supported' ]
		ifTrue: [ ^delegate ]
]

{ #category : 'caching' }
GbsForwarder >> putInGS
[

	"The receiver is already in GemStone - return my proxy"
	^self asGSObject
]

{ #category : 'caching' }
GbsForwarder >> putInGSSession: aGSSession
[

	"The receiver is already in GemStone - return my proxy"
	^self asGSObjectInSession: aGSSession
]

{ #category : 'caching' }
GbsForwarder >> asGSObjectInSession: aGSSession
[
	"Private to GBS. Return the receiver's delegate if it is from aGSSession.  Otherwise, raise an error."

	^self gbxExistingOrSpecialDelegateInSession: aGSSession
]

{ #category : 'obsolete' }
GbsForwarder >> putInGSSession: aGSSession toLevel: level 
[
	GbsConfiguration 
		deprecated: 'GbsForwarder>>putInGSSession:toLevel: deprecated January, 2008. Use #asGSObjectInSession instead, or even better, use normal replication mechanisms and avoid forcing objects to the server in separate network round trips.'.
	^self asGSObjectInSession: aGSSession
]

{ #category : 'proxy support' }
GbsForwarder >> gbxPerform: sel withArguments: args
[
	"Forward aMessage to the GemStone object that the receiver represents.  Return
	 a Smalltalk replicate for the result.  If the message selector begins with 'fw',
	 return a forwarder for the result.  If the message selector begins with 'ucfw',
	 return an uncached forwarder for the result."

	| selector answerForwarder answerUncachedForwarder delegate session messageSend |
	delegate := self gbxDelegate.
	"Until I get the session semaphore (in the #execute), it's possible I could become a 
	replicate at any moment due to the actions of another thread. 
	Until then, be careful to only send messages to self that both 
	replicates and forwarders understand.
	However, once we enter this method we're committed to sending the message to the server,
	even though I might be a replicate by the time the message is sent.
	This is because I don't want to grab the session semaphore until I'm in the #execute,
	so if there's a server error the debugger will be able to debug it without me holding that
	semaphore."
	delegate isNil
		ifTrue: 
			[self gbxProxyError: 'Defunct %1 - unconnected' with: self gbxBasicClass.
			^self].
	GbsConfiguration current forwarderDebugging
		ifTrue: 
			[self gbsMessenger
				comment: '%1 for %2 is forwarding %3.'
				with: self gbxBasicClass
				with: delegate
				with: sel].
	answerUncachedForwarder := sel size > 4 and: 
					[$u == (sel at: 1)
						and: [$c == (sel at: 2) and: [$f == (sel at: 3) and: [$w == (sel at: 4)]]]].	" 'ucfw*' match: sel "
	answerForwarder := answerUncachedForwarder or: 
					[" 'fw*' match: sel "
					sel size > 2 and: [$f == (sel at: 1) and: [$w == (sel at: 2)]]].
	selector := sel.
	answerForwarder
		ifTrue: 
			[selector := sel
						copyFrom: (answerUncachedForwarder ifTrue: [5] ifFalse: [3])
						to: sel size].

	"Any obvious problems will raise errors with this test."
	session := delegate validateSessionForProxy: self.

	"Okay, actually send the message."
	messageSend := session newMessageSend.
	messageSend
		selector: selector;
		arguments: args;
		receiver: delegate.
	^answerForwarder
		ifTrue: 
			[| resultDelegate |
			resultDelegate := messageSend
						shouldReplicateResult: false;
						execute.
			answerUncachedForwarder
				ifTrue: [resultDelegate gbsAsUncachedForwarderInSession: session]
				ifFalse: [resultDelegate asForwarder]]
		ifFalse: 
			[messageSend
				shouldReplicateResult: true;
				execute]
]

{ #category : 'replication' }
GbsForwarder >> beReplicate
[
	"The receiver will become a local replicate of the GemStone object
	 it forwards to. If receiver is an uncached forwarder then become what is
	 cached for the oop. If nothing is cached, will cache a new replicate."

	| local delegate session |
	delegate := self gbxValidateDelegateAndSession.

	"need session critical before cache critical to avoid deadlock if removeClampedObject:
	 needs to be invoked (which invokes remotePerform, which needs sessionCritical:)"
	session := delegate session.
	session sessionCritical: 
			[| dict cachedClient |
			self zzzisForwarder ifFalse: [^self].	"Another process preempted"
			dict := session serverMap.
			"Must disconnect first or else forwarder will be found in cache."
			cachedClient := dict clientAtOop: delegate.
			cachedClient == self
				ifTrue: 
					["I'm cached, remove from oop dict so asLocalObject won't just return me."
					dict pretendClientIsCollected: delegate.
					"Remove from identity clamps so server will send full report."
					session removeClampedObject: self withDelegate: delegate].
			local := delegate asLocalObject.
			"No need to reconnect because replicate should now be in cache, but
		 we do need to remove my old entry in the client map before changing my identityHash."
			GBSM clientMap
				writeCritical: [GBSM clientMap removeClient: self forSession: session].
			self oneWayBecome: local]
]

{ #category : 'replication' }
GbsForwarder >> faultToLevel: level
[

	"Private.  Forwarders don't fault their GemStone counterpart into Smalltalk"
	^self
]

{ #category : 'replication' }
GbsForwarder >> faultPolicy
[

	^#immediate
]

{ #category : 'Object kernel methods' }
GbsForwarder >> basicSize
[
	| delegate |
	GbsConfiguration current forwarderDebugging ifTrue: [^0].
	(delegate := self gbxValidateDelegateAndSession) isNil ifTrue: [^0].
	delegate exists ifFalse: [^0].
	^delegate remoteVaryingSize
]

{ #category : 'Object kernel methods' }
GbsForwarder >> isSequenceable
[

	| proxy |
	proxy := self gbxValidateDelegateAndSession.
	proxy isNil ifTrue: [^false].
	^proxy performOnGsServer: #isKindOf: withArguments: (Array with: OSequenceableCollection)
]

{ #category : 'Object kernel methods' }
GbsForwarder >> basicAt: index
[

	^self perform: #'_basicAt:' with: index
]

{ #category : 'Object kernel methods' }
GbsForwarder >> printOn: aStream 
[
	"Any errors while printing will have the error message
	 printed on aStream."

	GbsConfiguration current forwarderDebugging 
		ifTrue: [self gbxDebugPrintOn: aStream]
		ifFalse: [self gbxPrintOn: aStream]
]

{ #category : 'Object kernel methods' }
GbsForwarder >> class
[

	| remoteObject |
	remoteObject := self gbxDelegate.
	remoteObject isNil ifTrue: [^self gbxBasicClass].

	"Protect against errors!"
	^
	[| stClass rClass sess |
	rClass := remoteObject unsynchronizedRemoteClass.
	sess := remoteObject session.
	stClass := sess sessionCritical: [sess clientObjForDelegate: rClass otherwise: nil].
	stClass isNil ifTrue: [stClass := rClass asForwarder].
	stClass]
			on: GbsError hostErrorSignal , GbsError errorSignal
			do: [:ex | ex return: self gbxBasicClass]
]

{ #category : 'Object kernel methods' }
GbsForwarder >> = anObject 
[
	self == anObject ifTrue: [^true].

	"Protect against errors!"
	^[self gbxPerform: #= withArguments: (Array with: anObject)] 
		on: GbsError hostErrorSignal
		do: [:ex | ex return: false]
]

{ #category : 'Object kernel methods' }
GbsForwarder >> isString
[

	"Returns false, receiver does a bad job pretending to be a genuine client class."
	^false
]

{ #category : 'Object kernel methods' }
GbsForwarder >> gbxPrintOn: aStream
[

	self gbxIsGSDefunct
		ifTrue: [self gbxDebugPrintOn: aStream]
		ifFalse: 
			[| str |
			str := self gbxValidateDelegateAndSession performOnGsServer: #printString.
			aStream nextPutAll: str]
]

{ #category : 'Object kernel methods' }
GbsForwarder >> printString
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
							[(GbsConfiguration current forwarderDebugging or: [self gbxIsGSDefunct])
								ifTrue: [self gbxDebugPrintString]
								ifFalse: [self gbxValidateDelegateAndSession performOnGsServer: #printString]]]]
]

{ #category : 'debugging' }
GbsForwarder class >> debugWhile: aBlock 
[
	| saveDebugState |
	^
	[saveDebugState := GbsConfiguration current forwarderDebugging: true.
	aBlock value] 
			ensure: [GbsConfiguration current forwarderDebugging: saveDebugState]
]
