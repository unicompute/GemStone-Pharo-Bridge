Class {
	#name : 'GbsLibrary',
	#superclass : 'FFILibrary',
	#classInstVars : [
		'MacLibraryName'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing - platform' }
GbsLibrary class >> macLibraryName [
	^ MacLibraryName ifNil: [ 
		MacLibraryName := '/Users/tariq/GemStone64Bit3.7.4.3-arm64.Darwin/lib/libgcirpc-3.7.4.3-64.dylib' ]
]

{ #category : 'as yet unclassified' }
GbsLibrary class >> macLibraryName: aString [
	MacLibraryName := aString
]

{ #category : 'accessing - platform' }
GbsLibrary >> macLibraryName [
	^ self class macLibraryName
]
