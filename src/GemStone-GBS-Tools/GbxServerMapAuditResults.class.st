Class {
	#name : 'GbxServerMapAuditResults',
	#superclass : 'Object',
	#instVars : [
		'errors',
		'warnings',
		'auditTime',
		'nodesAudited'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxServerMapAuditResults class >> new [
	^ super new
		errors: OrderedCollection new;
		warnings: OrderedCollection new;
		auditTime: DateAndTime now;
		nodesAudited: 0;
		yourself
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> addError: aString [
	errors add: aString.
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> addWarning: aString [
	warnings add: aString.
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> auditTime [
	^ auditTime
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> auditTime: aDateAndTime [
	auditTime := aDateAndTime
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> errors [
	^ errors
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> errors: aCollection [
	errors := aCollection
]

{ #category : 'testing' }
GbxServerMapAuditResults >> hasErrors [
	^ errors isEmpty not
]

{ #category : 'testing' }
GbxServerMapAuditResults >> hasWarnings [
	^ warnings isEmpty not
]

{ #category : 'testing' }
GbxServerMapAuditResults >> isSuccess [
	^ errors isEmpty
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> nodesAudited [
	^ nodesAudited
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> nodesAudited: anInteger [
	nodesAudited := anInteger
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> printString [
	^ 'Audit Results: ', errors size asString, ' errors, ',
	  warnings size asString, ' warnings, ',
	  nodesAudited asString, ' nodes audited'
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> summary [
	"Return a summary string of audit results"
	| stream |
	
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Server Map Audit Results'; cr;
		nextPutAll: '========================'; cr;
		nextPutAll: 'Time: ', auditTime asString; cr;
		nextPutAll: 'Nodes Audited: ', nodesAudited asString; cr;
		nextPutAll: 'Errors: ', errors size asString; cr;
		nextPutAll: 'Warnings: ', warnings size asString; cr.
	
	errors isEmpty ifFalse: [
		stream cr; nextPutAll: 'Errors:'; cr.
		errors do: [ :err |
			stream tab; nextPutAll: err; cr.
		].
	].
	
	warnings isEmpty ifFalse: [
		stream cr; nextPutAll: 'Warnings:'; cr.
		warnings do: [ :warn |
			stream tab; nextPutAll: warn; cr.
		].
	].
	
	^ stream contents
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> warnings [
	^ warnings
]

{ #category : 'accessing' }
GbxServerMapAuditResults >> warnings: aCollection [
	warnings := aCollection
]
