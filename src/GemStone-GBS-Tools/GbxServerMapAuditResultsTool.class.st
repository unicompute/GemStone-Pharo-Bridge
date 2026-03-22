Class {
	#name : 'GbxServerMapAuditResultsTool',
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
GbxServerMapAuditResultsTool class >> new [
	^ super new
		errors: OrderedCollection new;
		warnings: OrderedCollection new;
		auditTime: DateAndTime now;
		nodesAudited: 0;
		yourself
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> addError: aString [
	errors add: aString.
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> addWarning: aString [
	warnings add: aString.
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> auditTime [
	^ auditTime
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> auditTime: aDateAndTime [
	auditTime := aDateAndTime
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> errors [
	^ errors
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> errors: aCollection [
	errors := aCollection
]

{ #category : 'testing' }
GbxServerMapAuditResultsTool >> hasErrors [
	^ errors isEmpty not
]

{ #category : 'testing' }
GbxServerMapAuditResultsTool >> hasWarnings [
	^ warnings isEmpty not
]

{ #category : 'testing' }
GbxServerMapAuditResultsTool >> isSuccess [
	^ errors isEmpty
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> nodesAudited [
	^ nodesAudited
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> nodesAudited: anInteger [
	nodesAudited := anInteger
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> printString [
	^ 'Audit Results: ', errors size asString, ' errors, ',
	  warnings size asString, ' warnings, ',
	  nodesAudited asString, ' nodes audited'
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> summary [
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
GbxServerMapAuditResultsTool >> warnings [
	^ warnings
]

{ #category : 'accessing' }
GbxServerMapAuditResultsTool >> warnings: aCollection [
	warnings := aCollection
]
