Class {
	#name : 'GbxOverrideEditWithCount',
	#superclass : 'GbxOverrideEdit',
	#instVars : [
		'count'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxOverrideEditWithCount class >> count: anInteger [
	^ self new
		count: anInteger;
		yourself
]

{ #category : 'accessing' }
GbxOverrideEditWithCount >> count [
	^ count
]

{ #category : 'accessing' }
GbxOverrideEditWithCount >> count: anObject [
	count := anObject
]

{ #category : 'comparing' }
GbxOverrideEditWithCount >> = anotherObject [
	^ self class = anotherObject class
		and: [ self count = anotherObject count ]
]

{ #category : 'comparing' }
GbxOverrideEditWithCount >> hash [
	^ self class hash bitXor: self count hash
]

{ #category : 'printing' }
GbxOverrideEditWithCount >> storeOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' count: '.
	count storeOn: aStream
]
