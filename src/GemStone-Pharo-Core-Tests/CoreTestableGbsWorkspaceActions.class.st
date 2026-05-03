Class {
	#name : 'CoreTestableGbsWorkspaceActions',
	#superclass : 'GbsWorkspace',
	#instVars : [
		'didDoIt',
		'didInspectIt',
		'didPrintIt'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'actions' }
CoreTestableGbsWorkspaceActions >> doIt [
	didDoIt := true.
	^ true
]

{ #category : 'accessing' }
CoreTestableGbsWorkspaceActions >> didDoIt [
	^ didDoIt = true
]

{ #category : 'accessing' }
CoreTestableGbsWorkspaceActions >> didInspectIt [
	^ didInspectIt = true
]

{ #category : 'accessing' }
CoreTestableGbsWorkspaceActions >> didPrintIt [
	^ didPrintIt = true
]

{ #category : 'actions' }
CoreTestableGbsWorkspaceActions >> gemStonePrintIt [
	didPrintIt := true.
	^ true
]

{ #category : 'actions' }
CoreTestableGbsWorkspaceActions >> inspectIt [
	didInspectIt := true.
	^ true
]
