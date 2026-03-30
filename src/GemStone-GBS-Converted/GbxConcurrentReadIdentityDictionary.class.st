Class {
	#name : 'GbxConcurrentReadIdentityDictionary',
	#superclass : 'Object',
	#instVars : [
		'storage',
		'accessProtect'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxConcurrentReadIdentityDictionary class >> new: initialSize [
	^ self new
		initializeWithSize: initialSize;
		yourself
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> at: aKey ifAbsent: aBlock [
	^ self readCritical: [ storage at: aKey ifAbsent: aBlock ]
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> at: aKey put: aValue [
	^ self writeCritical: [
		storage at: aKey put: aValue.
		aValue ]
]

{ #category : 'testing' }
GbxConcurrentReadIdentityDictionary >> includesKey: aKey [
	^ self readCritical: [ storage includesKey: aKey ]
]

{ #category : 'initialization' }
GbxConcurrentReadIdentityDictionary >> initialize [
	super initialize.
	self initializeWithSize: 16
]

{ #category : 'initialization' }
GbxConcurrentReadIdentityDictionary >> initializeWithSize: anInteger [
	storage := IdentityDictionary new: (anInteger ifNil: [ 16 ] ifNotNil: [ anInteger max: 1 ]).
	accessProtect := Semaphore forMutualExclusion
]

{ #category : 'enumerating' }
GbxConcurrentReadIdentityDictionary >> keysAndValuesDo: aBlock [
	| snapshot |
	snapshot := self readCritical: [ storage associations asArray ].
	snapshot do: [ :assoc | aBlock value: assoc key value: assoc value ]
]

{ #category : 'enumerating' }
GbxConcurrentReadIdentityDictionary >> readCritical: aBlock [
	^ accessProtect critical: aBlock
]

{ #category : 'removing' }
GbxConcurrentReadIdentityDictionary >> removeKey: aKey ifAbsent: aBlock [
	^ self writeCritical: [ storage removeKey: aKey ifAbsent: aBlock ]
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> size [
	^ self readCritical: [ storage size ]
]

{ #category : 'accessing' }
GbxConcurrentReadIdentityDictionary >> values [
	^ self readCritical: [ storage values asArray ]
]

{ #category : 'enumerating' }
GbxConcurrentReadIdentityDictionary >> writeCritical: aBlock [
	^ accessProtect critical: aBlock
]
