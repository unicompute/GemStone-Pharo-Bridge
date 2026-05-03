Class {
	#name : 'CoreGbxFakeServiceForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'currentContext',
		'currentReceiverOopValue',
		'contextList',
		'processOopValue',
		'labelValue',
		'restartCalls',
		'terminateCalls',
		'initializeForDebuggingCalls',
		'resetServerPCToStepOneCalls',
		'recomputeContextListCalls',
		'onRestartBlock',
		'onResetServerPCToStepOneBlock',
		'restartNeedsFreshFaultReplayValue',
		'restartSourceString'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreGbxFakeServiceForRemoteDebugger >> initialize [
	super initialize.
	contextList := #().
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentContext [
	^ currentContext
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentContext: aContext [
	currentContext := aContext
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentReceiverOop [
	^ currentReceiverOopValue
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentReceiverOop: anObject [
	currentReceiverOopValue := anObject
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> contextList [
	^ contextList ifNil: [ #() ]
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> contextList: aCollection [
	contextList := aCollection.
	currentContext ifNil: [
		currentContext := contextList
			ifEmpty: [ nil ]
			ifNotEmpty: [ :contexts | contexts first ]
	]
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> initializeForDebuggingCalls [
	^ initializeForDebuggingCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> label [
	^ labelValue
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> label: aString [
	labelValue := aString
]

{ #category : 'stepping' }
CoreGbxFakeServiceForRemoteDebugger >> onResetServerPCToStepOneDo: aBlock [
	onResetServerPCToStepOneBlock := aBlock
]

{ #category : 'stepping' }
CoreGbxFakeServiceForRemoteDebugger >> onRestartDo: aBlock [
	onRestartBlock := aBlock
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> processOop [
	^ processOopValue
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> processOop: anObject [
	processOopValue := anObject
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> recomputeContextListCalls [
	^ recomputeContextListCalls ifNil: [ 0 ]
]

{ #category : 'context list' }
CoreGbxFakeServiceForRemoteDebugger >> recomputeContextList [
	recomputeContextListCalls := self recomputeContextListCalls + 1.
	^ self
]

{ #category : 'stepping' }
CoreGbxFakeServiceForRemoteDebugger >> resetServerPCToStepOne [
	resetServerPCToStepOneCalls := self resetServerPCToStepOneCalls + 1.
	onResetServerPCToStepOneBlock ifNotNil: [
		^ onResetServerPCToStepOneBlock cull: self
	].
	^ true
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> resetServerPCToStepOneCalls [
	^ resetServerPCToStepOneCalls ifNil: [ 0 ]
]

{ #category : 'process control' }
CoreGbxFakeServiceForRemoteDebugger >> restart [
	restartCalls := self restartCalls + 1.
	onRestartBlock ifNotNil: [
		onRestartBlock cull: self
	].
	^ true
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> restartCalls [
	^ restartCalls ifNil: [ 0 ]
]

{ #category : 'process control' }
CoreGbxFakeServiceForRemoteDebugger >> restartNeedsFreshFaultReplay [
	^ restartNeedsFreshFaultReplayValue
]

{ #category : 'process control' }
CoreGbxFakeServiceForRemoteDebugger >> restartNeedsFreshFaultReplay: aBoolean [
	restartNeedsFreshFaultReplayValue := aBoolean
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> restartSourceString [
	^ restartSourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> restartSourceString: aString [
	restartSourceString := aString
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> selectedMethodClassName [
	^ currentContext
		ifNil: [ nil ]
		ifNotNil: [
			(currentContext respondsTo: #methodClassOrUnknown)
				ifTrue: [ currentContext methodClassOrUnknown ]
				ifFalse: [ nil ] ]
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> selectedMethodSelector [
	^ currentContext
		ifNil: [ nil ]
		ifNotNil: [
			(currentContext respondsTo: #selectorOrUnknown)
				ifTrue: [ currentContext selectorOrUnknown ]
				ifFalse: [ nil ] ]
]

{ #category : 'selection' }
CoreGbxFakeServiceForRemoteDebugger >> selectContext: aContext [
	currentContext := aContext
]

{ #category : 'process control' }
CoreGbxFakeServiceForRemoteDebugger >> terminate [
	terminateCalls := self terminateCalls + 1.
	^ true
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> terminateCalls [
	^ terminateCalls ifNil: [ 0 ]
]

{ #category : 'initialization' }
CoreGbxFakeServiceForRemoteDebugger >> initializeForDebugging [
	initializeForDebuggingCalls := self initializeForDebuggingCalls + 1.
	^ self
]
