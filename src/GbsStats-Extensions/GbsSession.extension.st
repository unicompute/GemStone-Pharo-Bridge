Extension { #name : 'GbsSession' }

{ #category : '*GbsStats-Extensions' }
GbsSession >> statResource
[

	^stats
]

{ #category : '*GbsStats-Extensions' }
GbsSession >> mainStatsEnabled
[
	"When main stats are enabled, a session is an instance of GbsSessionWithStats"

	^false
]

{ #category : '*GbsStats-Extensions' }
GbsSession >> initializeStatAdaptors
[
	"Initialize components that have stat adaptors - disable stats"

	serverInterface := serverInterface statResource: nil.
	self sessionCriticalNoSessionCheck: 
			[sessionProtect := sessionProtect statAdaptor: nil]
]

{ #category : '*GbsStats-Extensions' }
GbsSession class >> new
[
	"Private. The public way to create a GbsSession is to send #login* to a GbsSessionParameters."
	"The session class depends on whether stats are enabled"

	^GBSM statsEnabled
		ifTrue: [self classWithStats basicNew initialize]
		ifFalse: [self basicNew initialize]
]

