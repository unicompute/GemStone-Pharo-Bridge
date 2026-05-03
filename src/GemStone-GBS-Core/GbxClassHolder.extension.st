Extension { #name : 'GbxClassHolder' }

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder class >> nameRegistry [
	^ Smalltalk globals
		at: #GbxClassHolderNameRegistry
		ifAbsentPut: [ WeakKeyDictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder class >> name: aString proxy: aProxy [
	^ self new
		name: aString;
		proxy: aProxy;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder class >> name: aString proxy: aProxy version: anInteger numberOfVersions: aCount [
	^ self new
		name: aString;
		proxy: aProxy;
		version: anInteger;
		numberOfVersions: aCount;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> name [
	^ self class nameRegistry at: self ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> name: aString [
	self class nameRegistry at: self put: aString
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> numberOfVersions [
	^ numberOfVersions ifNil: [ 0 ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> numberOfVersions: anInteger [
	numberOfVersions := anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> proxy [
	^ remoteClass
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> proxy: aProxy [
	remoteClass := aProxy
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> remoteClass [
	^ remoteClass
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> printOn: aStream [
	aStream nextPutAll: (self name ifNil: [ self class name ]).
	self numberOfVersions > 0 ifTrue: [
		aStream
			nextPutAll: ' v';
			print: self version;
			nextPut: $/;
			print: self numberOfVersions ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> version [
	^ version ifNil: [ 0 ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClassHolder >> version: anInteger [
	version := anInteger
]
