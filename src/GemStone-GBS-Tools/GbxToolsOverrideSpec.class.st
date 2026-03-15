Class {
	#name : 'GbxToolsOverrideSpec',
	#superclass : 'Object',
	#instVars : [
		'selector',
		'overrideBlock',
		'isEnabled'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolsOverrideSpec class >> selector: aSymbol override: aBlock [
	^ self new
		selector: aSymbol;
		overrideBlock: aBlock;
		yourself
]

{ #category : 'applying' }
GbxToolsOverrideSpec >> applyTo: anObject [
	"Apply this override to an object"
	
	isEnabled ifFalse: [ ^ self ].
	overrideBlock ifNil: [ ^ self ].
	
	[ overrideBlock value: anObject ] on: Error do: [ ].
]

{ #category : 'accessing' }
GbxToolsOverrideSpec >> disable [
	"Disable this override"
	isEnabled := false.
]

{ #category : 'accessing' }
GbxToolsOverrideSpec >> enable [
	"Enable this override"
	isEnabled := true.
]

{ #category : 'initialization' }
GbxToolsOverrideSpec >> initialize [
	super initialize.
	isEnabled := true.
]

{ #category : 'testing' }
GbxToolsOverrideSpec >> isEnabled [
	^ isEnabled ifNil: [ true ]
]

{ #category : 'accessing' }
GbxToolsOverrideSpec >> overrideBlock [
	^ overrideBlock
]

{ #category : 'accessing' }
GbxToolsOverrideSpec >> overrideBlock: aBlock [
	overrideBlock := aBlock
]

{ #category : 'accessing' }
GbxToolsOverrideSpec >> selector [
	^ selector
]

{ #category : 'accessing' }
GbxToolsOverrideSpec >> selector: aSymbol [
	selector := aSymbol
]
