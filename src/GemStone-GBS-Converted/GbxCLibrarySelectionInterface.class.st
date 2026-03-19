Class {
	#name : 'GbxCLibrarySelectionInterface',
	#superclass : 'FFILibrary',
	#classVars : [
		'ErrorCode',
		'ExternalLibraryError'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxCLibrarySelectionInterface class >> tryToLoadLibraryNamed: libName [
	"Pharo compatibility: record the chosen library path and answer a selector object."

	(libName isNil or: [ libName isEmpty ]) ifTrue: [ ^ nil ].
	(((libName includes: $/) or: [ libName includes: $\ ])
		and: [ ([ libName asFileReference exists ] on: Error do: [ false ]) not ])
		ifTrue: [ ^ nil ].
	GbxCPrimInterface vmLibPath: libName.
	^ self uniqueInstance
]

{ #category : 'library selection' }
GbxCLibrarySelectionInterface >> gemstoneLibraryClass [
	^ GbxCPrimInterface vmLibPath: GbsConfiguration sharedLibraryFilename
]
