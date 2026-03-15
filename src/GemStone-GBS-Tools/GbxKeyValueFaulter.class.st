Class {
	#name : 'GbxKeyValueFaulter',
	#superclass : 'Object',
	#instVars : [
		'dictionary',
		'key',
		'session',
		'isFaulted',
		'cachedValue'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxKeyValueFaulter class >> dictionary: aDict key: aKey [
	^ self new
		dictionary: aDict;
		key: aKey;
		yourself
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> cachedValue [
	^ cachedValue
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> dictionary [
	^ dictionary
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> dictionary: aDict [
	dictionary := aDict
]

{ #category : 'faulting' }
GbxKeyValueFaulter >> faultIn [
	"Fault in the value from server"
	| script |
	
	isFaulted ifTrue: [ ^ cachedValue ].
	session ifNil: [ ^ nil ].
	dictionary ifNil: [ ^ nil ].
	
	script := '[
		| dict |
		dict := Object _objectForOop: ', dictionary oop asString, '.
		dict at: ', key asString, ' ifAbsent: [ nil ]
	] value'.
	
	cachedValue := session executeAndFetch: script.
	isFaulted := true.
	^ cachedValue
]

{ #category : 'testing' }
GbxKeyValueFaulter >> isFaulted [
	^ isFaulted ifNil: [ false ]
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> key [
	^ key
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> key: aKey [
	key := aKey
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> printString [
	^ 'KeyValueFaulter (', key asString, ', faulted: ', isFaulted asString, ')'
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> session [
	^ session
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxKeyValueFaulter >> value [
	^ self faultIn
]
