Class {
	#name : 'GbxClassHolder',
	#superclass : 'Object',
	#instVars : [
		'name',
		'version',
		'numberOfVersions',
		'depth',
		'instVarNames',
		'isSpecial',
		'remoteClass'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxClassHolder class >> name: aString proxy: aProxy [
	^ self new
		name: aString;
		proxy: aProxy;
		yourself
]

{ #category : 'instance creation' }
GbxClassHolder class >> name: aString proxy: aProxy version: anInteger numberOfVersions: aCount [
	^ self new
		name: aString;
		proxy: aProxy;
		version: anInteger;
		numberOfVersions: aCount;
		yourself
]

{ #category : 'accessing' }
GbxClassHolder >> name [
	^ name
]

{ #category : 'accessing' }
GbxClassHolder >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxClassHolder >> numberOfVersions [
	^ numberOfVersions ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxClassHolder >> numberOfVersions: anInteger [
	numberOfVersions := anInteger
]

{ #category : 'accessing' }
GbxClassHolder >> proxy [
	^ remoteClass
]

{ #category : 'accessing' }
GbxClassHolder >> proxy: aProxy [
	remoteClass := aProxy
]

{ #category : 'accessing' }
GbxClassHolder >> remoteClass [
	^ remoteClass
]

{ #category : 'printing' }
GbxClassHolder >> printOn: aStream [
	aStream nextPutAll: self name.
	self numberOfVersions > 0 ifTrue: [
		aStream
			nextPutAll: ' v';
			print: self version;
			nextPut: $/;
			print: self numberOfVersions ]
]

{ #category : 'accessing' }
GbxClassHolder >> version [
	^ version ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxClassHolder >> version: anInteger [
	version := anInteger
]
