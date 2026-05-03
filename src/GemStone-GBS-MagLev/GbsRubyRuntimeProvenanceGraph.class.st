Class {
	#name : 'GbsRubyRuntimeProvenanceGraph',
	#superclass : 'Object',
	#instVars : [
		'links',
		'actions'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyRuntimeProvenanceGraph class >> links: aCollection [
	^ self new
		links: aCollection;
		yourself
]

{ #category : 'instance creation' }
GbsRubyRuntimeProvenanceGraph class >> links: aCollection actions: anActionCollection [
	^ self new
		links: aCollection;
		actions: anActionCollection;
		yourself
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceGraph >> actions [
	^ actions ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceGraph >> actions: aCollection [
	actions := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> actionsForEntry: anEntry [
	anEntry ifNil: [ ^ #() ].
	^ self actions select: [ :each |
		each sourceEntry == anEntry
			or: [ each sourceEntry = anEntry ] ]
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> actionForBrowserRow: aRow [
	| kind object |
	aRow ifNil: [ ^ nil ].
	kind := aRow at: 3 ifAbsent: [ nil ].
	object := aRow at: 4 ifAbsent: [ nil ].
	kind = #action ifTrue: [ ^ object ].
	^ nil
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> browserRows [
	| rows |
	rows := OrderedCollection new.
	self entries do: [ :each |
		rows add: { 'Entry'. each displayString. #entry. each } ].
	self links do: [ :each |
		rows add: { 'Link'. each displayString. #link. each } ].
	self actions do: [ :each |
		rows add: { 'Action'. each displayString. #action. each } ].
	^ rows asArray
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> entries [
	^ (((self links collect: [ :each | each entry ])
		, (self actions collect: [ :each | each sourceEntry ]))
			reject: #isNil) asSet asArray
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> entriesForSourceLabel: aString [
	aString ifNil: [ ^ #() ].
	^ ((self linksFromSourceLabel: aString) collect: [ :each | each entry ])
		reject: #isNil
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> isEmpty [
	^ self links isEmpty and: [ self actions isEmpty ]
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> isActionBrowserRow: aRow [
	^ (self actionForBrowserRow: aRow) notNil
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceGraph >> links [
	^ links ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceGraph >> links: aCollection [
	links := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> linksForEntry: anEntry [
	anEntry ifNil: [ ^ #() ].
	^ self links select: [ :each |
		each entry == anEntry
			or: [ each entry = anEntry ] ]
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> objectForBrowserRow: aRow [
	aRow ifNil: [ ^ nil ].
	^ aRow at: 4 ifAbsent: [ nil ]
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceGraph >> previewForBrowserRow: aRow [
	| object kind title detailText |
	aRow ifNil: [ ^ { #rawPrintString -> self text } asDictionary ].
	object := self objectForBrowserRow: aRow.
	kind := aRow at: 3 ifAbsent: [ nil ].
	title := (aRow at: 1 ifAbsent: [ 'Entry' ]) asString.
	detailText := kind = #entry
		ifTrue: [ self textForEntry: object ]
		ifFalse: [ kind = #link
			ifTrue: [ self textForLink: object ]
			ifFalse: [ kind = #action
				ifTrue: [ self textForAction: object ]
				ifFalse: [ self text ] ] ].
	^ {
		#rawPrintString -> (String streamContents: [ :stream |
			stream
				nextPutAll: title;
				nextPutAll: ' Detail';
				cr; cr;
				nextPutAll: detailText ]) } asDictionary
]

{ #category : 'actions' }
GbsRubyRuntimeProvenanceGraph >> executeBrowserRow: aRow using: aRuntimeFacade [
	| action |
	action := self actionForBrowserRow: aRow.
	action ifNil: [ ^ nil ].
	^ aRuntimeFacade executeProvenanceAction: action
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> linksFromSourceLabel: aString [
	aString ifNil: [ ^ #() ].
	^ self links select: [ :each |
		each sourceLabel = aString ]
]

{ #category : 'querying' }
GbsRubyRuntimeProvenanceGraph >> linksToTargetLabel: aString [
	aString ifNil: [ ^ #() ].
	^ self links select: [ :each |
		each targetLabel = aString ]
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceGraph >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self text;
		nextPut: $)
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceGraph >> textForAction: anAction [
	anAction ifNil: [ ^ self text ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Action';
			cr;
			nextPutAll: anAction displayString.
		anAction sourceEntry ifNotNil: [
			stream
				cr; cr;
				nextPutAll: 'Source Entry';
				cr;
				nextPutAll: anAction sourceEntry displayString ] ]
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceGraph >> textForEntry: anEntry [
	anEntry ifNil: [ ^ self text ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Entry';
			cr;
			nextPutAll: anEntry displayString.
		(self linksForEntry: anEntry) ifNotEmpty: [ :linksForEntry |
			stream cr; cr; nextPutAll: 'Links'; cr.
			linksForEntry do: [ :each |
				stream nextPutAll: each displayString; cr ] ].
		(self actionsForEntry: anEntry) ifNotEmpty: [ :actionsForEntry |
			stream cr; nextPutAll: 'Actions'; cr.
			actionsForEntry do: [ :each |
				stream nextPutAll: each displayString; cr ] ] ]
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceGraph >> textForLink: aLink [
	aLink ifNil: [ ^ self text ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Link';
			cr;
			nextPutAll: aLink displayString.
		aLink entry ifNotNil: [
			stream
				cr; cr;
				nextPutAll: 'Entry';
				cr;
				nextPutAll: aLink entry displayString ] ]
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceGraph >> text [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Ruby Runtime Provenance'; cr.
		(self links isEmpty and: [ self actions isEmpty ])
			ifTrue: [ stream nextPutAll: '(empty)'; cr ]
			ifFalse: [
				self links do: [ :each |
					stream nextPutAll: each displayString; cr ].
				self actions ifNotEmpty: [
					stream cr; nextPutAll: 'Actions'; cr.
					self actions do: [ :each |
						stream nextPutAll: each displayString; cr ] ] ] ]
]
