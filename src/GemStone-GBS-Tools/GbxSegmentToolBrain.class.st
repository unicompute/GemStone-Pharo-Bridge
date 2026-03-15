Class {
	#name : 'GbxSegmentToolBrain',
	#superclass : 'Object',
	#instVars : [
		'session',
		'segments',
		'selectedSegment',
		'window'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxSegmentToolBrain class >> openOn: aSession [
	"Open the segment tool on a session"
	| brain |
	
	brain := self new.
	brain session: aSession.
	brain openWindow.
	^ brain
]

{ #category : 'actions' }
GbxSegmentToolBrain >> compactSegment [
	"Compact the selected segment"
	| script |
	
	selectedSegment ifNil: [ ^ false ].
	session ifNil: [ ^ false ].
	
	script := '[
		| seg |
		seg := Object _objectForOop: ', selectedSegment proxy oop asString, '.
		seg compact
	] value'.
	
	session execute: script.
	self refreshSegments.
	^ true
]

{ #category : 'actions' }
GbxSegmentToolBrain >> deleteSegment [
	"Delete the selected segment (dangerous!)"
	| script |
	
	selectedSegment ifNil: [ ^ false ].
	session ifNil: [ ^ false ].
	
	(ConfirmDialog confirm: 'Are you sure you want to delete this segment?') ifFalse: [ ^ false ].
	
	script := '[
		| seg |
		seg := Object _objectForOop: ', selectedSegment proxy oop asString, '.
		seg delete
	] value'.
	
	session execute: script.
	self refreshSegments.
	^ true
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> fetchSegments [
	"Fetch all segments from GemStone"
	| script result |
	
	session ifNil: [ ^ #() ].
	
	script := '[
		| segs stream |
		segs := System segmentList.
		stream := WriteStream on: String new.
		segs do: [ :seg |
			stream
				nextPutAll: seg name asString; nextPutAll: ''|'';
				nextPutAll: (Reflection oopOf: seg) asString; nextPutAll: ''|'';
				nextPutAll: seg size asString; nextPutAll: ''|'';
				nextPutAll: seg percentFull asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	^ self parseSegments: result
]

{ #category : 'initialization' }
GbxSegmentToolBrain >> initialize [
	super initialize.
	segments := OrderedCollection new.
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> parseSegments: aString [
	"Parse segments string into array of GbxSegmentHolder"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: $|.
			parts size >= 4 ifTrue: [
				| holder |
				holder := GbxSegmentHolder new
					name: parts first;
					proxy: (session objectFromOop: parts second asInteger);
					size: parts third asInteger;
					percentFull: parts fourth asInteger;
					session: session;
					yourself.
				items add: holder.
			]
		]
	].
	^ items asArray
]

{ #category : 'window' }
GbxSegmentToolBrain >> openWindow [
	"Open the segment tool window"
	| presenter |
	
	presenter := GbxSegmentTool new.
	presenter brain: self.
	presenter session: session.
	presenter open.
	window := presenter.
	
	self refreshSegments.
]

{ #category : 'actions' }
GbxSegmentToolBrain >> refreshSegments [
	"Refresh the segment list"
	segments := self fetchSegments.
	window ifNotNil: [
		window updateSegments: segments.
	].
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> segments [
	^ segments
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> selectedSegment [
	^ selectedSegment
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> selectedSegment: aSegmentHolder [
	selectedSegment := aSegmentHolder
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> session [
	^ session
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbxSegmentToolBrain >> showSegmentInfo [
	"Show detailed info about selected segment"
	| info |
	
	selectedSegment ifNil: [ ^ '' ].
	
	info := 'Segment: ', selectedSegment name, String cr,
			'Size: ', selectedSegment size asString, String cr,
			'Percent Full: ', selectedSegment percentFull asString, '%'.
	
	^ info
]
