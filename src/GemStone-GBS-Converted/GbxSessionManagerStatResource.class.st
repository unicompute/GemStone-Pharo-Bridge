Class {
	#name : 'GbxSessionManagerStatResource',
	#superclass : 'GbxStatResource',
	#instVars : [
		'sessionListProtectInvocations',
		'gciCallProtectInvocations',
		'numSessions',
		'stObjectCacheSize',
		'mainStatSampleTime',
		'cacheStatSampleTime'
	],
	#classVars : [
		'statDescriptors'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'stat updating' }
GbxSessionManagerStatResource >> incGciCallProtectInvocations
[

	gciCallProtectInvocations incValue: 1
]

{ #category : 'stat updating' }
GbxSessionManagerStatResource >> incMainStatSampleTime: delta 
[
	mainStatSampleTime incValue: delta
]

{ #category : 'stat updating' }
GbxSessionManagerStatResource >> setNumSessions
[
	numSessions setValue: GBSM loggedInSessions size
]

{ #category : 'stat updating' }
GbxSessionManagerStatResource >> incCacheStatSampleTime: delta 
[
	cacheStatSampleTime incValue: delta
]

{ #category : 'stat updating' }
GbxSessionManagerStatResource >> incSessionListProtectInvocations
[

	sessionListProtectInvocations incValue: 1.
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> clientMapSize
[
	"The number of objects in the client map."

	"Get a stable reference to support concurrency"

	| stoc |
	stoc := GBSM clientMap.
	stoc isNil 
		ifTrue: [stObjectCacheSize setValue: 0]
		ifFalse: [stObjectCacheSize setValue: stoc size].
	^stObjectCacheSize value
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> sessionListProtectInvocations
[

	"The number of times the sessionListProtect mutual exclusion semaphore has been invoked."

	^sessionListProtectInvocations value
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> cacheStatSampleTime
[
	"The number of microseconds spent sampling cache statistics"

	^cacheStatSampleTime value
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> numSessions
[

	"The number of logged in GbsSessions.  If a session has died abnormally, and GBS
	 has not yet discovered its death, this number will erroneously include that session."

	^numSessions value
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> mainStatSampleTime
[
	"The number of microseconds spent sampling manager and session statistics"

	^mainStatSampleTime value
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> gciCallProtectInvocations
[

	"The number of times the GbxCInterface GciCallProtect mutual exclusion semaphore has been invoked."

	^gciCallProtectInvocations value
]

{ #category : 'archiving' }
GbxSessionManagerStatResource >> writeSampleTo: statArchive 
[
	"Poll the stObjectCacheSize before archiving"

	self clientMapSize.
	^super writeSampleTo: statArchive
]

{ #category : 'archiving' }
GbxSessionManagerStatResource >> instanceDescription
[

	^'GbsSessionManagerStats'
]

{ #category : 'initialize-release' }
GbxSessionManagerStatResource >> initializeStatistics
[
	"Set the receiver's statistics to 0"

	| loggedInSessionCount |
	super initializeStatistics.
	loggedInSessionCount := [ GBSM loggedInSessions size ] on: Error do: [ 0 ].
	numSessions := self newGbxStatFor: 'numSessions'
				value: loggedInSessionCount.
	sessionListProtectInvocations := self 
				newGbxStatFor: 'sessionListProtectInvocations'
				value: 0.
	gciCallProtectInvocations := self 
				newGbxStatFor: 'gciCallProtectInvocations'
				value: 0.
	stObjectCacheSize := self newGbxStatFor: 'clientMapSize' value: 0.
	mainStatSampleTime := self newGbxStatFor: 'mainStatSampleTime' value: 0.
	cacheStatSampleTime := self newGbxStatFor: 'cacheStatSampleTime' value: 0.
]

{ #category : 'class initialization' }
GbxSessionManagerStatResource class >> initialize
[
	"Create GbxStatDescriptors for this stat resource"

	"self initialize"

	statDescriptors := OrderedCollection new.
	self
		addStatDescriptor: (self newStatFor: 'numSessions');
		addStatDescriptor: (self newStatFor: 'sessionListProtectInvocations');
		addStatDescriptor: (self newStatFor: 'gciCallProtectInvocations');
		addStatDescriptor: (self newStatFor: 'clientMapSize');
		addStatDescriptor: (self newStatFor: 'mainStatSampleTime');
		addStatDescriptor: (self newStatFor: 'cacheStatSampleTime')
]

{ #category : 'archiving' }
GbxSessionManagerStatResource class >> resourceTypeName
[
	^'GbsSessionManager'
]

{ #category : 'archiving' }
GbxSessionManagerStatResource class >> resourceTypeDescription
[
	^'Statistics associated with the sole instance of GbsSessionManager'
]

{ #category : 'archiving' }
GbxSessionManagerStatResource class >> resourceTypeId
[
	^0
]
