Class {
	#name : 'GbxTestableDebuggerService',
	#superclass : 'GbxDebuggerService',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
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
