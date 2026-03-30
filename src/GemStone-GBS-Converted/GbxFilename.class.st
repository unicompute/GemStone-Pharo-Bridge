Class {
	#name : 'GbxFilename',
	#superclass : 'Object',
	#instVars : [
		'reference'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'defaults' }
GbxFilename class >> concreteClass [
	^ self
]

{ #category : 'defaults' }
GbxFilename class >> currentDirectory [
	^ self named: FileSystem workingDirectory fullName
]

{ #category : 'instance creation' }
GbxFilename class >> named: aString [
	^ self new
		reference: (FileSystem disk referenceTo: aString);
		yourself
]

{ #category : 'printing' }
GbxFilename >> asString [
	^ reference fullName
]

{ #category : 'testing' }
GbxFilename >> exists [
	^ reference exists
]

{ #category : 'actions' }
GbxFilename >> ensureDelete [
	reference ensureDelete
]

{ #category : 'printing' }
GbxFilename >> fullName [
	^ reference fullName
]

{ #category : 'accessing' }
GbxFilename >> readStream [
	^ reference readStream
]

{ #category : 'accessing' }
GbxFilename >> reference: aFileReference [
	reference := aFileReference
]

{ #category : 'printing' }
GbxFilename >> tail [
	^ reference basename
]

{ #category : 'accessing' }
GbxFilename >> writeStream [
	^ reference writeStream
]

{ #category : 'accessing' }
GbxFilename >> writeStreamDo: aBlock [
	^ reference writeStreamDo: aBlock
]
