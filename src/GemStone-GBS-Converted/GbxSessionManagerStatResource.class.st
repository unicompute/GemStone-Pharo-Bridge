Class {
	#name : #'GbxSessionManagerStatResource',
	#superclass : #'GbxStatResource',
	#instVars : [ #'sessionListProtectInvocations' #'gciCallProtectInvocations' #'numSessions' #'stObjectCacheSize' #'mainStatSampleTime' #'cacheStatSampleTime' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'stat updating' }
GbxSessionManagerStatResource >> incGciCallProtectInvocations

	gciCallProtectInvocations incValue: 1

{ #category : #'stat updating' }
GbxSessionManagerStatResource >> incMainStatSampleTime: delta 
	mainStatSampleTime incValue: delta

{ #category : #'stat updating' }
GbxSessionManagerStatResource >> setNumSessions
	numSessions setValue: GBSM loggedInSessions size

{ #category : #'stat updating' }
GbxSessionManagerStatResource >> incCacheStatSampleTime: delta 
	cacheStatSampleTime incValue: delta

{ #category : #'stat updating' }
GbxSessionManagerStatResource >> incSessionListProtectInvocations

	sessionListProtectInvocations incValue: 1.

{ #category : #'stat accessing' }
GbxSessionManagerStatResource >> clientMapSize
	"The number of objects in the client map."

	"Get a stable reference to support concurrency"

	| stoc |
	stoc := GBSM clientMap.
	stoc isNil 
		ifTrue: [stObjectCacheSize setValue: 0]
		ifFalse: [stObjectCacheSize setValue: stoc size].
	^stObjectCacheSize value

{ #category : #'stat accessing' }
GbxSessionManagerStatResource >> sessionListProtectInvocations

	"The number of times the sessionListProtect mutual exclusion semaphore has been invoked."

	^sessionListProtectInvocations value

{ #category : #'stat accessing' }
GbxSessionManagerStatResource >> cacheStatSampleTime
	"The number of microseconds spent sampling cache statistics"

	^cacheStatSampleTime value

{ #category : #'stat accessing' }
GbxSessionManagerStatResource >> numSessions

	"The number of logged in GbsSessions.  If a session has died abnormally, and GBS
	 has not yet discovered its death, this number will erroneously include that session."

	^numSessions value

{ #category : #'stat accessing' }
GbxSessionManagerStatResource >> mainStatSampleTime
	"The number of microseconds spent sampling manager and session statistics"

	^mainStatSampleTime value

{ #category : #'stat accessing' }
GbxSessionManagerStatResource >> gciCallProtectInvocations

	"The number of times the GbxCInterface GciCallProtect mutual exclusion semaphore has been invoked."

	^gciCallProtectInvocations value

{ #category : #'archiving' }
GbxSessionManagerStatResource >> writeSampleTo: statArchive 
	"Poll the stObjectCacheSize before archiving"

	self clientMapSize.
	^super writeSampleTo: statArchive

{ #category : #'archiving' }
GbxSessionManagerStatResource >> instanceDescription

	^'GbsSessionManagerStats'

{ #category : #'initialize-release' }
GbxSessionManagerStatResource >> initializeStatistics
	"Set the receiver's statistics to 0"

	super initializeStatistics.
	numSessions := self newGbxStatFor: 'numSessions'
				value: GBSM loggedInSessions size.
	sessionListProtectInvocations := self 
				newGbxStatFor: 'sessionListProtectInvocations'
				value: 0.
	gciCallProtectInvocations := self 
				newGbxStatFor: 'gciCallProtectInvocations'
				value: 0.
	stObjectCacheSize := self newGbxStatFor: 'clientMapSize' value: 0.
	mainStatSampleTime := self newGbxStatFor: 'mainStatSampleTime' value: 0.
	cacheStatSampleTime := self newGbxStatFor: 'cacheStatSampleTime' value: 0.

{ #category : #'class initialization' }
GbxSessionManagerStatResource class >> initialize
	"Create GbxStatDescriptors for this stat resource"

	"self initialize"

	statDescriptors := OrderedCollection new.
	self
		addStatDescriptor: (GbxStatDescriptor 
					name: 'numSessions'
					description: 'The number of logged in GbsSessions'
					type: GemStone.Gbs.GbxStatArchiver.TypeShort16
					isCounter: false
					isLargerBetter: false
					unit: 'sessions');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'sessionListProtectInvocations'
					description: 'The number of accesses to the sessionListProtect semaphore'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'accesses');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciCallProtectInvocations'
					description: 'The number of accesses to the GciCallProtect semaphore (a GbxCInterface shared variable)'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'accesses');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'clientMapSize'
					description: 'The number of client objects in the client map, the dictionary structure that maps client objects to server objects. There is one client map, shared between all sessions.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'entries');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'mainStatSampleTime'
					description: 'The amount of time spent sampling manager and session statistics'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'microseconds');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'cacheStatSampleTime'
					description: 'The amount of time spent sampling cache statistics'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'microseconds')

{ #category : #'archiving' }
GbxSessionManagerStatResource class >> resourceTypeName
	^'GbsSessionManager'

{ #category : #'archiving' }
GbxSessionManagerStatResource class >> resourceTypeDescription
	^'Statistics associated with the sole instance of GbsSessionManager'

{ #category : #'archiving' }
GbxSessionManagerStatResource class >> resourceTypeId
	^0

