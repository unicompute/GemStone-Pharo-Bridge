Class {
	#name : 'GbsRubyRuntimeProvenanceLink',
	#superclass : 'Object',
	#instVars : [
		'sourceLabel',
		'targetLabel',
		'kind',
		'entry'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyRuntimeProvenanceLink class >> source: aSourceLabel target: aTargetLabel kind: aKind entry: anEntry [
	^ self new
		sourceLabel: aSourceLabel;
		targetLabel: aTargetLabel;
		kind: aKind;
		entry: anEntry;
		yourself
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceLink >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: (self sourceLabel ifNil: [ '(unknown)' ]) asString;
			nextPutAll: ' -> ';
			nextPutAll: (self targetLabel ifNil: [ '(unknown)' ]) asString.
		self kind ifNotNil: [
			stream
				nextPutAll: ' [';
				nextPutAll: self kind asString;
				nextPut: $] ] ]
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> entry [
	^ entry
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> entry: anEntry [
	entry := anEntry
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> kind [
	^ kind
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> kind: aSymbol [
	kind := aSymbol
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceLink >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> sourceLabel [
	^ sourceLabel
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> sourceLabel: aString [
	sourceLabel := aString
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> targetLabel [
	^ targetLabel
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceLink >> targetLabel: aString [
	targetLabel := aString
]
