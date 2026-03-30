Class {
	#name : 'GbxKeyedElement',
	#superclass : 'Object',
	#instVars : [
		'keyDelegate',
		'keyName',
		'valueDelegate',
		'valueName',
		'partName'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxKeyedElement class >> of: anObject key: aKey keyName: aKeyName value: aValue valueName: aValueName [
	^ self new
		keyDelegate: aKey;
		keyName: aKeyName;
		valueDelegate: aValue;
		valueName: aValueName;
		yourself
]

{ #category : 'comparing' }
GbxKeyedElement >> = anObject [
	self class = anObject class ifFalse: [ ^ false ].
	^ self sameTypeEquals: anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> basicValueDelegate [
	^ valueDelegate
]

{ #category : 'printing' }
GbxKeyedElement >> displayString [
	^ valueName ifNil: [ self value printString ]
]

{ #category : 'accessing' }
GbxKeyedElement >> key [
	^ keyDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> keyDelegate [
	^ keyDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> keyDelegate: anObject [
	keyDelegate := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> keyName: aString [
	keyName := aString
]

{ #category : 'accessing' }
GbxKeyedElement >> partName [
	^ partName ifNil: [ keyName ifNil: [ self key printString ] ]
]

{ #category : 'accessing' }
GbxKeyedElement >> partName: aString [
	partName := aString
]

{ #category : 'updating' }
GbxKeyedElement >> refresh [
	^ self
]

{ #category : 'comparing' }
GbxKeyedElement >> sameTypeEquals: anObject [
	^ self key == anObject key and: [ self value == anObject value ]
]

{ #category : 'printing' }
GbxKeyedElement >> text [
	^ self displayString
]

{ #category : 'accessing' }
GbxKeyedElement >> value [
	^ valueDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> value: anObject [
	valueDelegate := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> valueDelegate [
	^ valueDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> valueDelegate: anObject [
	valueDelegate := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> valueName: aString [
	valueName := aString
]
