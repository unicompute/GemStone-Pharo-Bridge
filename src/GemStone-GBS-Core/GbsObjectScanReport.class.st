Class {
	#name : 'GbsObjectScanReport',
	#superclass : 'Object',
	#instVars : [
		'diagnostics',
		'title',
		'objects'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsObjectScanReport class >> diagnostics: aDiagnosticsFacade title: aString objects: aCollection [
	^ self new
		diagnostics: aDiagnosticsFacade;
		title: aString;
		objects: aCollection;
		yourself
]

{ #category : 'printing' }
GbsObjectScanReport >> appendOn: aStream [
	self section appendOn: aStream
]

{ #category : 'accessing' }
GbsObjectScanReport >> diagnostics [
	^ diagnostics
]

{ #category : 'accessing' }
GbsObjectScanReport >> diagnostics: aDiagnosticsFacade [
	diagnostics := aDiagnosticsFacade
]

{ #category : 'accessing' }
GbsObjectScanReport >> objects [
	^ objects ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsObjectScanReport >> objects: aCollection [
	objects := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'querying' }
GbsObjectScanReport >> section [
	^ GbsReportSection
		title: self title
		items: self objects
		lineBlock: [ :each |
			diagnostics
				summaryLineFor: each
				label: 'Object' ]
]

{ #category : 'printing' }
GbsObjectScanReport >> text [
	^ String streamContents: [ :stream |
		self appendOn: stream ]
]

{ #category : 'accessing' }
GbsObjectScanReport >> title [
	^ title ifNil: [ 'Object Scan' ]
]

{ #category : 'accessing' }
GbsObjectScanReport >> title: aString [
	title := aString ifNil: [ 'Object Scan' ] ifNotNil: [ aString asString ]
]
