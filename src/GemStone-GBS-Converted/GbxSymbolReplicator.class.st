Class {
	#name : 'GbxSymbolReplicator',
	#superclass : 'GbxByteObjectReplicator',
	#instVars : [
		'stringClass'
	],
	#classVars : [
		'StringClassMapping'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object replication' }
GbxSymbolReplicator >> replicateFromReport
[
	"Private.  Given the description of a GemStone object from a traversal object header,
	 replicate the object as a client object.  If the object is already in the cache,
	 and it's not a stub, ignore it.. Self is returned."
	"Symbols are always sent in a single report, so we don't have to worry about that here.
	Symbols are also never sent as a header-only report, simplifying things.
	We shouldn't get a report for an already-mapped symbol in single-trip, but in multi-trip we can,
	so we look up the oop to see if it's already mapped.
	Make a temporary string of the appropriate class from the report, then intern that string,
	and connect the resulting Symbol.
	There is no known way to get a stub for a Symbol. But if you do manage to get one, there would be
	no way to unstub it without the code here that
	will unstub it and do the required one-way become."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientObject := session clientAtOop: reportOop.
	(clientObject == notCachedToken or: [clientObject zzzisStub])
		ifTrue: 
			[| string newSymbol |
			string := stringClass newFromGSObjectReport: currentReport.
			string gbxCopyBytesFromReport: currentReport.
			newSymbol := Symbol intern: string.
			delegate := session unprotectedConnectPossiblyExistingClient: newSymbol
						toServer: reportOop.
			delegate nowExported.
			clientObject zzzisStub
				ifTrue: 
					[GBSM clientMap
						writeCritical: [GBSM clientMap removeClient: clientObject forSession: session].
					clientObject oneWayBecome: newSymbol].
			clientObject := newSymbol]
]

{ #category : 'store replication' }
GbxSymbolReplicator >> store: anObject withDelegate: aDelegate inTraversal: storeTraversal
[
	"Recursively store object reports into the traversal buffer describing anObject
	and its referents. Only objects marked dirty are stored, and they will
	become 'not dirty'."
	"Sender must hold session's sessionProtect"
	"Symbols should never be put in a store traversal buffer. Their server-side creation is handled by 
	Symbol>>newGSObjectMappingInSession:, and they are immutable so should never have to be updated."

	anObject asGSObjectInSession: session	"Force creation if not already present."
]

{ #category : 'initialize-release' }
GbxSymbolReplicator >> initializeForClientClass: aClientClass serverClass: classDelegate manager: aManager
[

	super
		initializeForClientClass: aClientClass
		serverClass: classDelegate
		manager: aManager.
	stringClass := StringClassMapping at: aClientClass
]

{ #category : 'class initialization' }
GbxSymbolReplicator class >> initialize
[
	"GbxSymbolReplicator initialize"

	StringClassMapping := Dictionary new.
	StringClassMapping
		at: ByteSymbol put: ByteString;
		at: WideSymbol put: WideString
]
