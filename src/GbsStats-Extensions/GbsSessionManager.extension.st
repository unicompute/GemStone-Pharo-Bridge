Extension { #name : 'GbsSessionManager' }

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statMonitorRunning
[
	"Return true if the stat monitor, which samples and archives statistics, is running."

	"GBSM statMonitorRunning"

	^GbxStatMonitor instance isProcessRunning
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statsEnabled: enableStats
[
	"Turn all GBS stats on or off.  This enables/disables collection of main
	 stats, cache stats, and starts/stops the stat monitor process."

	"GBSM statsEnabled: true"

	"GBSM statsEnabled: false"


	self
		mainStatsEnabled: enableStats;
		cacheStatsEnabled: enableStats;
		statMonitorRunning: enableStats
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> cacheSampleIntervalMultiplier
[
	"This value times sampleInterval is the interval between two cache stat samples.  For example, a
	 cacheSampleIntervalMultiplier of 1 means cache stats will be sampled every time stats are
	 sampled.  A value of 5 means cache stats will be sampled every 5th time.  Cache stats are
	 more expensive to sample than other stats, as they iterate over the gsObjectCache."

	^GbxStatMonitor instance cacheSampleIntervalMultiplier
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> mainStatsEnabled: enableMainStats
[
	"Enable or disable the main stats (session manager and session stats).  This method 
	 does not enable or disable cache stats."
	"GBSM mainStatsEnabled: true"
	"GBSM mainStatsEnabled: false"

	enableMainStats
		ifTrue: 
			[GbsSessionManagerWithStats adoptInstance: self.	"Enable the session manager"
			self initializeStatAdaptors.

			"Enable active sessions for stats"
			self loggedInSessions do: 
					[:sess |
					sess parameters sessionClass classWithStats adoptInstance: sess.
					sess initializeStatAdaptors].

			"Enable the prim interface"
			GbxServerInterface enableStats]
		ifFalse: 
			[GbsSessionManager adoptInstance: self.

			"Disable the session manager"
			self initializeStatAdaptors.

			"Disable active sessions for stats"
			self loggedInSessions do: 
					[:sess |
					sess parameters sessionClass adoptInstance: sess.
					sess initializeStatAdaptors].

			"Disable the prim interface"
			GbxServerInterface disableStats]
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statsEnabled
[
	"Return a boolean indicating whether any stats are enabled"

	"GBSM statsEnabled"

	^self mainStatsEnabled or: [self cacheStatsEnabled]
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> mainStatsEnabled
[
	"GBSM mainStatsEnabled"

	^self class == GbsSessionManagerWithStats
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statSampleInterval: milliseconds
[
	"Set the interval, in milliseconds, at which stat sampling and archiving 
	 occurs when stats are enabled."

	GbxStatMonitor instance sampleInterval: milliseconds
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> cacheStatsEnabled: enableCacheStats
[
	"If cache stats are enabled and the stat monitor is running, the stObjectCache
	 will be inventoried so that statistics can be archived describing its contents.
	 Cache inventory is somewhat expensive, so by default, only every 5th stat
	 sample will do an inventory.  See GbxStatMonitor>>cacheStatIntervalMultiplier."

	enableCacheStats
		ifTrue: [clientMap classWithStats adoptInstance: clientMap]
		ifFalse: 
			[clientMap classWithoutStats adoptInstance: clientMap.
			clientMap discardStats]
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statSampleInterval
[

	"Return the interval, in milliseconds, at which stat sampling and archiving 
	 occurs when stats are enabled."

	^GbxStatMonitor instance sampleInterval
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> cacheStatsEnabled
[

	^clientMap collectsStats and: [self statMonitorRunning]
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statMonitorRunning: aBoolean
[
	"If aBoolean is true, turn start the stat monitor process, which samples 
	 and archives statistics.  If false, turn off the stat monitor process."

	"GBSM statMonitorRunning: true"

	aBoolean 
		ifTrue: [GbxStatMonitor instance startProcess]
		ifFalse: [GbxStatMonitor instance stopProcess]
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> cacheSampleIntervalMultiplier: anInteger
[
	"This value times sampleInterval is the interval between two cache stat samples.  For example, a
	 cacheSampleIntervalMultiplier of 1 means cache stats will be sampled every time stats are
	 sampled.  A value of 5 means cache stats will be sampled every 5th time.  Cache stats are
	 more expensive to sample than other stats, as they iterate over the gsObjectCache."

	GbxStatMonitor instance cacheSampleIntervalMultiplier: anInteger
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> initializeStatAdaptors
[
	"Initialize components that have stat adaptors - disable stats"

	GbxGciCallSequencer gciCallProtectStatAdaptor: nil
]

{ #category : '*GbsStats-Extensions' }
GbsSessionManager >> statResource
[
	"Return the session manager stat resource.  Note that each logged in
	 GbsSession will also have a stat resource.  Also note that although there
	 may be a stat resource, statistics are not updated unless statistics are 
	 enabled."
	"See also: GbsSessionManager>>enableStats, >>disableStats"

	^stats
]

