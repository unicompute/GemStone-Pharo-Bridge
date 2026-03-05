Class {
	#name : 'GbxTestableDebuggerService',
	#superclass : 'GbxDebuggerService',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'inspector' }
GbxTestableDebuggerService >> inspectorClass [
	^ GbxFakeInspectorForService
]

{ #category : 'breakpoint support' }
GbxTestableDebuggerService >> breakpointClass [
	^ GbxFakeBreakPointForService
]

{ #category : 'breakpoint support' }
GbxTestableDebuggerService >> browserClass [
	^ GbxFakeBrowserForService
]
