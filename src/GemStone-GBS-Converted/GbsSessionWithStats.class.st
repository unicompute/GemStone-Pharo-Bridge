Class {
	#name : 'GbsSessionWithStats',
	#superclass : 'GbsSession',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbsSessionWithStats >> replicationClass
[
	"With stats, use the stat version."

	^GbxReplicationWithStats
]

{ #category : 'testing' }
GbsSessionWithStats >> mainStatsEnabled
[
	"When main stats are enabled, a session is an instance of GbsSessionWithStats"

	^true
]

{ #category : 'reimplemented to update stats' }
GbsSessionWithStats >> signalFromGemStoneSession
[

	"Reimplemented to update changedObjNotifications stat."

	| signal |
	signal := super signalFromGemStoneSession.
	signal isNil ifFalse: [ self statResource incSessionSignals ].
	^signal
]

{ #category : 'reimplemented to update stats' }
GbsSessionWithStats >> getFreeOops: numOops
[

	self statResource incFreeOopsFetched: numOops.
	^super getFreeOops: numOops
]

{ #category : 'reimplemented to update stats' }
GbsSessionWithStats >> storingObjectInTraversal
[

	self statResource incObjectsStoredByTraversal
]

{ #category : 'reimplemented to update stats' }
GbsSessionWithStats >> signaledObjects
[

	"Returns an array containing the current contents of the signaledObjects set and clears the signaledObjects set."
	"Reimplemented to update changedObjNotifications stat."

	| signaledObjects |
	signaledObjects := super signaledObjects.
	self statResource incChangedObjNotifications: signaledObjects size.
	^signaledObjects
]

{ #category : 'reimplemented to update stats' }
GbsSessionWithStats >> processEventHandlerFor: aGbsError 
[

	aGbsError asExceptionClass updateStats: self statResource.
	^super processEventHandlerFor: aGbsError
]

{ #category : 'initialize-release' }
GbsSessionWithStats >> initializeStatAdaptors
[
	"Initialize components that have stat adaptors - enable stats"

	serverInterface := serverInterface statResource: stats.
	self sessionCriticalNoSessionCheck: 
			[sessionProtect := sessionProtect statAdaptor: (GbxStatAdaptor 
								statResource: stats
								incrementCountSelector: #incSessionProtectInvocations
								incrementTimeSelector: nil)]
]

