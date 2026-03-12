Class {
	#name : 'GbsNamespacesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'namespacesTable',
		'refreshButton',
		'closeButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsNamespacesPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	presenter := self new.
	presenter
		session: aSession;
		open.
	^ presenter
]

{ #category : 'layout' }
GbsNamespacesPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: namespacesTable;
		add: (SpBoxLayout newLeftToRight
			add: refreshButton;
			add: closeButton;
			spacing: 8;
			yourself) expand: false;
		yourself
]

{ #category : 'initialization' }
GbsNamespacesPresenter >> connectPresenters [
	refreshButton action: [ self refreshNamespaces ].
	closeButton action: [ self closeWindow ].
	self refreshNamespaces
]

{ #category : 'initialization' }
GbsNamespacesPresenter >> initializePresenters [
	namespacesTable := self newTable.
	namespacesTable
		addColumn: (SpStringTableColumn title: 'Index' evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Namespace' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Class' evaluated: [ :row | row at: 3 ifAbsent: [ '' ] ]);
		yourself.
	refreshButton := self newButton
		label: 'Refresh';
		icon: (self iconNamed: #smallUpdate);
		yourself.
	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		yourself
]

{ #category : 'initialization' }
GbsNamespacesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Namespaces';
		initialExtent: 760 @ 460
]

{ #category : 'private' }
GbsNamespacesPresenter >> parseRows: rawString [
	| lines |
	(rawString isString and: [ rawString isNotEmpty ]) ifFalse: [ ^ #() ].
	lines := rawString lines.
	^ lines collect: [ :line |
		| columns |
		columns := line splitOn: Character tab.
		{ (columns at: 1 ifAbsent: [ '' ]).
		  (columns at: 2 ifAbsent: [ '' ]).
		  (columns at: 3 ifAbsent: [ '' ]) } ]
]

{ #category : 'actions' }
GbsNamespacesPresenter >> refreshNamespaces [
	| raw rows |
	(self isSessionUsable not) ifTrue: [
		namespacesTable items: #().
		^ self
	].
	raw := [ session evaluate: self namespacesScript ] on: Error do: [ :ex | self inform: 'Fetch namespaces failed: ', ex messageText. '' ].
	rows := self parseRows: raw.
	namespacesTable items: rows
]

{ #category : 'private' }
GbsNamespacesPresenter >> namespacesScript [
	^ '
	| sl strm |
	strm := WriteStream on: String new.
	sl := System myUserProfile symbolList.
	1 to: sl size do: [ :index |
		| ns nsName nsClass |
		ns := sl at: index.
		nsName := (ns respondsTo: #name)
			ifTrue: [ ns name ]
			ifFalse: [ ns printString ].
		nsClass := ns class name asString.
		strm
			nextPutAll: index asString;
			tab;
			nextPutAll: nsName asString;
			tab;
			nextPutAll: nsClass;
			cr ].
	strm contents'
]

{ #category : 'private' }
GbsNamespacesPresenter >> session: aSession [
	session := aSession
]

{ #category : 'private' }
GbsNamespacesPresenter >> isSessionUsable [
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ session isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : 'private' }
GbsNamespacesPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
