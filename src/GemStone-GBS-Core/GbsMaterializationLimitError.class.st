Class {
	#name : 'GbsMaterializationLimitError',
	#superclass : 'Error',
	#instVars : [
		'limitKind',
		'observedValue',
		'limitValue',
		'contextLabel'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'signaling' }
GbsMaterializationLimitError class >> signalKind: kindSymbol observed: observedInteger limit: limitInteger label: labelString [
	^ self new
		limitKind: kindSymbol;
		observedValue: observedInteger;
		limitValue: limitInteger;
		contextLabel: labelString;
		signal: (self
			messageForKind: kindSymbol
			observed: observedInteger
			limit: limitInteger
			label: labelString)
]

{ #category : 'signaling' }
GbsMaterializationLimitError class >> messageForKind: kindSymbol observed: observedInteger limit: limitInteger label: labelString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Materialization ';
			nextPutAll: kindSymbol asString;
			nextPutAll: ' limit exceeded'.
		labelString ifNotNil: [
			labelString asString isEmpty ifFalse: [
				stream
					nextPutAll: ' for ';
					nextPutAll: labelString asString ] ].
		stream
			nextPutAll: ': observed=';
			nextPutAll: observedInteger asString;
			nextPutAll: ', limit=';
			nextPutAll: limitInteger asString ]
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> contextLabel [
	^ contextLabel
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> contextLabel: aString [
	contextLabel := aString
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> limitKind [
	^ limitKind
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> limitKind: aSymbol [
	limitKind := aSymbol
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> limitValue [
	^ limitValue
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> limitValue: anInteger [
	limitValue := anInteger
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> observedValue [
	^ observedValue
]

{ #category : 'accessing' }
GbsMaterializationLimitError >> observedValue: anInteger [
	observedValue := anInteger
]
