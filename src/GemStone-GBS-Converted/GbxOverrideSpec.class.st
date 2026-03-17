Class {
	#name : #'GbxOverrideSpec',
	#superclass : #'Object',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'storing' }
GbxOverrideSpec >> storeOverrides: someOverrides withKeyword: aKeyword on: aStream

	aStream space.
	aStream nextPutAll: aKeyword.
	aStream space.
	self storeSortedArray: someOverrides on: aStream

{ #category : #'storing' }
GbxOverrideSpec >> storeArray: anArray on: aStream

	aStream nextPutAll: '{ '.
	anArray
		do: [:each | each storeOn: aStream]
		separatedBy: [aStream nextPutAll: '. '].
	aStream nextPutAll: ' }'

{ #category : #'storing' }
GbxOverrideSpec >> storeSortedArray: anArray on: aStream

	self storeArray: (anArray
				asSortedCollection: [:a :b | a printString < b printString])
		on: aStream

