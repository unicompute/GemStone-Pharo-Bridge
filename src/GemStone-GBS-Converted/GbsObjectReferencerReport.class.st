Class {
	#name : 'GbsObjectReferencerReport',
	#superclass : 'Object',
	#instVars : [
		'diagnostics',
		'targetLabel',
		'targetOop',
		'referencers'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectReferencerReport class >> diagnostics: aDiagnosticsFacade targetLabel: aString targetOop: anOop referencers: aCollection [
	^ self new
		diagnostics: aDiagnosticsFacade;
		targetLabel: aString;
		targetOop: anOop;
		referencers: aCollection;
		yourself
]

{ #category : 'printing' }
GbsObjectReferencerReport >> appendOn: aStream [
	self section appendOn: aStream
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> diagnostics [
	^ diagnostics
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> diagnostics: aDiagnosticsFacade [
	diagnostics := aDiagnosticsFacade
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> referencers [
	^ referencers ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> referencers: aCollection [
	referencers := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'querying' }
GbsObjectReferencerReport >> section [
	^ GbsReportSection
		title: self title
		items: self referencers
		lineBlock: [ :each |
			diagnostics
				summaryLineFor: each
				label: 'Referencer' ]
]

{ #category : 'printing' }
GbsObjectReferencerReport >> text [
	^ String streamContents: [ :stream |
		self appendOn: stream ]
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> targetLabel [
	^ targetLabel ifNil: [ 'Object' ]
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> targetLabel: aString [
	targetLabel := aString ifNil: [ 'Object' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> targetOop [
	^ targetOop
]

{ #category : 'accessing' }
GbsObjectReferencerReport >> targetOop: anOop [
	targetOop := anOop
]

{ #category : 'querying' }
GbsObjectReferencerReport >> title [
	^ String streamContents: [ :stream |
		stream nextPutAll: self targetLabel.
		targetOop ifNotNil: [
			stream
				nextPutAll: ' oop=';
				nextPutAll: targetOop asString ].
		stream nextPutAll: ' Referencers' ]
]
