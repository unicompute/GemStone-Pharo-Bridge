Class {
	#name : 'GbxSpecFormatter',
	#superclass : 'Object',
	#instVars : [
		'spec',
		'stream',
		'version'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxSpecFormatter class >> format: anOverrideSet [
	^ self new
		spec: anOverrideSet;
		format
]

{ #category : 'instance creation' }
GbxSpecFormatter class >> format: anOverrideSet version: aVersionString [
	^ self new
		spec: anOverrideSet;
		version: aVersionString;
		format
]

{ #category : 'formatting' }
GbxSpecFormatter >> format [
	stream := WriteStream on: String new.
	version ifNotNil: [
		stream
			nextPutAll: '"version: ';
			nextPutAll: version asString;
			nextPutAll: '"';
			cr;
			cr ].
	stream
		nextPutAll: 'spec';
		cr;
		cr;
		tab;
		nextPut: $^.
	spec storeOn: stream.
	^ stream contents
]

{ #category : 'accessing' }
GbxSpecFormatter >> spec: anOverrideSet [
	spec := anOverrideSet
]

{ #category : 'accessing' }
GbxSpecFormatter >> version: aVersionString [
	version := aVersionString
]
