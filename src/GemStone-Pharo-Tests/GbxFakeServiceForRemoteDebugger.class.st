Class {
	#name : 'GbxFakeServiceForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'inspectReceiverCalls',
		'inspectProcessCalls',
		'inspectFrameCalls',
		'inspectVariableCalls',
		'lastInspectedVariableName',
		'gsDoItCalls',
		'gsPrintItCalls',
		'gsInspectItCalls',
		'recompileCalls',
		'lastRecompiledSource',
		'toggleBreakPointCalls',
		'setBreakPointCalls',
		'removeBreakPointCalls',
		'removeAllBreakPointsCalls',
		'sourceMap',
		'raiseOnInspectReceiver',
		'recompileShouldSucceed',
		'compileErrorMessage'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
GbxFakeServiceForRemoteDebugger >> initialize [
	super initialize.
	raiseOnInspectReceiver := false.
	recompileShouldSucceed := true.
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectCurrentReceiver [
	raiseOnInspectReceiver = true ifTrue: [ Error signal: 'inspect receiver failed' ].
	inspectReceiverCalls := self inspectReceiverCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectCurrentProcess [
	inspectProcessCalls := self inspectProcessCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectCurrentFrame [
	inspectFrameCalls := self inspectFrameCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectVariableNamed: aVariableName [
	inspectVariableCalls := self inspectVariableCalls + 1.
	lastInspectedVariableName := aVariableName.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> gsDoIt: codeString [
	gsDoItCalls := self gsDoItCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> gsPrintIt: codeString [
	gsPrintItCalls := self gsPrintItCalls + 1.
	^ '42'
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> gsInspectIt: codeString [
	gsInspectItCalls := self gsInspectItCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> recompileCurrentMethodWithSource: sourceString [
	recompileCalls := self recompileCalls + 1.
	lastRecompiledSource := sourceString.
	^ recompileShouldSucceed ifNil: [ true ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectReceiverCalls [
	^ inspectReceiverCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectProcessCalls [
	^ inspectProcessCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectFrameCalls [
	^ inspectFrameCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectVariableCalls [
	^ inspectVariableCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> lastInspectedVariableName [
	^ lastInspectedVariableName
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> gsDoItCalls [
	^ gsDoItCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> gsPrintItCalls [
	^ gsPrintItCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> gsInspectItCalls [
	^ gsInspectItCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> recompileCalls [
	^ recompileCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> lastRecompiledSource [
	^ lastRecompiledSource
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> setBreakPointIn: aTextWidget [
	setBreakPointCalls := self setBreakPointCalls + 1.
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> toggleBreakPointIn: aTextWidget [
	toggleBreakPointCalls := self toggleBreakPointCalls + 1.
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeBreakIn: aTextWidget [
	removeBreakPointCalls := self removeBreakPointCalls + 1.
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeAllBreakPoints [
	removeAllBreakPointsCalls := self removeAllBreakPointsCalls + 1.
	^ 1
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> setBreakPointCalls [
	^ setBreakPointCalls ifNil: [ 0 ]
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> toggleBreakPointCalls [
	^ toggleBreakPointCalls ifNil: [ 0 ]
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeBreakPointCalls [
	^ removeBreakPointCalls ifNil: [ 0 ]
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeAllBreakPointsCalls [
	^ removeAllBreakPointsCalls ifNil: [ 0 ]
]

{ #category : 'source map' }
GbxFakeServiceForRemoteDebugger >> sourceMap [
	^ sourceMap ifNil: [ #( ) ]
]

{ #category : 'source map' }
GbxFakeServiceForRemoteDebugger >> sourceMap: aCollection [
	sourceMap := aCollection
]

{ #category : 'evaluation' }
GbxFakeServiceForRemoteDebugger >> recompileShouldSucceed: aBoolean [
	recompileShouldSucceed := aBoolean
]

{ #category : 'evaluation' }
GbxFakeServiceForRemoteDebugger >> lastCompileError [
	^ compileErrorMessage ifNil: [ 'compile failed' ]
]

{ #category : 'evaluation' }
GbxFakeServiceForRemoteDebugger >> lastCompileError: aString [
	compileErrorMessage := aString
]

{ #category : 'evaluation' }
GbxFakeServiceForRemoteDebugger >> clearCompileError [
	compileErrorMessage := nil
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> canSetBreakPoint [
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> canRemoveBreakPoint [
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> canRemoveAllBreakPoints [
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> canToggleBreakPoint [
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> breakpointSummaryString [
	^ 'Breakpoints step points: 2'
]

{ #category : 'testing' }
GbxFakeServiceForRemoteDebugger >> raiseOnInspectReceiver: aBoolean [
	raiseOnInspectReceiver := aBoolean
]

{ #category : 'selection' }
GbxFakeServiceForRemoteDebugger >> selectContext: aContext [
	"Presenter tests only need this to exist."
]
