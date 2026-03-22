Class {
	#name : 'GbxKeyValueFaulterTool',
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
GbxKeyValueFaulterTool class >> dictionary: aDict key: aKey [
	^ self new
		dictionary: aDict;
		key: aKey;
		yourself
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> cachedValue [
	^ cachedValue
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> dictionary [
	^ dictionary
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> dictionary: aDict [
	dictionary := aDict
]

{ #category : 'faulting' }
GbxKeyValueFaulterTool >> faultIn [
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
GbxKeyValueFaulterTool >> isFaulted [
	^ isFaulted ifNil: [ false ]
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> key [
	^ key
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> key: aKey [
	key := aKey
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> printString [
	^ 'KeyValueFaulter (', key asString, ', faulted: ', isFaulted asString, ')'
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxKeyValueFaulterTool >> value [
	^ self faultIn
]
