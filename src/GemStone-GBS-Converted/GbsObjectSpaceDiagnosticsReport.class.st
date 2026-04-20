Class {
	#name : 'GbsObjectSpaceDiagnosticsReport',
	#superclass : 'Object',
	#instVars : [
		'diagnostics',
		'slots'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectSpaceDiagnosticsReport class >> diagnostics: aDiagnosticsFacade slots: aCollection [
	^ self new
		diagnostics: aDiagnosticsFacade;
		slots: aCollection;
		yourself
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsReport >> appendOn: aStream [
	self sections
		doWithIndex: [ :each :index |
			index > 1 ifTrue: [ aStream cr ].
			each appendOn: aStream ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsReport >> customSlots [
	| known |
	known := diagnostics wellKnownSessionStateKeys asSet.
	^ self slots select: [ :each | (known includes: each key) not ]
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsReport >> diagnostics [
	^ diagnostics
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsReport >> diagnostics: aDiagnosticsFacade [
	diagnostics := aDiagnosticsFacade
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsReport >> sections [
	| sections |
	sections := OrderedCollection new.
	self wellKnownSlots ifNotEmpty: [ :known |
		sections add:
			(GbsReportSection
				title: 'Well-Known Session State'
				items: known
				lineBlock: [ :each | each summaryLine ]) ].
	self customSlots ifNotEmpty: [ :custom |
		sections add:
			(GbsReportSection
				title: 'Custom Session State'
				items: custom
				lineBlock: [ :each | each summaryLine ]) ].
	sections isEmpty ifTrue: [
		sections add:
			(GbsReportSection
				title: 'Session State'
				items: #()
				lineBlock: [ :each | each summaryLine ]) ].
	^ sections asArray
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsReport >> slots [
	^ slots ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsReport >> slots: aCollection [
	slots := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsReport >> text [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Session State'; cr; cr.
		self appendOn: stream ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsReport >> wellKnownSlots [
	| known |
	known := diagnostics wellKnownSessionStateKeys asSet.
	^ self slots select: [ :each | known includes: each key ]
]
