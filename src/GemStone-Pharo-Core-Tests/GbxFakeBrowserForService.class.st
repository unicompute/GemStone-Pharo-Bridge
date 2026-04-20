Class {
	#name : 'GbxFakeBrowserForService',
	#superclass : 'Object',
	#classVars : [
		'LastBreakView',
		'LastModel',
		'LastMethod',
		'LastClass',
		'SetBreakCalls'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'breakpoint support' }
GbxFakeBrowserForService class >> setBreakInView: aView model: aModel method: aSelector class: aClassName [
	SetBreakCalls := self setBreakCalls + 1.
	LastBreakView := aView.
	LastModel := aModel.
	LastMethod := aSelector.
	LastClass := aClassName.
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastBreakView [
	^ LastBreakView
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastModel [
	^ LastModel
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastMethod [
	^ LastMethod
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastClass [
	^ LastClass
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> reset [
	SetBreakCalls := 0.
	LastBreakView := nil.
	LastModel := nil.
	LastMethod := nil.
	LastClass := nil
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> setBreakCalls [
	^ SetBreakCalls ifNil: [ 0 ]
]
