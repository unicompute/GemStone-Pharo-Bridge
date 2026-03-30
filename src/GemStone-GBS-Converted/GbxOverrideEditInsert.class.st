Class {
	#name : 'GbxOverrideEditInsert',
	#superclass : 'GbxOverrideEdit',
	#instVars : [
		'string'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxOverrideEditInsert class >> string: aString [
	^ self new
		string: aString;
		yourself
]

{ #category : 'applying' }
GbxOverrideEditInsert >> applyFrom: inputStream to: outputStream [
	outputStream nextPutAll: string
]

{ #category : 'accessing' }
GbxOverrideEditInsert >> count [
	^ self string size
]

{ #category : 'comparing' }
GbxOverrideEditInsert >> = anotherObject [
	^ self class = anotherObject class
		and: [ self string = anotherObject string ]
]

{ #category : 'comparing' }
GbxOverrideEditInsert >> hash [
	^ self class hash bitXor: self string hash
]

{ #category : 'printing' }
GbxOverrideEditInsert >> storeOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' string: '.
	self string storeOn: aStream
]

{ #category : 'accessing' }
GbxOverrideEditInsert >> string [
	^ string
]

{ #category : 'accessing' }
GbxOverrideEditInsert >> string: anObject [
	string := anObject
]
