Class {
	#name : 'CoreGbsSemanticDirtyStoreFixture',
	#superclass : 'Object',
	#instVars : [
		'key',
		'value'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'dirty store' }
CoreGbsSemanticDirtyStoreFixture >> gbsDirtyStoreRequiresSemanticCommand [
	^ true
]

{ #category : 'accessing' }
CoreGbsSemanticDirtyStoreFixture >> key [
	^ key
]

{ #category : 'accessing' }
CoreGbsSemanticDirtyStoreFixture >> key: anObject [
	key := anObject
]

{ #category : 'accessing' }
CoreGbsSemanticDirtyStoreFixture >> value [
	^ value
]

{ #category : 'accessing' }
CoreGbsSemanticDirtyStoreFixture >> value: anObject [
	value := anObject
]
