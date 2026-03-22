Class {
	#name : 'GbxPointerObjectReplicator',
	#superclass : 'GbxObjectReplicator',
	#instVars : [
		'serverInstVarNames',
		'serverToClientOffsets',
		'deferredAssignments',
		'indexedBuffer',
		'namedBuffer',
		'replicationScheme',
		'replication'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private clamping' }
GbxPointerObjectReplicator >> instVarLevelForServerInstVar: index fromSpecs: specs noStubLevel: noStubLevel
[
	"index may be up to 1 greater than the number of server named instvars, in which case it represents the indexed instvars."

	| clientIndex clientIvarName rawSpec |
	index > serverInstVarNames size
		ifTrue: [clientIvarName := 'indexable_part']
		ifFalse: 
			[clientIndex := serverToClientOffsets at: index.
			clientIndex == nil
				ifTrue: [^false	"Instvar not mapped."]
				ifFalse: [clientIvarName := clientClass allInstVarNames at: clientIndex]].
	rawSpec := specs at: clientIvarName
				ifAbsent: [^noStubLevel < 0 ifTrue: [noStubLevel] ifFalse: [nil]].
	^self instVarLevelFor: rawSpec
]

{ #category : 'private clamping' }
GbxPointerObjectReplicator >> dictionaryFormOfReplicationSpec: replicationSpec
[

	| specs |
	specs := Dictionary new: replicationSpec size.
	replicationSpec do: 
			[:specArray |
			(specArray size between: 2 and: 3)
				ifTrue: [specs at: specArray first asString put: specArray]
				ifFalse: 
					[self gbsMessenger
						error: 'Each element of a replication spec should be a two- or three-element array.']].
	^specs
]

{ #category : 'private clamping' }
GbxPointerObjectReplicator >> instVarLevelFor: rawInstVarLevelsSpec
[
	"stInstVarSpec is the two or three element array found in the client's
	 implementations of replicationSpec.  The first element is an instvar
	 name or #indexable_part.  The second element is #min, #max, #stub,
	 #replicate, or #forwarder.  The third element, when it exists, is an
	 integer.  This method translates the second & third elements into
	 a positive or negative integer, nil, or false, to be used by the GemStone
	 clamp spec.  In GemStone, a negative integer represents a 'min' spec,
	 positive is 'max', and false means fully clamp (don't even give me an
	 object header).  If this client spec doesn't translate into a GemStone
	 spec, nil is returned.
	 The Code Critic can remain unhappy with this method."

	| operator level |
	operator := rawInstVarLevelsSpec at: 2.
	operator == #forwarder ifTrue: [^false].
	operator == #stub ifTrue: [^0].
	operator == #max
		ifTrue: 
			[level := rawInstVarLevelsSpec at: 3.
			level < 0 ifTrue: [^0] ifFalse: [^level]].
	operator == #min
		ifTrue: 
			[level := rawInstVarLevelsSpec at: 3.
			level <= 0 ifTrue: [^nil] ifFalse: [^level negated]].
	operator == #replicate ifTrue: [^nil].
	self gbsMessenger
		error: 'Illegal operator "%2" in a replicationSpec for %1'
		with: clientClass
		with: operator.
	^nil
]

{ #category : 'private clamping' }
GbxPointerObjectReplicator >> shouldBeForwarderFor: rawInstVarLevelsSpec
[
	"stInstVarSpec is the two or three element array found in the client's
	 implementations of replicationSpec.  The first element is an instvar
	 name or #indexable_part.  The second element is #min, #max, #stub,
	#replicate, or #forwarder.  The third element, when it exists, is an
	integer.  This method is only concerned with whether or not the
	operator is #forwarder, indicating that a server instvar should be
	replicated as a forwarder."

	| operator |
	operator := rawInstVarLevelsSpec at: 2.
	^operator == #forwarder
]

{ #category : 'private clamping' }
GbxPointerObjectReplicator >> shouldBeForwarderForServerInstVar: index fromSpecs: specs
[

	| clientIndex clientIvarName |
	(clientIndex := serverToClientOffsets at: index)
		ifNil: [^false	"Instvar not mapped."].
	clientIvarName := clientClass allInstVarNames at: clientIndex.
	^self shouldBeForwarderFor: (specs at: clientIvarName ifAbsent: [^false])
]

{ #category : 'per-object accessing' }
GbxPointerObjectReplicator >> deferredAssignments
[
	"To be sent only when wanting to add to the deferred assignments.
	deferredAssignments must be nil if it is empty."
	
	deferredAssignments == nil
		ifTrue:
			[deferredAssignments := self deferredAssignmentsClass new.
			deferredAssignments
				session: session;
				clientObject: clientObject;
				namedBuffer: namedBuffer;
				indexedBuffer: indexedBuffer].
	^deferredAssignments.
]

{ #category : 'per-object testing' }
GbxPointerObjectReplicator >> clientObjectIsComplete
[
	"Answer false if there is more work needed on this client object."

	^self expectsAnotherReport not and: [deferredAssignments == nil]
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> canUnstubInPlace
[

	^self clientSizeIsCorrect
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> assignInstvars
[
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	self
		assignNamedInstvars;
		assignIndexedInstvars
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> referentForOop: oop shouldBeForwarder: shouldBeForwarder
[
	"Private.  Look up the GemStone 'oop' and answer either:
	1) The corresponding special object
	2) The cached client object for the oop
	3) A new forwarder
	4) NotCachedToken.
	NotCachedToken means we must defer mapping the referent"
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	| val |
	val := session lookupOop: oop.
	"val is now set if it's a special or in the cache."
	val ~~ notCachedToken ifTrue: [^val].
	"If it's not in the cache, and it's specified as a forwarder, make a new forwarder"
	shouldBeForwarder
		ifTrue: 
			[val := GbsForwarder new.
			session unprotectedConnectNewClient: val
				toServer: (oop asGSObjectInSession: session)].
	^val
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> updateClientObjectForFault
[
	"Sender must hold sessionProtect.
	If the client object is immutable, it is an error to try to change it."

	super updateClientObjectForFault.
	"It shouldn't *always* be an error to get a report for an immutable client object.
	If the server object has moved pages due to clustering, we will get a report for it,
	even if its state hasn't changed (bug 48541). A full fix for this problem is non-
	trivial."
	self gbxFixMe.
	self errorIfClientImmutable
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> assignIndexedInstvars
[
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	| forwardIndexed namedSize |
	forwardIndexed := replicationScheme
				indexedInstvarsShouldBeForwardersInClass: clientClass.
	namedSize := currentReport namedSize.
	currentReport firstIndexableOffset to: currentReport lastIndexableOffset
		do: 
			[:serverOffset |
			| oop referent |
			oop := currentReport oopPtrAt: serverOffset.
			referent := self referentForOop: oop shouldBeForwarder: forwardIndexed.

			"Assign if now cached. If not cached, unmapped referent has been deferrred."
			referent == notCachedToken
				ifTrue: [self deferIndexedAssignmentAt: serverOffset - namedSize oop: oop]
				ifFalse: 
					[indexedBuffer indexableValueAt: serverOffset - namedSize put: referent]]
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> deferredAssignmentsClass
[
	
	^GbxObjectWithDeferredAssignments.
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> deferNamedAssignmentAt: clientOffset oop: oop 
[
	self deferredAssignments deferNamedOffset: clientOffset oop: oop
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> clientSizeIsCorrect
[
	"We need to know whether the number of total pointers (named plus indexed) is correct.
	Especially in the unstubbing case, the number of named instvars may be different
	but the total size may still be correct."

	| existingSize newSize |
	existingSize := clientObject gbxBasicClass instSize
				+ clientObject gbxBasicSize.
	newSize := clientClass instSize + currentReport idxSize.
	^existingSize = newSize
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> deferIndexedAssignmentAt: clientOffset oop: oop 
[
	self deferredAssignments deferIndexedOffset: clientOffset oop: oop
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> assignNamedInstvars
[
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	| forwarderOffsets clientOffset |
	forwarderOffsets := replicationScheme
				forwarderOffsetsForClass: clientClass.
	currentReport firstOffset to: currentReport lastNamedOffset
		do: 
			[:serverOffset |
			clientOffset := serverToClientOffsets at: serverOffset.
			clientOffset == nil
				ifFalse: 
					[| oop referent |
					oop := currentReport oopPtrAt: serverOffset.
					referent := self referentForOop: oop
								shouldBeForwarder: (forwarderOffsets at: serverOffset).
					"Assign if now cached. If not cached, unmapped referent must be deferrred."
					referent == notCachedToken
						ifTrue: [self deferNamedAssignmentAt: clientOffset oop: oop]
						ifFalse: [namedBuffer namedValueAt: clientOffset put: referent]]]
]

{ #category : 'per-object private' }
GbxPointerObjectReplicator >> session: anObject
[

	session := anObject
]

{ #category : 'accessing' }
GbxPointerObjectReplicator >> replicationScheme: anObject
[

	replicationScheme := anObject
]

{ #category : 'private-initialization' }
GbxPointerObjectReplicator >> validateInstVarName: name isIn: names message: message
[

	(GbsConfiguration current confirm and: [(names includes: name) not])
		ifTrue: 
			[self gbsMessenger
				warn: 'Class <%1> includes in its <instVarMap>,\ the name %2 which is not a %3 instance variable name'
				with: clientClass name
				with: name
				with: message]
]

{ #category : 'private-initialization' }
GbxPointerObjectReplicator >> initializeServerOffsets
[
	"This message must be sent after the client and server classes and session and server instvar names are all known.
	Compute the server offsets based on the client and server instvar names and the instvarMapping, if any."

	| size tempOffsets clientInstVarNames explicitMappings clientNamesMappedToNil |
	size := serverInstVarNames size.
	tempOffsets := OrderedCollection new: size.
	clientInstVarNames := clientClass allInstVarNames
				collect: [:each | each asSymbol].
	"Build temporary mapping dictionary, a more convenient form of the information in the class's instVarMap"
	explicitMappings := IdentityDictionary new: size.
	clientNamesMappedToNil := IdentitySet new.
	clientClass instVarMap do: 
			[:mapping |
			| serverName clientName |
			clientName := mapping at: 1.
			serverName := mapping at: 2.
			(clientName == nil or: [clientName == #nil])
				ifFalse: 
					[self
						validateInstVarName: clientName
						isIn: clientInstVarNames
						message: 'client'].
			(serverName == nil or: [serverName == #nil])
				ifTrue: 
					[clientNamesMappedToNil add: clientName
					"If clientName is nil, it will be ignored. Mappings of the form #(nil nil) are meaningless anyway."]
				ifFalse: 
					[self
						validateInstVarName: serverName
						isIn: serverInstVarNames
						message: 'server'.
					explicitMappings at: serverName put: clientName]].
	"We now know that they haven't specified any bogus names, and we have a dictionary 
	of the explicit mappings keyed by server name, with nil where there is an explicit non-mapping.
	And we have a set of client names that shouldn't be mapped. Now we can combine explicit and default mappings in a
	single pass."
	serverInstVarNames do: 
			[:serverName |
			| clientName |
			clientName := explicitMappings at: serverName ifAbsent: [serverName].	"If not explicitly mapped, try same-name"
			tempOffsets add: ((clientNamesMappedToNil includes: clientName)
						ifTrue: [nil]
						ifFalse: [clientInstVarNames indexOf: clientName ifAbsent: [nil]])].
	serverToClientOffsets := tempOffsets asArray
]

{ #category : 'per-object initialization' }
GbxPointerObjectReplicator >> initializeForNewObject
[

	super initializeForNewObject.
	replication := deferredAssignments := indexedBuffer := namedBuffer := nil
]

{ #category : 'testing' }
GbxPointerObjectReplicator >> isComplete
[

	^serverInstVarNames ~~ nil
]

{ #category : 'per-object replication' }
GbxPointerObjectReplicator >> forReplication: aReplication replicateFromReport: report
[
	"Sender must hold session's semaphore, and clientMap semaphore."

	| interaction |
	report isFirstReportForObject ifTrue: [self initializeForNewObject].
	replication := aReplication.
	interaction := replication interaction.
	currentReport := report.
	reportOop := report objId.
	replicationScheme := interaction replicationScheme.
	self replicateFromReport.
	deferredAssignments == nil
		ifFalse: [replication addDeferredAssignments: deferredAssignments].
	report isLastReportForObject ifTrue: [self initializeForNewObject]
]

{ #category : 'per-object replication' }
GbxPointerObjectReplicator >> replicateFromReport
[
	"Private.  Given the description of a GemStone object from a traversal object header,
	 replicate the object as a client object.  If the object is already in the cache,
	 and it's not a stub, ignore it.. Self is returned."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientObject := session clientAtOop: reportOop.
	reportCount := reportCount + 1.
	reportCount == 1
		ifTrue: 
			[self updateOrCreateClientObject.
			currentReport isHeaderOnly
				ifTrue: 
					[^self	"create or update all needed -- leave existing replicate alone (bug 41115)"]
				ifFalse: [self delegate nowExported].
			self gbxFixMe.	"assigns need to be unpreemptible"
			clientObject gbxIsProxy
				ifTrue: 
					[clientObject gbxTrapFutureChanges.
					^self].
			clientObject gbxIgnoreFutureChanges.
			clientObject preFaultWithReport: currentReport inSession: session]
		ifFalse: 
			["If we have a stub or forwarder at this point, we're done."
			clientObject gbxIsProxy ifTrue: [^self]].
	namedBuffer := clientObject namedValuesBuffer.
	indexedBuffer := clientObject indexableValuesBuffer.
	clientObject gbxIgnoreFutureChanges.	"Fill in object body. Some objects have no body (nil, true, false) and some don't need
	their body filled in (Block replication), Symbols, Floats, so some classes answer false to both
	#gbxReferencesOtherObjects and #gbxNeedsByteUpdates."
	self assignInstvars.
	self clientObjectIsComplete
		ifTrue: 
			[clientObject namedValues: namedBuffer indexableValues: indexedBuffer.
			clientObject postFaultInSession: session.
			self setImmutability].
	self gbxFixMe.	"assigns need to be unpreemptible"
	clientObject gbxTrapFutureChanges
]

{ #category : 'clamping' }
GbxPointerObjectReplicator >> updateInstVarLevelsOfScheme: scheme
[
	"If the scheme's selector has been removed, or the replication spec is a clamp by callback spec,
	 remove the class and related details from the scheme. Otherwise, update the scheme with
	 current details."

	| replicationSpec specs selector |
	selector := scheme selector.

	"If the scheme's selector has been removed, remove the class and related details from the scheme."
	(clientClass respondsTo: selector)
		ifFalse: [^scheme removeArtefactsForClass: self clientClass].

	"If the class' replication spec is by #callback, remove the class from instVarLevels, but keep
	 the forwarder information (no forwarding), regardless of whether Clamp by Callback is enabled."
	(replicationSpec := clientClass perform: selector) == #callback
		ifTrue: 
			[^scheme
				updateInstVarLevels: nil
				forwarderOffsets: (Array new: serverInstVarNames size withAll: false)
				forwardIndexedPart: false
				forClass: self clientClass].

	"In the normal case, update the scheme to reflect the replication spec."
	specs := self dictionaryFormOfReplicationSpec: replicationSpec.
	scheme
		updateInstVarLevels: (self createInstVarLevelsForReplicationSpecs: specs)
		forwarderOffsets: (self createForwarderOffsetsForReplicationSpecs: specs)
		forwardIndexedPart: (self
				indexedInstvarsShouldBeForwardersForReplicationSpecs: specs)
		forClass: self clientClass
]

{ #category : 'clamping' }
GbxPointerObjectReplicator >> createForwarderOffsetsForReplicationSpecs: specs
[
	"Answer an array of booleans, or nil. Nil is answered if my server class has no named instvars, or 
	if the scheme's selector is not understood by my client class.
	Otherwise, the size of the array is the number of named instvars in my server class.
	Each boolean in the array is true if the corresponding server named instvar is to be replicated 
	as a forwarder in the given replication scheme, or false if it is to be replicated as a replicate or stub."

	| resultArray numNamedVars |
	numNamedVars := serverInstVarNames size.
	numNamedVars = 0 ifTrue: [^nil].
	resultArray := Array new: numNamedVars.
	1 to: numNamedVars
		do: 
			[:i |
			resultArray at: i
				put: (self shouldBeForwarderForServerInstVar: i fromSpecs: specs)].
	^resultArray
]

{ #category : 'clamping' }
GbxPointerObjectReplicator >> createInstVarLevelsForReplicationSpecs: specs
[
	"Answer an instVarLevels array in the form the server expects, or nil if the scheme's selector
	is not defined for my class, which can happen if a scheme is removed after a session logs in.
	This is an array containing nil, false, or an integer for each named instvar in the class, plus one for the indexable instvars.
	Nil means do the default.
	False means clamp, not even a header-only report.
	0 means stub -- send a header-only report.
	A positive number is a 'max' spec (no more than this many levels).
	A negative number is a negated 'min' spec (no fewer than this many levels)."

	| levels noStubLevel numLevels |
	noStubLevel := 1 - clientClass noStubLevel.
	numLevels := serverInstVarNames size + 1.	"Extra one is for indexable_part"
	levels := Array new: numLevels.
	1 to: numLevels
		do: 
			[:i |
			levels at: i
				put: (self
						instVarLevelForServerInstVar: i
						fromSpecs: specs
						noStubLevel: noStubLevel)].
	^levels
]

{ #category : 'clamping' }
GbxPointerObjectReplicator >> indexedInstvarsShouldBeForwardersForReplicationSpecs: specs
[
	"Answer a boolean indicating whether instances of this class should have
	any indexed instvars replicated as forwarders, or nil if this question is moot."

	^self
		shouldBeForwarderFor: (specs at: 'indexable_part' ifAbsent: [^false])
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> namedInstvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each instvar (named or indexed) that is mapped to the server,
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report. At the evaluation for server
	named instvars that are not mapped to the client, evaluate the block with 
	a delegate for OOP_ILLEGAL."

	self
		namedInstvarsOf: anObject
		inServerOrderFrom: 1
		to: serverToClientOffsets size
		do: aBlock
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> packDirtyReferentsOf: anObject inTraversal: storeTraversal
[
	"Recursively store object reports into the traversal buffer describing anObject's
	referents, and their referents, and so on. Only objects marked dirty are stored, and they will
	become 'not dirty'."

	self instvarsOf: anObject
		inServerOrderDo: [:clientObj | storeTraversal pack: clientObj]
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> serverOverallSizeOf: anObject
[
	"Answer the number of named plus indexed instance variables in the server representation of anObject"

	^self serverNamedSize + (self serverIndexedSizeOf: anObject)
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> pack: anObject withDelegate: aDelegate inTraversal: storeTraversal
[
	"Store a report for anObject in the storeTraversal. If I won't fit, put the part of 
	anObject that will fit in, flush it to the server, and repeat until all of anObject has been stored."

	| indexWithinObject report valueBuffMaxNumOops oopsInValueBuffer firstOffset |
	indexWithinObject := 1.	"Overall index, with named instvars starting at 1, and indexed instvars at the first index following the named."
	storeTraversal flushBufferIfFull.
	report := storeTraversal objectReport.
	"Figure out how many oops could be stored in this report before hitting the end of the traversal buffer."
	valueBuffMaxNumOops := report maxValueBufferOops.
	oopsInValueBuffer := 0.
	firstOffset := indexWithinObject.
	self instvarsOf: anObject
		inServerOrderDo: 
			[:clientObj |
			oopsInValueBuffer >= valueBuffMaxNumOops
				ifTrue: 
					["No room for this oop in current report -- fill in the object header, send the buffer, and get a new report."
					"objImpl of 0 means pointers. #objImpl: also sets isOverlayed"
					"SwizzleStride only non-zero for byte objects"
					report
						valueBuffSize: oopsInValueBuffer * report bytesPerOop;
						namedSize: self serverNamedSize;
						idxSize: (self serverIndexedSizeOf: anObject);
						firstOffset: firstOffset;
						setObjIdFromDelegate: aDelegate;
						setObjClassFromDelegate: serverClass;
						segment: (report segmentValueForSession: session);
						objSize: (self serverOverallSizeOf: anObject);
						objImpl: self objImpl;
						swizzleStride: 0;
						storeIndexedSizeBits.
					storeTraversal finishedReport.
					self gbsMessenger traceLog: 
							[:msgr |
							msgr
								statusTag: #storedPartialObjectReport
								message: '(s%1)GbxPointerObjectReplicator>>pack:... a %2 %3 firstOffset: %4'
								with: session sessionId
								with: anObject gbxBasicClass name
								with: aDelegate
								with: firstOffset].
					storeTraversal flushBufferToServer.
					valueBuffMaxNumOops := report maxValueBufferOops.
					oopsInValueBuffer := 0.
					firstOffset := indexWithinObject].
			oopsInValueBuffer := oopsInValueBuffer + 1.
			report oopAt: oopsInValueBuffer
				putDelegate: (self storageDelegateForReference: clientObj).
			indexWithinObject := indexWithinObject + 1].
	"Done with value buffer of last report -- fill in the header."
	report
		valueBuffSize: oopsInValueBuffer * report bytesPerOop;
		namedSize: self serverNamedSize;
		idxSize: (self serverIndexedSizeOf: anObject);
		firstOffset: firstOffset;
		setObjIdFromDelegate: aDelegate;
		setObjClassFromDelegate: serverClass;
		segment: (report segmentValueForSession: session);
		objSize: (self serverOverallSizeOf: anObject);
		objImpl: self objImpl;
		swizzleStride: 0;
		storeIndexedSizeBits.
	storeTraversal finishedReport.
	self gbsMessenger traceLog: 
			[:msgr |
			msgr
				statusTag: #storedObjectReport
				message: '(s%1)GbxPointerObjectReplicator>>pack:... a %2 %3 firstOffset: %4'
				with: session sessionId
				with: anObject gbxBasicClass name
				with: aDelegate
				with: firstOffset].
	storeTraversal packed: anObject.
	session packed: anObject
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> instvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each instvar (named or indexed) that is mapped to the server,
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report. At the evaluation for server
	named instvars that are not mapped to the client, evaluate the block with 
	a delegate for OOP_ILLEGAL."

	self
		namedInstvarsOf: anObject namedValues inServerOrderDo: aBlock;
		indexedInstvarsOf: anObject indexableValues inServerOrderDo: aBlock
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> serverNamedSize
[
	"Answer the number of named instance variables of my server class."

	^serverToClientOffsets size
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> indexedInstvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each indexed instvar
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report.

	For simple objects, this is just the indexed instvars in order."

	1 to: anObject gbxBasicSize do: [:i | aBlock value: (anObject basicAt: i)]
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> serverIndexedSizeOf: anObject
[
	"Answer the number of indexed instance variables in the server representation of anObject"

	^anObject gbxBasicSize
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> objImpl
[

	^0	"Pointers"
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> namedInstvarsOf: anObject inServerOrderFrom: startIndex to: stopIndex do: aBlock
[
	"Do the default mapping for the given server range of instvars, as modified by #instVarMap"

	startIndex to: stopIndex
		do: 
			[:serverIndex |
			| sourceIndex |
			sourceIndex := serverToClientOffsets at: serverIndex.
			aBlock value: (sourceIndex == nil
						ifTrue: 
							[session oopIllegal
							"OOP_ILLEGAL -- this server instvar is not mapped to the client. 
							With the overlay flag set, this indicates to leave existing value alone"]
						ifFalse: [anObject namedValueAt: sourceIndex])]
]

{ #category : 'private store replication' }
GbxPointerObjectReplicator >> storageDelegateForReference: clientObj
[
	"By default, just the delegate of the given client object. Subclasses can override this for GBS Customization behavior."

	^clientObj asGSObjectInSession: session
]

{ #category : 'initialize-release' }
GbxPointerObjectReplicator >> initializeForClientClass: aClientClass serverClass: classDelegate manager: aManager
[

	super
		initializeForClientClass: aClientClass
		serverClass: classDelegate
		manager: aManager.
	self shouldFetchDeferredServerInstVarNames
		ifTrue: [manager serverInstVarNamesNeededByReplicator: self]
]

{ #category : 'initialize-release' }
GbxPointerObjectReplicator >> initializeForServerInstVarNames: names
[
	"This message must be sent after the basic initialization that provides the client and server classes and session.
	Remember the server instvar names (primarily for ease of debugging) and compute the offsets array, which is
	the real reason we need the names."
	"The sender must hold my session's protect semaphore."

	serverInstVarNames := names.
	self initializeServerOffsets
]

{ #category : 'testing' }
GbxPointerObjectReplicator >> shouldFetchDeferredServerInstVarNames
[

	^true
]

{ #category : 'stubbing' }
GbxPointerObjectReplicator >> nilMappedSlotsOf: aStub
[
	"An object is being made a stub, when it was a replicate of my class. Since it was a replicate, my offsets should be current.
	It is currently a stub, so it only has indexed instvars at this point, but the first ones map to any named instvars of its previous
	client class.
	Nil out each of its named instance variables that are mapped, and all of its indexed instvars.
	We must make anObject mutable during this operation. To protect against another thread trying 
	to modify the object, all of the time that the object is mutable this thread must be unpreemptable."
	"Note that this suffers from bug 43724 -- if the class uses a namedValueBuffer, 
	we don't know what the right thing to do here is."

	aStub gbxWhileMutableDoUnpreemptively: 
			[serverToClientOffsets
				do: [:clientOffset | clientOffset notNil ifTrue: [aStub gbxBasicAt: clientOffset put: nil]].
			clientClass instSize + 1 to: aStub gbxBasicSize
				do: [:idx | aStub gbxBasicAt: idx put: nil]]
]
