Class {
	#name : 'MockGbsSession',
	#superclass : 'GbsSession',
	#instVars : [
		'stubs'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
MockGbsSession >> apiGciExecute: aString context: anInteger [
	"Intercept the actual FFI call used by execute:"
	| errBlock |
	errBlock := self stubs at: #executeError ifAbsent: [ nil ].
	errBlock ifNotNil: [ errBlock value ].
	^ self stubs at: #apiGciExecute ifAbsent: [ 268 ] "268 = true in GS64"
]

{ #category : 'execution' }
MockGbsSession >> evaluate: aString [
	^ self stubs at: #evaluate ifAbsent: [ '' ]
]

{ #category : 'accessing' }
MockGbsSession >> gciAbort [
	^ self stubs at: #gciAbort ifAbsent: [ 1 ]
]

{ #category : 'accessing' }
MockGbsSession >> gciCommit [
	^ self stubs at: #gciCommit ifAbsent: [ 1 ]
]

{ #category : 'accessing' }
MockGbsSession >> gciErr: errorStruct [
	| block |
	block := self stubs at: #gciErr ifAbsent: [ nil ].
	block ifNotNil: [ block value: errorStruct. ^ true ].
	^ false
]

{ #category : 'accessing' }
MockGbsSession >> gciInit [
	^ self stubs at: #gciInit ifAbsent: [ true ]
]

{ #category : 'accessing' }
MockGbsSession >> gciLoginStone: s hostUser: hu hostPass: hp gsUser: gu gsPass: gp [
	^ self stubs at: #gciLogin ifAbsent: [ true ]
]

{ #category : 'accessing' }
MockGbsSession >> gciLogout [
	^ self stubs at: #gciLogout ifAbsent: [ 1 ]
]

{ #category : 'accessing' }
MockGbsSession >> gciPollForSignal [
	^ self stubs at: #gciPollForSignal ifAbsent: [ 0 ]
]

{ #category : 'execution' }
MockGbsSession >> serverInterface [
	"Return self so this mock can also intercept serverInterface calls!"
	^ self
]

{ #category : 'accessing' }
MockGbsSession >> stubs [
	^ stubs ifNil: [ stubs := Dictionary new ]
]
