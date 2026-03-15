Class {
	#name : 'GbxKeyedDummyElement',
	#superclass : 'GbxKeyedElement',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxKeyedDummyElement class >> key: aKey [
	^ self new
		key: aKey;
		yourself
]

{ #category : 'testing' }
GbxKeyedDummyElement >> isDummy [
	^ true
]

{ #category : 'accessing' }
GbxKeyedDummyElement >> printString [
	^ key asString, ' -> <dummy>'
]

{ #category : 'accessing' }
GbxKeyedDummyElement >> value [
	^ nil
]
