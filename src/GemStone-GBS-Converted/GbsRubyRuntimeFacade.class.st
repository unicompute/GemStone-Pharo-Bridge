Class {
	#name : 'GbsRubyRuntimeFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsRubyRuntimeFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> appendRuntimeReportOn: aStream namespace: aNamespaceMirror selectedConstant: aConstantMirror selectedAutoload: anAutoloadMirror [
	self
		writeSelectedAutoload: anAutoloadMirror
		selectedConstant: aConstantMirror
		on: aStream.
	self
		writeAutoloadRegistrationsFor: aNamespaceMirror
		on: aStream.
	self writeCollection: self loadPath label: '$LOAD_PATH' on: aStream.
	aStream cr.
	self writeCollection: self loadedFeatures label: 'Loaded Features' on: aStream.
	aStream cr.
	self writeCollection: self persistentLoadedFeatures label: 'Persistent Loaded Features' on: aStream.
	aStream cr; nextPutAll: 'Session State'; cr.
	self objectSpaceDiagnostics sessionStateSummaryLines do: [ :each |
		aStream nextPutAll: each; cr ]
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> clearPersistentLoadedFeatures [
	^ session clearPersistentRubyLoadedFeatures
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadPath [
	^ session rubyLoadPath ifNil: [ #() ]
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> loadFileNamed: aString [
	^ session rubyLoadFileNamed: aString
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadedFeatures [
	^ session rubyLoadedFeatures ifNil: [ #() ]
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> objectSpaceDiagnostics [
	^ session objectSpaceDiagnostics
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> persistentLoadedFeatures [
	^ session rubyPersistentLoadedFeatures ifNil: [ #() ]
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> requireFileNamed: aString [
	^ session rubyRequireFileNamed: aString
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> reportText [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Ruby Runtime'; cr; cr.
		self
			appendRuntimeReportOn: stream
			namespace: nil
			selectedConstant: nil
			selectedAutoload: nil ]
]

{ #category : 'accessing' }
GbsRubyRuntimeFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsRubyRuntimeFacade >> session: aSession [
	session := aSession
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> writeAutoloadRegistrationsFor: aNamespaceMirror on: aStream [
	| autoloads |
	aNamespaceMirror ifNil: [ ^ self ].
	autoloads := [ aNamespaceMirror autoloadMirrors ]
		on: Error
		do: [ :ex | #() ].
	autoloads ifEmpty: [ ^ self ].
	aStream nextPutAll: 'Autoload Registrations'; cr.
	autoloads do: [ :each |
		aStream
			nextPutAll: each name asString;
			nextPutAll: ' -> ';
			nextPutAll: (each autoloadFile ifNil: [ '(none)' ]) asString;
			nextPutAll: ' [';
			nextPutAll: each stateLabel asString;
			nextPut: $];
			cr ].
	aStream cr
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> writeCollection: aCollection label: aLabel on: aStream [
	aStream nextPutAll: aLabel; cr.
	aCollection
		ifEmpty: [ aStream nextPutAll: '(empty)'; cr ]
		ifNotEmpty: [
			aCollection do: [ :each |
				aStream nextPutAll: each asString; cr ] ]
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> writeSelectedAutoload: anAutoloadMirror selectedConstant: aConstantMirror on: aStream [
	anAutoloadMirror ifNotNil: [
		aStream
			nextPutAll: 'Selected Autoload: ';
			nextPutAll: anAutoloadMirror name asString;
			cr;
			nextPutAll: 'Autoload State: ';
			nextPutAll: anAutoloadMirror stateLabel asString;
			cr.
		anAutoloadMirror autoloadFile ifNotNil: [
			aStream
				nextPutAll: 'Autoload File: ';
				nextPutAll: anAutoloadMirror autoloadFile asString;
				cr ].
		anAutoloadMirror targetDisplayName ifNotNil: [
			aStream
				nextPutAll: 'Autoload Target: ';
				nextPutAll: anAutoloadMirror targetDisplayName asString;
				cr ].
		anAutoloadMirror valueClassName ifNotNil: [
			aStream
				nextPutAll: 'Autoload Value Class: ';
				nextPutAll: anAutoloadMirror valueClassName asString;
				cr ].
		aStream cr ].
	aConstantMirror ifNotNil: [
		aStream
			nextPutAll: 'Selected Constant: ';
			nextPutAll: aConstantMirror name asString;
			cr;
			nextPutAll: 'Target: ';
			nextPutAll: (aConstantMirror targetDisplayName ifNil: [ 'n/a' ]) asString;
			cr.
		aConstantMirror valueClassName ifNotNil: [
			aStream
				nextPutAll: 'Value Class: ';
				nextPutAll: aConstantMirror valueClassName asString;
				cr ].
		aConstantMirror autoloadFile ifNotNil: [
			aStream
				nextPutAll: 'Autoload File: ';
				nextPutAll: aConstantMirror autoloadFile asString;
				cr ].
		aStream cr ]
]
