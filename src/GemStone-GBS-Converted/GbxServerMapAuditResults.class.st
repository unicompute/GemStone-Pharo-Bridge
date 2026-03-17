Class {
	#name : #'GbxServerMapAuditResults',
	#superclass : #'Object',
	#instVars : [ #'map' #'failures' #'numUsedElements' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'assertions' }
GbxServerMapAuditResults >> assert: aBoolean node: aNode description: description actual: actual expected: expected
	"Actual should be the actual object, not a string describing it."

	aBoolean
		ifFalse: 
			[self addFailure: (GbxServerMapAuditFailure node: aNode
						description: (self gbsMessenger
								print: description
								with: actual gbxDebugPrintString
								with: expected))]

{ #category : #'accessing' }
GbxServerMapAuditResults >> addUsedElements: anInteger

	numUsedElements := numUsedElements + anInteger

{ #category : #'accessing' }
GbxServerMapAuditResults >> map
	^map

{ #category : #'accessing' }
GbxServerMapAuditResults >> addFailure: aFailure

	failures add: aFailure

{ #category : #'accessing' }
GbxServerMapAuditResults >> numUsedElements: anObject
	numUsedElements := anObject

{ #category : #'accessing' }
GbxServerMapAuditResults >> numUsedElements
	^numUsedElements

{ #category : #'accessing' }
GbxServerMapAuditResults >> map: anObject
	map := anObject

{ #category : #'verifying' }
GbxServerMapAuditResults >> verify
	"Check results. If there are any inconsistencies, raise an error."

	| reportStream |
	failures isEmpty ifTrue: [^self].

	reportStream := WriteStream on: String new.
	reportStream nextPutAll: 'Server Map audit failures:'.
	failures doWithIndex: 
			[:each :index |
			reportStream cr; print: index; tab.
			each printDescriptionOn: reportStream].

	self gbsMessenger
		comment: reportStream contents;
		error: 'Audit failed with %1 failures (see above or Transcript).'
			with: failures size.

{ #category : #'initialize-release' }
GbxServerMapAuditResults >> initialize

	failures := OrderedCollection new.
	numUsedElements := 0

{ #category : #'instance creation' }
GbxServerMapAuditResults class >> new

	^super new initialize

