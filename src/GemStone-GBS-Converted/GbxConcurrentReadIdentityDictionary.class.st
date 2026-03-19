Class {
	#name : 'GbxConcurrentReadIdentityDictionary',
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
GbxConcurrentReadIdentityDictionary >> initialize
[
	^self initializeWithCapacity: 16
]

{ #category : 'initialize-release' }
GbxConcurrentReadIdentityDictionary >> initializeWithCapacity: initialCapacity
[
	writeProtect := GbxRecursionLock forMutualExclusion.
	table := IdentityDictionary new: initialCapacity.
	^self
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> at: aKey ifAbsent: aBlock
[
	^table at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> at: aKey put: aValue
[
	^self writeCritical: [ table at: aKey put: aValue ]
]

{ #category : 'removing' }
GbxConcurrentReadIdentityDictionary >> removeKey: aKey
[
	^self writeCritical: [ table removeKey: aKey ]
]

{ #category : 'removing' }
GbxConcurrentReadIdentityDictionary >> removeKey: aKey ifAbsent: aBlock
[
	^self writeCritical: [ table removeKey: aKey ifAbsent: aBlock ]
]

{ #category : 'enumeration' }
GbxConcurrentReadIdentityDictionary >> do: aBlock
[
	table do: aBlock
]

{ #category : 'enumeration' }
GbxConcurrentReadIdentityDictionary >> keysAndValuesDo: aBlock
[
	table keysAndValuesDo: aBlock
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> values
[
	^table values
]

{ #category : 'queries' }
GbxConcurrentReadIdentityDictionary >> size
[
	^table size
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> writeProtect
[
	^writeProtect
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> hasCriticalAccess
[
	^writeProtect isActiveProcessInCriticalRegion
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> writeCritical: aBlock
[
	^writeProtect critical: aBlock
]

{ #category : 'initialize-release' }
GbxConcurrentReadIdentityDictionary >> release
[
	table := IdentityDictionary new.
	^self
]

{ #category : 'instance creation' }
GbxConcurrentReadIdentityDictionary class >> new: initialCapacity
[
	| inst |
	inst := self basicNew.
	inst initializeWithCapacity: initialCapacity.
	^inst
]
