Class {
	#name : 'GbsSessionWithStats',
	#superclass : 'GbsSession',
	#instVars : [
		'stats'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsSessionWithStats class >> mainStatsEnabled [
	^ true
]

{ #category : 'error handling' }
GbsSessionWithStats >> checkForError [
	^ [ super checkForError ]
		on: GbsError
		do: [ :ex |
			stats ifNotNil: [ stats incGciErrors ].
			ex pass ]
]

{ #category : 'execution' }
GbsSessionWithStats >> evaluate: aString [
	^ self measureGemCall: [ super evaluate: aString ]
]

{ #category : 'evaluating' }
GbsSessionWithStats >> evaluateAndFetchString: aString [
	^ self measureGemCall: [ super evaluateAndFetchString: aString ]
]

{ #category : 'execution' }
GbsSessionWithStats >> execute: script [
	^ self measureGemCall: [ super execute: script ]
]

{ #category : 'execution' }
GbsSessionWithStats >> executeAndFetch: script context: contextOop [
	^ self measureGemCall: [ super executeAndFetch: script context: contextOop ]
]

{ #category : 'error handling' }
GbsSessionWithStats >> handleGciError [
	stats ifNotNil: [ stats incGciErrors ].
	^ super handleGciError
]

{ #category : 'initialization' }
GbsSessionWithStats >> initialize [
	super initialize.
	stats := GbxSessionStatResource new.
	stats session: self
]

{ #category : 'initialize-release' }
GbsSessionWithStats >> initializeStatAdaptors [
	"VW enables additional wrapped components here. The Pharo bridge updates
	the session counters directly in the public execution paths instead."
]

{ #category : 'initialization' }
GbsSessionWithStats >> loginStone: stoneName user: username password: password [
	| result |

	result := super loginStone: stoneName user: username password: password.
	self isLoggedIn ifTrue: [ GbxStatMonitor instance addStatResource: stats ].
	^ result
]

{ #category : 'actions' }
GbsSessionWithStats >> logout [
	[ GbxStatMonitor instance removeStatResource: stats ]
		on: Error
		do: [ :ex | ].
	^ super logout
]

{ #category : 'testing' }
GbsSessionWithStats >> mainStatsEnabled [
	^ true
]

{ #category : 'private' }
GbsSessionWithStats >> measureGemCall: aBlock [
	| start |

	start := Time millisecondClockValue.
	^ [ aBlock value ]
		ensure: [
			stats ifNotNil: [
				stats
					incGciCallsToGem;
					incGciCallsToGemTime: ((Time millisecondClockValue - start) * 1000) ] ]
]

{ #category : 'polling' }
GbsSessionWithStats >> checkSignals [
	| signalResult |

	signalResult := self gciPollForSignal.
	signalResult = 4 ifTrue: [
		stats ifNotNil: [ stats incSigAborts ].
		TransactionBacklog signal ].
	signalResult = 1 ifTrue: [ AlmostOutOfMemory signal ].
	signalResult > 0 ifTrue: [
		stats ifNotNil: [ stats incSessionSignals ].
		Transcript cr; show: 'GemStone Signal: ', signalResult asString ].
]

{ #category : 'private' }
GbsSessionWithStats >> replicationClass [
	^ GbxReplicationWithStats
]

{ #category : 'accessing' }
GbsSessionWithStats >> statResource [
	^ stats
]
