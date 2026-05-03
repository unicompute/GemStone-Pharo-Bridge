Class {
	#name : 'GbsReportSection',
	#superclass : 'Object',
	#instVars : [
		'title',
		'items',
		'emptyText',
		'lineBlock'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsReportSection class >> title: aString items: aCollection [
	^ self
		title: aString
		items: aCollection
		lineBlock: nil
]

{ #category : 'instance creation' }
GbsReportSection class >> title: aString items: aCollection lineBlock: aBlock [
	^ self new
		title: aString;
		items: aCollection;
		lineBlock: aBlock;
		yourself
]

{ #category : 'printing' }
GbsReportSection >> appendOn: aStream [
	aStream nextPutAll: self title; cr.
	self displayLines
		ifEmpty: [ aStream nextPutAll: self emptyText; cr ]
		ifNotEmpty: [ :lines |
			lines do: [ :each |
				aStream nextPutAll: each asString; cr ] ]
]

{ #category : 'querying' }
GbsReportSection >> displayLines [
	^ self items collect: [ :each |
		self lineFor: each ]
]

{ #category : 'accessing' }
GbsReportSection >> emptyText [
	^ emptyText ifNil: [ '(empty)' ]
]

{ #category : 'accessing' }
GbsReportSection >> emptyText: aString [
	emptyText := aString ifNil: [ '(empty)' ] ifNotNil: [ aString asString ]
]

{ #category : 'querying' }
GbsReportSection >> isEmpty [
	^ self items isEmpty
]

{ #category : 'accessing' }
GbsReportSection >> items [
	^ items ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsReportSection >> items: aCollection [
	items := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
GbsReportSection >> lineBlock [
	^ lineBlock
]

{ #category : 'accessing' }
GbsReportSection >> lineBlock: aBlock [
	lineBlock := aBlock
]

{ #category : 'private' }
GbsReportSection >> lineFor: anObject [
	lineBlock ifNotNil: [ ^ lineBlock value: anObject ].
	(anObject respondsTo: #displayString) ifTrue: [ ^ anObject displayString ].
	(anObject respondsTo: #summaryLine) ifTrue: [ ^ anObject summaryLine ].
	^ anObject asString
]

{ #category : 'printing' }
GbsReportSection >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self title;
		nextPut: $)
]

{ #category : 'printing' }
GbsReportSection >> text [
	^ String streamContents: [ :stream |
		self appendOn: stream ]
]

{ #category : 'accessing' }
GbsReportSection >> title [
	^ title ifNil: [ 'Section' ]
]

{ #category : 'accessing' }
GbsReportSection >> title: aString [
	title := aString ifNil: [ 'Section' ] ifNotNil: [ aString asString ]
]
