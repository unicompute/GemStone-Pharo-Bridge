Class {
	#name : 'GbxClientObjDictionary',
	#superclass : 'Object',
	#instVars : [
		'table',
		'writeProtect'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxClientObjDictionary >> initialize
[
	^self initializeWithCapacity: 16
]

{ #category : 'initialize-release' }
GbxClientObjDictionary >> initializeWithCapacity: initialCapacity
[
	writeProtect := GbxRecursionLock forMutualExclusion.
	table := IdentityDictionary new: initialCapacity.
	^self
]

{ #category : 'accessing' }
GbxClientObjDictionary >> writeProtect
[
	^writeProtect
]

{ #category : 'accessing' }
GbxClientObjDictionary >> hasCriticalAccess
[
	^writeProtect isActiveProcessInCriticalRegion
]

{ #category : 'accessing' }
GbxClientObjDictionary >> writeCritical: aBlock
[
	^writeProtect critical: aBlock
]

{ #category : 'accessing' }
GbxClientObjDictionary >> delegateAtClient: anObject
[
	^table at: anObject ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxClientObjDictionary >> atNewClient: clientObject putDelegate: aDelegate
[
	^self atClient: clientObject putDelegate: aDelegate
]

{ #category : 'accessing' }
GbxClientObjDictionary >> atClient: clientObject putDelegate: aDelegate
[
	^self writeCritical: [
		| existing updated |
		existing := table at: clientObject ifAbsent: [ nil ].
		updated := existing
			ifNil: [ aDelegate ]
			ifNotNil: [ existing connectingDelegate: aDelegate withClient: clientObject ].
		table at: clientObject put: updated.
		updated ]
]

{ #category : 'removing' }
GbxClientObjDictionary >> removeClient: clientObject forSession: aSession
[
	^self writeCritical: [
		| existing updated |
		existing := table at: clientObject ifAbsent: [ ^nil ].
		updated := existing notForSession: aSession.
		updated
			ifNil: [ table removeKey: clientObject ifAbsent: [ nil ] ]
			ifNotNil: [ table at: clientObject put: updated ].
		updated ]
]

{ #category : 'removing' }
GbxClientObjDictionary >> clearForSession: aSession
[
	^self writeCritical: [
		table keys asArray do: [ :clientObject |
			| updated |
			updated := (table at: clientObject) notForSession: aSession.
			updated
				ifNil: [ table removeKey: clientObject ifAbsent: [ nil ] ]
				ifNotNil: [ table at: clientObject put: updated ] ] ]
]

{ #category : 'enumeration' }
GbxClientObjDictionary >> keysAndValuesDo: aBlock
[
	table keysAndValuesDo: aBlock
]

{ #category : 'queries' }
GbxClientObjDictionary >> size
[
	^table size
]

{ #category : 'testing' }
GbxClientObjDictionary >> auditHashing
[
	^false
]

{ #category : 'cache statistics' }
GbxClientObjDictionary >> inventoryCache
[
]

{ #category : 'private' }
GbxClientObjDictionary >> checkFinalizer
[
]

{ #category : 'initialize-release' }
GbxClientObjDictionary >> release
[
	table := IdentityDictionary new.
	^self
]

{ #category : 'instance creation' }
GbxClientObjDictionary class >> new: initialCapacity
[
	| inst |
	inst := self basicNew.
	inst initializeWithCapacity: initialCapacity.
	^inst
]
