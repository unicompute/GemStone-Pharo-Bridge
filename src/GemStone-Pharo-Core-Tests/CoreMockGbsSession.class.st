Class {
	#name : 'CoreMockGbsSession',
	#superclass : 'GbsSession',
	#instVars : [
		'stubs'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreMockGbsSession >> initialize [
	super initialize.
	isLoggedIn := true
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciExecute: aString context: anInteger [
	"Intercept the actual FFI call used by execute:"
	| errBlock |
	errBlock := self stubs at: #executeError ifAbsent: [ nil ].
	errBlock ifNotNil: [ errBlock value ].
	^ self stubs at: #apiGciExecute ifAbsent: [ 268 ] "268 = true in GS64"
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciExecuteStr: scriptString context: contextOop env: envId [
	| block |
	block := self stubs at: #apiGciExecuteStrContextEnv ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: scriptString cull: contextOop cull: envId ].
	^ self stubs at: #apiGciExecuteStr ifAbsent: [ 20 ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciErr: errorStruct [
	^ self gciErr: errorStruct
]

{ #category : 'execution' }
CoreMockGbsSession >> evaluate: aString [
	| value |
	value := self stubs at: #evaluate ifAbsent: [ '' ].
	(value respondsTo: #cull:) ifTrue: [ ^ value cull: aString ].
	^ value
]

{ #category : 'execution' }
CoreMockGbsSession >> execute: script [
	| block |
	block := self stubs at: #execute ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value: script ].
	^ self stubs at: #executeResult ifAbsent: [ true ]
]

{ #category : 'execution' }
CoreMockGbsSession >> executeAndFetch: script [
	| block |
	block := self stubs at: #executeAndFetch ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	^ self stubs at: #executeAndFetchResult ifAbsent: [ '' ]
]

{ #category : 'execution' }
CoreMockGbsSession >> executeAndFetch: script context: contextOop [
	| block |
	block := self stubs at: #executeAndFetchContext ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script cull: contextOop ].
	^ self executeAndFetch: script
]

{ #category : 'execution' }
CoreMockGbsSession >> executeScriptAndFetchObject: script [
	| block |
	block := self stubs at: #executeScriptAndFetchObject ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	(self stubs includesKey: #executeScriptAndFetchObjectResult)
		ifTrue: [ ^ self stubs at: #executeScriptAndFetchObjectResult ].
	((self stubs includesKey: #executeAndFetch)
		or: [ self stubs includesKey: #executeAndFetchResult ])
		ifTrue: [ ^ self executeAndFetch: script ].
	^ nil
]

{ #category : 'execution' }
CoreMockGbsSession >> executeScriptAndReturnOop: script [
	| block |
	block := self stubs at: #executeScriptAndReturnOop ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	(self stubs includesKey: #executeScriptAndReturnOopResult)
		ifTrue: [ ^ self stubs at: #executeScriptAndReturnOopResult ].
	^ super executeScriptAndReturnOop: script
]

{ #category : 'execution' }
CoreMockGbsSession >> forwardRemoteMessage: aMessage forOop: targetOop [
	| block |
	block := self stubs at: #forwardRemoteMessage ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: aMessage cull: targetOop ].
	^ super forwardRemoteMessage: aMessage forOop: targetOop
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> refreshAllTypedWrapperClasses [
	| block |
	block := self stubs at: #refreshAllTypedWrapperClasses ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super refreshAllTypedWrapperClasses
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> refreshStaleTypedWrapperClasses [
	| block |
	block := self stubs at: #refreshStaleTypedWrapperClasses ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super refreshStaleTypedWrapperClasses
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> typedWrapperLifecycleReportText [
	| block |
	block := self stubs at: #typedWrapperLifecycleReportText ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super typedWrapperLifecycleReportText
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> typedWrapperLifecycleReport [
	| block |
	block := self stubs at: #typedWrapperLifecycleReport ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super typedWrapperLifecycleReport
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciAbort [
	| value |
	value := self stubs at: #gciAbort ifAbsent: [ 1 ].
	(value respondsTo: #value) ifTrue: [ ^ value value ].
	^ value
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciCommit [
	| value |
	value := self stubs at: #gciCommit ifAbsent: [ 1 ].
	(value respondsTo: #value) ifTrue: [ ^ value value ].
	^ value
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciErr: errorStruct [
	| block |
	block := self stubs at: #gciErr ifAbsent: [ nil ].
	block ifNotNil: [ block value: errorStruct. ^ true ].
	^ false
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciInit [
	^ self stubs at: #gciInit ifAbsent: [ true ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciLoginStone: s hostUser: hu hostPass: hp gsUser: gu gsPass: gp [
	^ self stubs at: #gciLogin ifAbsent: [ true ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciLogout [
	^ self stubs at: #gciLogout ifAbsent: [ 1 ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciPollForSignal [
	^ self stubs at: #gciPollForSignal ifAbsent: [ 0 ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> sendInterrupt [
	| block |
	block := self stubs at: #sendInterrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
CoreMockGbsSession >> interrupt [
	| block |
	block := self stubs at: #interrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
CoreMockGbsSession >> signalInterrupt [
	| block |
	block := self stubs at: #signalInterrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'execution' }
CoreMockGbsSession >> serverInterface [
	"Return self so this mock can also intercept serverInterface calls!"
	^ self
]

{ #category : 'accessing' }
CoreMockGbsSession >> stubs [
	^ stubs ifNil: [ stubs := Dictionary new ]
]
