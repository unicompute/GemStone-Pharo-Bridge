Class {
	#name : 'GbxKeyedElement',
	#superclass : 'Object',
	#instVars : [
		'key',
		'value',
		'isFaulted'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxKeyedElement class >> key: aKey value: aValue [
	^ self new
		key: aKey;
		value: aValue;
		yourself
]

{ #category : 'comparing' }
GbxKeyedElement >> = anObject [
	^ (anObject isKindOf: GbxKeyedElement)
		and: [ key = anObject key ]
]

{ #category : 'accessing' }
GbxKeyedElement >> asAssociation [
	^ key -> value
]

{ #category : 'accessing' }
GbxKeyedElement >> faultIn [
	"Fault in the value if needed"
	^ value
]

{ #category : 'testing' }
GbxKeyedElement >> hasKey: aKey [
	^ key = aKey
]

{ #category : 'accessing' }
GbxKeyedElement >> hash [
	^ key hash
]

{ #category : 'testing' }
GbxKeyedElement >> isFaulted [
	^ isFaulted ifNil: [ false ]
]

{ #category : 'testing' }
GbxKeyedElement >> isFaulted: aBoolean [
	isFaulted := aBoolean
]

{ #category : 'accessing' }
GbxKeyedElement >> key [
	^ key
]

{ #category : 'accessing' }
GbxKeyedElement >> key: aKey [
	key := aKey
]

{ #category : 'accessing' }
GbxKeyedElement >> printString [
	^ key asString, ' -> ', (value ifNil: [ '<nil>' ] ifNotNil: [ value printString ])
]

{ #category : 'accessing' }
GbxKeyedElement >> value [
	^ self faultIn
]

{ #category : 'accessing' }
GbxKeyedElement >> value: anObject [
	value := anObject
]
