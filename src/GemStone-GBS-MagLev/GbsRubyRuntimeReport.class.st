Class {
	#name : 'GbsRubyRuntimeReport',
	#superclass : 'Object',
	#instVars : [
		'session',
		'namespace',
		'selectedConstant',
		'selectedAutoload'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyRuntimeReport class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'printing' }
GbsRubyRuntimeReport >> appendOn: aStream [
	self sections
		doWithIndex: [ :each :index |
			index > 1 ifTrue: [ aStream cr ].
			each appendOn: aStream ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> autoloadRegistrations [
	namespace ifNil: [ ^ #() ].
	^ [ namespace autoloadMirrors ]
		on: Exception
		do: [ :ex | #() ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> autoloadRegistrationEntries [
	^ self autoloadRegistrations collect: [ :each |
		GbsRubyAutoloadRegistrationEntry on: each ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> provenanceGraph [
	^ GbsRubyRuntimeProvenanceGraph
		links: self provenanceLinks
		actions: self provenanceActions
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> provenanceLinks [
	^ Array streamContents: [ :stream |
		self loadPathEntries do: [ :each | stream nextPutAll: each provenanceLinks ].
		self loadedFeatureEntries do: [ :each | stream nextPutAll: each provenanceLinks ].
		self persistentLoadedFeatureEntries do: [ :each | stream nextPutAll: each provenanceLinks ].
		self autoloadRegistrationEntries do: [ :each | stream nextPutAll: each provenanceLinks ] ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> provenanceActions [
	| runtimeFacade |
	runtimeFacade := session
		ifNil: [ nil ]
		ifNotNil: [ session rubyRuntime ].
	^ Array streamContents: [ :stream |
		self loadedFeatureEntries do: [ :each | stream nextPutAll: (each provenanceActionsUsing: runtimeFacade) ].
		self persistentLoadedFeatureEntries do: [ :each | stream nextPutAll: (each provenanceActionsUsing: runtimeFacade) ].
		self autoloadRegistrationEntries do: [ :each | stream nextPutAll: (each provenanceActionsUsing: runtimeFacade) ] ]
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> namespace [
	^ namespace
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> namespace: aNamespaceMirror [
	namespace := aNamespaceMirror
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> loadPathEntries [
	^ (session rubyLoadPath ifNil: [ #() ]) collect: [ :each |
		GbsRubyLoadPathEntry path: each ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> loadPathSection [
	^ GbsReportSection
		title: '$LOAD_PATH'
		items: self loadPathEntries
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> loadedFeatureEntries [
	^ (session rubyLoadedFeatures ifNil: [ #() ]) collect: [ :each |
		GbsRubyLoadedFeatureEntry feature: each ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> loadedFeaturesSection [
	^ GbsReportSection
		title: 'Loaded Features'
		items: self loadedFeatureEntries
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> persistentLoadedFeatureEntries [
	^ (session rubyPersistentLoadedFeatures ifNil: [ #() ]) collect: [ :each |
		GbsRubyLoadedFeatureEntry
			feature: each
			persistent: true ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> persistentLoadedFeaturesSection [
	^ GbsReportSection
		title: 'Persistent Loaded Features'
		items: self persistentLoadedFeatureEntries
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> selectedAutoload [
	^ selectedAutoload
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> selectedAutoload: anAutoloadMirror [
	selectedAutoload := anAutoloadMirror
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> selectedConstant [
	^ selectedConstant
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> selectedConstant: aConstantMirror [
	selectedConstant := aConstantMirror
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> session [
	^ session
]

{ #category : 'accessing' }
GbsRubyRuntimeReport >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> sessionStateSlots [
	^ session objectSpaceDiagnostics wellKnownSessionStateSlots
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> sessionStateSection [
	^ GbsReportSection
		title: 'Session State'
		items: self sessionStateSlots
		lineBlock: [ :each | each summaryLine ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> sections [
	| sections |
	sections := OrderedCollection new.
	self selectedDetailsSection ifNotNil: [ :section |
		section isEmpty ifFalse: [ sections add: section ] ].
	self autoloadRegistrationsSection ifNotNil: [ :section |
		section isEmpty ifFalse: [ sections add: section ] ].
	sections
		add: self loadPathSection;
		add: self loadedFeaturesSection;
		add: self persistentLoadedFeaturesSection;
		add: self sessionStateSection.
	^ sections asArray
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> selectedDetailsLines [
	| lines |
	lines := OrderedCollection new.
	selectedAutoload ifNotNil: [
		lines
			add: 'Selected Autoload: ', selectedAutoload name asString;
			add: 'Autoload State: ', selectedAutoload stateLabel asString.
		selectedAutoload autoloadFile ifNotNil: [
			lines add: 'Autoload File: ', selectedAutoload autoloadFile asString ].
		selectedAutoload targetDisplayName ifNotNil: [
			lines add: 'Autoload Target: ', selectedAutoload targetDisplayName asString ].
		selectedAutoload valueClassName ifNotNil: [
			lines add: 'Autoload Value Class: ', selectedAutoload valueClassName asString ] ].
	selectedConstant ifNotNil: [
		lines
			add: 'Selected Constant: ', selectedConstant name asString;
			add: 'Target: ', (selectedConstant targetDisplayName ifNil: [ 'n/a' ]) asString.
		selectedConstant valueClassName ifNotNil: [
			lines add: 'Value Class: ', selectedConstant valueClassName asString ].
		selectedConstant autoloadFile ifNotNil: [
			lines add: 'Autoload File: ', selectedConstant autoloadFile asString ] ].
	^ lines asArray
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> selectedDetailsSection [
	^ GbsReportSection
		title: 'Selection'
		items: self selectedDetailsLines
		lineBlock: [ :each | each ]
]

{ #category : 'printing' }
GbsRubyRuntimeReport >> text [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Ruby Runtime'; cr; cr.
		self appendOn: stream ]
]

{ #category : 'querying' }
GbsRubyRuntimeReport >> autoloadRegistrationsSection [
	^ GbsReportSection
		title: 'Autoload Registrations'
		items: self autoloadRegistrationEntries
		lineBlock: [ :each | each displayString ]
]
