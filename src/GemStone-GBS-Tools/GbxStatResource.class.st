Class {
	#name : 'GbxStatResource',
	#superclass : 'Object',
	#instVars : [
		'name',
		'stats',
		'resourceType'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStatResource class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'instance creation' }
GbxStatResource class >> named: aString type: aSymbol [
	^ self new
		name: aString;
		resourceType: aSymbol;
		yourself
]

{ #category : 'initialization' }
GbxStatResource >> initialize [
	super initialize.
	stats := Dictionary new.
]

{ #category : 'accessing' }
GbxStatResource >> addStat: aStat [
	"Add a stat to this resource"
	stats at: aStat name put: aStat.
]

{ #category : 'accessing' }
GbxStatResource >> collectStats [
	"Collect statistics from the resource"
	self subclassResponsibility
]

{ #category : 'accessing' }
GbxStatResource >> name [
	^ name
]

{ #category : 'accessing' }
GbxStatResource >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxStatResource >> printString [
	^ resourceType ifNil: [ name ] ifNotNil: [ name, ' (', resourceType asString, ')' ]
]

{ #category : 'accessing' }
GbxStatResource >> resourceType [
	^ resourceType
]

{ #category : 'accessing' }
GbxStatResource >> resourceType: aSymbol [
	resourceType := aSymbol
]

{ #category : 'accessing' }
GbxStatResource >> statAt: aString [
	^ stats at: aString ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxStatResource >> stats [
	^ stats
]

{ #category : 'accessing' }
GbxStatResource >> summary [
	"Return a summary string of all stats"
	| stream |
	
	stream := WriteStream on: String new.
	stream nextPutAll: name; cr.
	
	stats keysAndValuesDo: [ :name :stat |
		stream
			tab; nextPutAll: name; tab;
			nextPutAll: stat value asString; cr.
	].
	
	^ stream contents
]
