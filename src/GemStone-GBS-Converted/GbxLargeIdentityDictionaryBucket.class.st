Class {
	#name : 'GbxLargeIdentityDictionaryBucket',
	#superclass : 'GbxLargeIdentityKeyedCollection',
	#instVars : [
		'tableOffset',
		'checkNecessity'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxLargeIdentityDictionaryBucket >> accessProtector [
	^ owner
		ifNil: [ nil ]
		ifNotNil: [ owner accessProtect ]
]

{ #category : 'adding' }
GbxLargeIdentityDictionaryBucket >> at: key put: value [
	storage at: key put: value.
	^ value
]

{ #category : 'accessing' }
GbxLargeIdentityDictionaryBucket >> at: key otherwise: absentBlock [
	^ storage at: key ifAbsent: absentBlock
]

{ #category : 'key comparing' }
GbxLargeIdentityDictionaryBucket >> compare: keyA with: keyB [
	^ keyA == keyB
]

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> hasWeakValues [
	^ owner notNil and: [ owner weakness = #values ]
]

{ #category : 'initialization' }
GbxLargeIdentityDictionaryBucket >> initializeSize: initialSize owner: anOwner atOffset: anInteger [
	super initialize.
	owner := anOwner.
	tableOffset := anInteger.
	checkNecessity := false.
	tableSize := initialSize.
	^ self
]

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> indexOf: key [
	^ storage keys
		indexOf: key
		ifAbsent: [ 0 ]
]

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> isNecessary [
	^ storage isNotEmpty
]

{ #category : 'instance creation' }
GbxLargeIdentityDictionaryBucket class >> new: initialSize owner: anOwner atOffset: anInteger [
	^ self basicNew initializeSize: initialSize owner: anOwner atOffset: anInteger
]

{ #category : 'removing' }
GbxLargeIdentityDictionaryBucket >> removedKey: key value: value [
	^ value
]

{ #category : 'accessing' }
GbxLargeIdentityDictionaryBucket >> weakness [
	^ owner
		ifNil: [ #none ]
		ifNotNil: [ owner weakness ]
]
