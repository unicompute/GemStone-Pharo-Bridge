Class {
	#name : 'GbxReplication',
	#superclass : 'Object',
	#instVars : [
		'interaction',
		'objectsWithDeferredAssignments',
		'reportsWithDeferredElements',
		'reportsWithNoMappedClass',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxReplication >> interaction
[

	^interaction
]

{ #category : 'ServerInteraction interface' }
GbxReplication >> resolve
[
	"Private.  Resolve the things left unresolved from the initial traversal."
	"Always acquire sessionProtect before the cache write lock here. Several deferred
	class-mapping paths assume both semaphores are held when they remap replicators."

	session sessionCritical:
		[GBSM clientMap
			writeCritical:
				[self
					resolveUnmappedClasses;
					resolveDeferredAssignments;
					resolveObjectsWithDeferredElements]]
]

{ #category : 'ServerInteraction interface' }
GbxReplication >> replicateFromTraversal: aFetchTraversal
[
	"Answer nil unless an error occurs during replication. In that case, answer
	the error.
	If bodyAsDelegates is true, fill the instance variables of the object with 
	oop resultDelegate with delegates instead of replicates, stubs, and forwarders."

	| lastReportOrError |
	GBSM clientMap writeCritical: 
			[lastReportOrError := aFetchTraversal reportsAllButLastDo: 
							[:report |
							"We need to make extra checks on the last report, but all others are processed here."
							self gbsMessenger
								statusTag: #replicatingReportFromTraversal
								message: '(s%1) GbxReplication>>replicateFromTraversal:...%3 %2\%4'
								with: session sessionId
								with: (report isHeaderOnly ifTrue: ['HeaderOnly'] ifFalse: [''])
								with: report objId
								with: (GbsConfiguration current verbose ifTrue: [report] ifFalse: ['']).
							self replicateFromTraversalReport: report].
			lastReportOrError gbxIsGSError ifTrue: [^lastReportOrError].
			lastReportOrError ~~ nil
				ifTrue: 
					["When we're not replicating the result, there may be no reports at all."
					"Nothing needs to be done with a report for a special result. It cannot be split across traversal 
			buffers. Specials get their own object report only if a special oop is the result of computation or 
			is otherwise requested as the root of a traversal. In that case they are always the last report 
			in the traversal, preceded by any dirty object traversals."
					(session isSpecialOop: lastReportOrError objId)
						ifFalse: 
							[self gbsMessenger
								statusTag: #replicatingLastReportFromTraversal
								message: '(s%1) GbxReplication>>replicateFromTraversal:...%3 %2\%4'
								with: session sessionId
								with: (lastReportOrError isHeaderOnly ifTrue: ['HeaderOnly'] ifFalse: [''])
								with: lastReportOrError objId
								with: (GbsConfiguration current verbose ifTrue: [lastReportOrError] ifFalse: ['']).
							self replicateFromTraversalReport: lastReportOrError]]].
	^nil
]

{ #category : 'replicator interface' }
GbxReplication >> addDeferredElementsReport: report
[
	"Sender must ensure that this report does not reside in a buffer that might get reused."

	reportsWithDeferredElements add: report
]

{ #category : 'private' }
GbxReplication >> replicatorForReport: report
[

	^session replicatorForServerBehavior: report objClass
		ifAbsentPut: 
			[session unmappedClassReplicatorClass forSession: session
				serverBehavior: (report objClass asGSObjectInSession: session)]
]

{ #category : 'private' }
GbxReplication >> replicateFromTraversalReport: report
[
	"Private.  Given the description of a GemStone object from a traversal object header,
	 replicate the object as a client object.  If the object is already in the cache,
	 and it's not a stub, ignore it."
	"Sender must hold session's semaphore, and clientMap semaphore."

	| replicator |
	replicator := self replicatorForReport: report.
	replicator forReplication: self replicateFromReport: report
]

{ #category : 'private' }
GbxReplication >> replicateFromDeferredReport: report
[
	"Private.  Given the description of a GemStone object from a traversal object header,
	 replicate the object as a client object.  If the object is already in the cache,
	 and it's not a stub, ignore it."
	"Sender must hold session semaphore and cache semaphore."
	"An UnmappedClassReplicator has deferred this report. 
	At this point, we must:
	1) Look up the replicator for the class oop in the report. It will either be the unmapped class replicator, or a previous report will have mapped the class and gotten the real replicator.
	2) send the replicator forReplication:replicateFromDeferredReport:"

	| replicator |
	replicator := self replicatorForReport: report.
	replicator forReplication: self replicateFromDeferredReport: report
]

{ #category : 'private' }
GbxReplication >> resolveUnmappedClasses
[
	"Private.  ReportsWithNoMappedClass is an OrderedCollection of GbxObjectReports describing
	 reports from the last traversal buffer that require class generation.
	 Perform the class generation and then replicate those objects."
	"Sender must hold session semaphore and cache semaphore."
	
	reportsWithNoMappedClass
		do:
			[:aReport | 
			self gbsMessenger
				statusTag: #deferredClassMapping
				message: '(s%1) GbxReplication>>resolveUnmappedClasses, report=%2'
				with: session sessionId
				with: aReport.
			self replicateFromDeferredReport: aReport]	"Perform class generation"
]

{ #category : 'private' }
GbxReplication >> addUnmappedClassReport: report
[
	"Private.  The given report must be in its own private buffer, not a traversal buffer which could be re-used.
	The sender must hold session protect."

	reportsWithNoMappedClass add: report
]

{ #category : 'private' }
GbxReplication >> resolveObjectsWithDeferredElements
[
	"Process reports for hashed collections that must have complete contents in order to compute hash
	values correctly, and must be able to unstub if necessary."
	"At this point, all classes should be mapped, and each object will have been created or unstubbed.
	Beware, #updateServerInstVarNames invokes this method, so it's important that
	fetching server instVarNames never fault a hashed collection, or infinite recursion would result."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	reportsWithDeferredElements
		do: [:report | self replicateFromDeferredReport: report]
]

{ #category : 'private' }
GbxReplication >> addDeferredAssignments: deferredAssignments
[

	objectsWithDeferredAssignments add: deferredAssignments
]

{ #category : 'private' }
GbxReplication >> resolveDeferredAssignments
[
	"Private.  objectsWithDeferredAssignments is an OrderedCollection of GbxObjectWithDeferredAssignments.
	See the comment on that class."
	"The sender must hold my session protect."

	objectsWithDeferredAssignments do: 
			[:objectWithDeferredAssignments |
			self gbsMessenger
				statusTag: #deferredAssignments
				message: '(s%1) GbxReplication>>resolveDeferredAssignments ODA=%2'
				with: session sessionId
				with: objectWithDeferredAssignments.
			objectWithDeferredAssignments resolve].
	objectsWithDeferredAssignments := OrderedCollection new
]

{ #category : 'private - accessing' }
GbxReplication >> session: anObject
[
	session := anObject
]

{ #category : 'initialize-release' }
GbxReplication >> initializeForInteraction: anInteraction
[
	"Must initialize after session is set."

	interaction := anInteraction.
	session := anInteraction session.
	objectsWithDeferredAssignments := OrderedCollection new.
	reportsWithNoMappedClass := OrderedCollection new.
	reportsWithDeferredElements := OrderedCollection new.
	^self
]

{ #category : 'instance creation' }
GbxReplication class >> forInteraction: anInteraction
[

	^self new initializeForInteraction: anInteraction
]
