Class {
	#name : 'MockGbsSession',
	#superclass : 'GbsSession',
	#instVars : [
		'stubs'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
MockGbsSession >> initialize [
	super initialize.
	isLoggedIn := true
]

{ #category : 'initialization' }
MockGbsSession >> loginStone: stoneName user: username password: password [
	| initSuccess loginSuccess errorStruct |
	initSuccess := self gciInit.
	initSuccess ifFalse: [ ^ GbsError signal: 'Failed to initialize GemStone GCI library.' ].
	loginSuccess := self
		gciLoginStone: stoneName
		hostUser: ''
		hostPass: ''
		gsUser: username
		gsPass: password.
	loginSuccess ifFalse: [
		errorStruct := GciError new.
		(self gciErr: errorStruct) ifTrue: [ ^ self signalError: errorStruct ].
		^ GbsError signal: 'Unknown login failure. Please check your GemStone connection parameters.' ].
	isLoggedIn := true
]

{ #category : 'accessing' }
MockGbsSession >> apiGciExecute: aString context: anInteger [
	"Intercept the actual FFI call used by execute:"
	| errBlock |
	errBlock := self stubs at: #executeError ifAbsent: [ nil ].
	errBlock ifNotNil: [ errBlock value ].
	^ self stubs at: #apiGciExecute ifAbsent: [ 268 ] "268 = true in GS64"
]

{ #category : 'accessing' }
MockGbsSession >> apiGciExecuteStr: scriptString context: contextOop env: envId [
	| block |
	block := self stubs at: #apiGciExecuteStrContextEnv ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: scriptString cull: contextOop cull: envId ].
	^ self stubs at: #apiGciExecuteStr ifAbsent: [ 20 ]
]

{ #category : 'execution' }
MockGbsSession >> evaluate: aString [
	| value |
	value := self stubs at: #evaluate ifAbsent: [ '' ].
	(value respondsTo: #cull:) ifTrue: [ ^ value cull: aString ].
	^ value
]

{ #category : 'execution' }
MockGbsSession >> execute: script [
	| block |
	block := self stubs at: #execute ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value: script ].
	^ self stubs at: #executeResult ifAbsent: [ true ]
]

{ #category : 'execution' }
MockGbsSession >> executeAndFetch: script [
	| block |
	block := self stubs at: #executeAndFetch ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	^ self stubs at: #executeAndFetchResult ifAbsent: [ '' ]
]

{ #category : 'execution' }
MockGbsSession >> executeAndFetch: script context: contextOop [
	| block |
	block := self stubs at: #executeAndFetchContext ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script cull: contextOop ].
	^ self executeAndFetch: script
]

{ #category : 'execution' }
MockGbsSession >> executeScriptAndFetchObject: script [
	| block |
	block := self stubs at: #executeScriptAndFetchObject ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	^ self stubs at: #executeScriptAndFetchObjectResult ifAbsent: [ nil ]
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

{ #category : 'accessing' }
MockGbsSession >> sendInterrupt [
	| block |
	block := self stubs at: #sendInterrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
MockGbsSession >> interrupt [
	| block |
	block := self stubs at: #interrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
MockGbsSession >> signalInterrupt [
	| block |
	block := self stubs at: #signalInterrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
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
