Class {
	#name : 'GbxClassVersionBrowser',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'selectedClass',
		'versionList',
		'sourceText',
		'migrateButton',
		'inspectInstancesButton',
		'closeButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxClassVersionBrowser class >> openOn: aClassHolder session: aSession [
	"Open the class version browser on a class"
	| browser |
	
	browser := self new.
	browser session: aSession.
	browser selectedClass: aClassHolder.
	browser open.
	^ browser
]

{ #category : 'layout' }
GbxClassVersionBrowser >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (SpBoxLayout newHorizontal
			add: migrateButton width: 150;
			add: inspectInstancesButton width: 150;
			add: closeButton width: 100;
			yourself) height: 35;
		add: versionList;
		add: sourceText;
		yourself
]

{ #category : 'initialization' }
GbxClassVersionBrowser >> initializePresenters [
	migrateButton := self newButton
		label: 'Migrate Instances';
		action: [ self migrateInstances ].
	
	inspectInstancesButton := self newButton
		label: 'Inspect Instances';
		action: [ self inspectInstances ].
	
	closeButton := self newButton
		label: 'Close';
		action: [ self delete ].
	
	versionList := self newList.
	versionList
		addColumn: (SpStringTableColumn title: 'Version' evaluated: [ :item | item at: 1 ]);
		addColumn: (SpStringTableColumn title: 'Instance Count' evaluated: [ :item | item at: 2 ]);
		whenActivatedDo: [ :selection | self showVersion: selection selectedItem ].
	
	sourceText := self newText.
	sourceText beReadOnly.
]

{ #category : 'initialization' }
GbxClassVersionBrowser >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Class Version Browser';
		initialExtent: 700 @ 600.
]

{ #category : 'actions' }
GbxClassVersionBrowser >> inspectInstances [
	"Inspect instances of the selected class version"
	| script result |
	
	selectedClass ifNil: [ ^ self ].
	session ifNil: [ ^ self ].
	
	script := '[
		| cls instances |
		cls := Object _objectForOop: ', selectedClass proxy oop asString, '.
		instances := cls allInstances.
		instances
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		GbsInspector inspect: result session: session.
	].
]

{ #category : 'actions' }
GbxClassVersionBrowser >> migrateInstances [
	"Migrate instances from old class version to new"
	| script |
	
	selectedClass ifNil: [ ^ self ].
	session ifNil: [ ^ self ].
	
	(ConfirmDialog confirm: 'Migrate all instances to this class version?') ifFalse: [ ^ self ].
	
	script := '[
		| cls |
		cls := Object _objectForOop: ', selectedClass proxy oop asString, '.
		System commit.
		cls migrateInstancesWithSubclasses
	] value'.
	
	session execute: script.
	
	InformDialog inform: 'Migration complete!'.
	self refreshVersions.
]

{ #category : 'fetching' }
GbxClassVersionBrowser >> fetchVersions [
	"Fetch class versions from GemStone"
	| script result |
	
	selectedClass ifNil: [ ^ #() ].
	session ifNil: [ ^ #() ].
	
	script := '[
		| cls versions stream |
		cls := Object _objectForOop: ', selectedClass proxy oop asString, '.
		versions := cls classHistory.
		stream := WriteStream on: String new.
		versions do: [ :ver |
			stream
				nextPutAll: ver name asString; nextPutAll: ''|'';
				nextPutAll: ver instanceCount asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	^ self parseVersions: result
]

{ #category : 'fetching' }
GbxClassVersionBrowser >> parseVersions: aString [
	"Parse versions string into array"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: $|.
			parts size >= 2 ifTrue: [
				items add: { parts first. parts second }.
			]
		]
	].
	^ items asArray
]

{ #category : 'actions' }
GbxClassVersionBrowser >> refreshVersions [
	"Refresh the version list"
	| versions |
	
	versions := self fetchVersions.
	versionList items: versions.
	versionList selectIndex: 1.
	versionList selectedItem ifNotNil: [ :item |
		self showVersion: item.
	].
]

{ #category : 'accessing' }
GbxClassVersionBrowser >> selectedClass [
	^ selectedClass
]

{ #category : 'accessing' }
GbxClassVersionBrowser >> selectedClass: aClassHolder [
	selectedClass := aClassHolder.
	self window ifNotNil: [ :win |
		win title: 'Class Version Browser - ', aClassHolder name.
	].
	self refreshVersions.
]

{ #category : 'accessing' }
GbxClassVersionBrowser >> session [
	^ session
]

{ #category : 'accessing' }
GbxClassVersionBrowser >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbxClassVersionBrowser >> showVersion: versionInfo [
	"Show source code for a version"
	| script source |
	
	versionInfo ifNil: [ ^ self ].
	selectedClass ifNil: [ ^ self ].
	session ifNil: [ ^ self ].
	
	script := '[
		| cls |
		cls := Object _objectForOop: ', selectedClass proxy oop asString, '.
		cls source
	] value'.
	
	source := session executeAndFetch: script.
	sourceText text: (source ifNil: [ '' ] ifNotNil: [ source ]).
]
