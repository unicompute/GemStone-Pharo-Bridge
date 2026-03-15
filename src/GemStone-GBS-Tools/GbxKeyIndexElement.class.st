Class {
	#name : 'GbxKeyIndexElement',
	#superclass : 'GbxKeyedElement',
	#instVars : [
		'index'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxKeyIndexElement class >> key: aKey index: anIndex value: aValue [
	^ self new
		key: aKey;
		index: anIndex;
		value: aValue;
		yourself
]

{ #category : 'accessing' }
GbxKeyIndexElement >> index [
	^ index
]

{ #category : 'accessing' }
GbxKeyIndexElement >> index: anInteger [
	index := anInteger
]

{ #category : 'accessing' }
GbxKeyIndexElement >> printString [
	^ '[', index asString, '] ', key asString, ' -> ',
	  (value ifNil: [ '<nil>' ] ifNotNil: [ value printString ])
]
