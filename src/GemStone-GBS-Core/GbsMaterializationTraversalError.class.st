Class {
	#name : 'GbsMaterializationTraversalError',
	#superclass : 'Error',
	#instVars : [
		'errorKind',
		'contextLabel',
		'observedValue'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'signaling' }
GbsMaterializationTraversalError class >> signalKind: kindSymbol label: labelString message: messageString [
	^ self new
		errorKind: kindSymbol;
		contextLabel: labelString;
		signal: messageString
]

{ #category : 'signaling' }
GbsMaterializationTraversalError class >> signalKind: kindSymbol label: labelString observed: observedObject message: messageString [
	^ self new
		errorKind: kindSymbol;
		contextLabel: labelString;
		observedValue: observedObject;
		signal: messageString
]

{ #category : 'accessing' }
GbsMaterializationTraversalError >> contextLabel [
	^ contextLabel
]

{ #category : 'accessing' }
GbsMaterializationTraversalError >> contextLabel: aString [
	contextLabel := aString
]

{ #category : 'accessing' }
GbsMaterializationTraversalError >> errorKind [
	^ errorKind
]

{ #category : 'accessing' }
GbsMaterializationTraversalError >> errorKind: aSymbol [
	errorKind := aSymbol
]

{ #category : 'accessing' }
GbsMaterializationTraversalError >> observedValue [
	^ observedValue
]

{ #category : 'accessing' }
GbsMaterializationTraversalError >> observedValue: anObject [
	observedValue := anObject
]
