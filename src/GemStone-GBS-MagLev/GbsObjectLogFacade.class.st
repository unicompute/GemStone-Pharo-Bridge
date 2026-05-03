Class {
	#name : 'GbsObjectLogFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsObjectLogFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsObjectLogFacade >> browserRows [
	^ self entries collect: [ :each |
		{ each priorityLabel. each displayString. #entry. each } ]
]

{ #category : 'actions' }
GbsObjectLogFacade >> addEntryUsingSelector: aSelector label: aString object: anObject tag: aTag commit: aBoolean [
	| result |
	result := session executeScriptAndFetchObject: (self
		addEntryScriptUsingSelector: aSelector
		label: aString
		object: anObject
		tag: aTag).
	aBoolean == true ifTrue: [ session commitTransactionOrSignalConflict ].
	^ result == true
]

{ #category : 'private' }
GbsObjectLogFacade >> addEntryScriptUsingSelector: aSelector label: aString object: anObject tag: aTag [
	| objectScript |
	objectScript := anObject
		ifNil: [ 'nil' ]
		ifNotNil: [
			(anObject respondsTo: #oop)
				ifTrue: [ '(Object _objectForOop: ', anObject oop printString, ')' ]
				ifFalse: [ session marshalArgumentToScript: anObject ] ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[ | entry object |
	object := ';
			nextPutAll: objectScript;
			nextPutAll: '.
	entry := ObjectLogEntry ';
			nextPutAll: aSelector asString;
			nextPutAll: ': ';
			nextPutAll: (session marshalArgumentToScript: aString);
			nextPutAll: ' object: object.
	'.
		aTag ifNotNil: [
			stream
				nextPutAll: '[ entry tag: ';
				nextPutAll: (session marshalArgumentToScript: aTag);
				nextPutAll: ' ] on: Error do: [ ].
	' ].
		stream
			nextPutAll: 'entry addToLog.
	true ] value' ]
]

{ #category : 'actions' }
GbsObjectLogFacade >> clear [
	^ self clearCommit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> clearCommit: aBoolean [
	| result |
	result := session executeScriptAndFetchObject: '[
		| log |
		log := [ ObjectLogEntry objectLog ] on: Error do: [ nil ].
		log ifNil: [ false ] ifNotNil: [ log removeAll. true ]
	] value'.
	(result == true and: [ aBoolean == true ]) ifTrue: [ session commitTransactionOrSignalConflict ].
	^ result
]

{ #category : 'querying' }
GbsObjectLogFacade >> count [
	^ self entries size
]

{ #category : 'actions' }
GbsObjectLogFacade >> deleteEntry: anEntry [
	anEntry ifNil: [ ^ false ].
	^ self deleteIndex: anEntry index
]

{ #category : 'actions' }
GbsObjectLogFacade >> deleteEntry: anEntry commit: aBoolean [
	anEntry ifNil: [ ^ false ].
	^ self deleteIndex: anEntry index commit: aBoolean
]

{ #category : 'actions' }
GbsObjectLogFacade >> deleteIndex: anInteger [
	^ self deleteIndex: anInteger commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> deleteIndex: anInteger commit: aBoolean [
	| result |
	result := session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: '[
		| log index |
		log := [ ObjectLogEntry objectLog ] on: Error do: [ nil ].
		index := ';
			nextPutAll: anInteger asInteger printString;
			nextPutAll: '.
		(log isNil or: [ index < 1 or: [ index > log size ] ])
			ifTrue: [ false ]
			ifFalse: [ log delete: (log at: index). true ]
	] value' ]).
	(result == true and: [ aBoolean == true ]) ifTrue: [ session commitTransactionOrSignalConflict ].
	^ result
]

{ #category : 'querying' }
GbsObjectLogFacade >> entries [
	| rows |
	rows := session executeScriptAndFetchObject: self entriesScript.
	rows ifNil: [ ^ #() ].
	^ rows collect: [ :each |
		GbsObjectLogEntry
			index: (each at: 1 ifAbsent: [ 0 ])
			priority: (each at: 2 ifAbsent: [ 0 ])
			label: (each at: 3 ifAbsent: [ '' ])
			pid: (each at: 4 ifAbsent: [ nil ])
			timestamp: (each at: 5 ifAbsent: [ nil ])
			tag: (each at: 6 ifAbsent: [ '' ])
			tagged: (each at: 7 ifAbsent: [ false ])
			objectOop: (each at: 8 ifAbsent: [ nil ])
			objectDisplayString: (each at: 9 ifAbsent: [ '' ])
			session: session ]
]

{ #category : 'private' }
GbsObjectLogFacade >> entriesScript [
	^ '[
		| log rows |
		log := [ ObjectLogEntry objectLog ] on: Error do: [ nil ].
		log ifNil: [ ^ #() ].
		rows := OrderedCollection new.
		1 to: log size do: [ :index |
			| entry object objectOop stamp tagValue taggedValue |
			entry := log at: index.
			object := [ entry object ] on: Error do: [ nil ].
			objectOop := object
				ifNil: [ nil ]
				ifNotNil: [ [ Reflection oopOf: object ] on: Error do: [ nil ] ].
			stamp := [ entry stamp printString ] on: Error do: [ [ entry timestamp printString ] on: Error do: [ nil ] ].
			tagValue := [ entry tag ] on: Error do: [ nil ].
			taggedValue := [ entry hasTag ] on: Error do: [ false ].
			rows add: (Array
				with: index
				with: ([ entry priority ] on: Error do: [ nil ])
				with: ([ entry label ] on: Error do: [ '''' ])
				with: ([ entry pid ] on: Error do: [ nil ])
				with: stamp
				with: tagValue
				with: taggedValue
				with: objectOop
				with: (object ifNil: [ nil ] ifNotNil: [ [ object printString ] on: Error do: [ nil ] ])) ].
		rows asArray
	] value'
]

{ #category : 'querying' }
GbsObjectLogFacade >> entriesAtPriority: anInteger [
	^ self entries select: [ :each | each priority = anInteger ]
]

{ #category : 'querying' }
GbsObjectLogFacade >> toA [
	^ self entries
]

{ #category : 'querying' }
GbsObjectLogFacade >> toAry [
	^ self entries
]

{ #category : 'querying' }
GbsObjectLogFacade >> traces [
	^ self entriesAtPriority: 6
]

{ #category : 'querying' }
GbsObjectLogFacade >> debugs [
	^ self entriesAtPriority: 5
]

{ #category : 'querying' }
GbsObjectLogFacade >> infos [
	^ self entriesAtPriority: 4
]

{ #category : 'querying' }
GbsObjectLogFacade >> warns [
	^ self entriesAtPriority: 3
]

{ #category : 'querying' }
GbsObjectLogFacade >> errors [
	^ self entriesAtPriority: 2
]

{ #category : 'querying' }
GbsObjectLogFacade >> fatals [
	^ self entriesAtPriority: 1
]

{ #category : 'actions' }
GbsObjectLogFacade >> trace: aString [
	^ self trace: aString object: nil
]

{ #category : 'actions' }
GbsObjectLogFacade >> trace: aString object: anObject [
	^ self addEntryUsingSelector: 'trace' label: aString object: anObject tag: nil commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> debug: aString [
	^ self debug: aString object: nil
]

{ #category : 'actions' }
GbsObjectLogFacade >> debug: aString object: anObject [
	^ self addEntryUsingSelector: 'debug' label: aString object: anObject tag: nil commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> info: aString [
	^ self info: aString object: nil
]

{ #category : 'actions' }
GbsObjectLogFacade >> info: aString object: anObject [
	^ self addEntryUsingSelector: 'info' label: aString object: anObject tag: nil commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> info: aString object: anObject tag: aTag [
	^ self addEntryUsingSelector: 'info' label: aString object: anObject tag: aTag commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> warn: aString [
	^ self warn: aString object: nil
]

{ #category : 'actions' }
GbsObjectLogFacade >> warn: aString object: anObject [
	^ self addEntryUsingSelector: 'warn' label: aString object: anObject tag: nil commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> error: aString [
	^ self error: aString object: nil
]

{ #category : 'actions' }
GbsObjectLogFacade >> error: aString object: anObject [
	^ self addEntryUsingSelector: 'error' label: aString object: anObject tag: nil commit: true
]

{ #category : 'actions' }
GbsObjectLogFacade >> fatal: aString [
	^ self fatal: aString object: nil
]

{ #category : 'actions' }
GbsObjectLogFacade >> fatal: aString object: anObject [
	^ self addEntryUsingSelector: 'fatal' label: aString object: anObject tag: nil commit: true
]

{ #category : 'querying' }
GbsObjectLogFacade >> isEmpty [
	^ self entries isEmpty
]

{ #category : 'printing' }
GbsObjectLogFacade >> previewForBrowserRow: aRow [
	| entry |
	aRow ifNil: [ ^ { #rawPrintString -> self reportText } asDictionary ].
	entry := aRow at: 4 ifAbsent: [ nil ].
	entry ifNil: [ ^ { #rawPrintString -> self reportText } asDictionary ].
	^ { #rawPrintString -> entry detailText } asDictionary
]

{ #category : 'printing' }
GbsObjectLogFacade >> reportText [
	| entries |
	entries := self entries.
	entries isEmpty ifTrue: [ ^ 'ObjectLog', String cr, String cr, '(empty)' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'ObjectLog'; cr; cr.
		entries do: [ :each |
			stream nextPutAll: each displayString; cr ] ]
]

{ #category : 'accessing' }
GbsObjectLogFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsObjectLogFacade >> session: aSession [
	session := aSession
]
