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
