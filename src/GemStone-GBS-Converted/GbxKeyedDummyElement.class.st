Class {
	#name : 'GbxKeyedDummyElement',
	#superclass : 'GbxKeyIndexElement',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxKeyedDummyElement >> key: anObject [
	self
		keyDelegate: anObject;
		keyName: anObject asString;
		partName: '[', anObject asString, ']'
]

{ #category : 'accessing' }
GbxKeyedDummyElement >> value: anObject [
	self valueDelegate: anObject
]
