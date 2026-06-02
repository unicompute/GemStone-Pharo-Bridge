Class {
	#name : 'GbsReplicationPolicy',
	#superclass : 'Object',
	#instVars : [
		'autoMarkDirty',
		'blockReplicationPolicy',
		'defaultFaultPolicy',
		'faultLevelRpc',
		'freeSlotsOnStubbing',
		'traversalBufferSize'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsReplicationPolicy class >> default [
	^ self new initializeDefaults
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> forSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionReplicationPolicies)
		at: aSession
		ifAbsentPut: [ self default ]
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> forSession: aSession put: aPolicy [
	^ (aSession class weakRegistryNamed: #GbsSessionReplicationPolicies)
		at: aSession
		put: aPolicy
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> fromConfiguration: aConfiguration [
	^ self new
		initializeFromConfiguration: aConfiguration;
		yourself
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> resetForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionReplicationPolicies)
		removeKey: aSession
		ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsReplicationPolicy >> autoMarkDirty [
	^ autoMarkDirty
]

{ #category : 'accessing' }
GbsReplicationPolicy >> autoMarkDirty: aBoolean [
	autoMarkDirty := aBoolean
]

{ #category : 'accessing' }
GbsReplicationPolicy >> blockReplicationPolicy [
	^ blockReplicationPolicy
]

{ #category : 'accessing' }
GbsReplicationPolicy >> blockReplicationPolicy: aString [
	blockReplicationPolicy := aString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> defaultFaultPolicy [
	^ defaultFaultPolicy
]

{ #category : 'accessing' }
GbsReplicationPolicy >> defaultFaultPolicy: aString [
	defaultFaultPolicy := aString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> faultLevelRpc [
	^ faultLevelRpc
]

{ #category : 'accessing' }
GbsReplicationPolicy >> faultLevelRpc: anInteger [
	faultLevelRpc := anInteger
]

{ #category : 'accessing' }
GbsReplicationPolicy >> freeSlotsOnStubbing [
	^ freeSlotsOnStubbing
]

{ #category : 'accessing' }
GbsReplicationPolicy >> freeSlotsOnStubbing: aBoolean [
	freeSlotsOnStubbing := aBoolean
]

{ #category : 'initialization' }
GbsReplicationPolicy >> initializeDefaults [
	^ self initializeFromConfiguration: ([ GbsConfiguration current ] on: Error do: [ nil ])
]

{ #category : 'initialization' }
GbsReplicationPolicy >> initializeFromConfiguration: aConfiguration [
	autoMarkDirty := self valueAt: #autoMarkDirty fromConfiguration: aConfiguration default: true.
	blockReplicationPolicy := self valueAt: #blockReplicationPolicy fromConfiguration: aConfiguration default: 'replicate'.
	defaultFaultPolicy := self valueAt: #defaultFaultPolicy fromConfiguration: aConfiguration default: 'lazy'.
	faultLevelRpc := self valueAt: #faultLevelRpc fromConfiguration: aConfiguration default: 4.
	freeSlotsOnStubbing := self valueAt: #freeSlotsOnStubbing fromConfiguration: aConfiguration default: true.
	traversalBufferSize := self valueAt: #traversalBufferSize fromConfiguration: aConfiguration default: 250000.
	^ self
]

{ #category : 'accessing' }
GbsReplicationPolicy >> traversalBufferSize [
	^ traversalBufferSize
]

{ #category : 'accessing' }
GbsReplicationPolicy >> traversalBufferSize: anInteger [
	traversalBufferSize := anInteger
]

{ #category : 'private' }
GbsReplicationPolicy >> valueAt: selector fromConfiguration: aConfiguration default: defaultValue [
	aConfiguration ifNil: [ ^ defaultValue ].
	(aConfiguration respondsTo: selector) ifTrue: [
		^ [ aConfiguration perform: selector ] on: Error do: [ defaultValue ] ].
	(aConfiguration respondsTo: #valueAt:ifAbsent:) ifTrue: [
		^ aConfiguration valueAt: selector ifAbsent: defaultValue ].
	^ defaultValue
]
