Class {
	#name : 'GbxExecBlockTool',
	#superclass : 'Object',
	#instVars : [
		'method',
		'session',
		'blockOop',
		'numArgs'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxExecBlockTool class >> oop: anOop session: aSession [
	^ self new
		blockOop: anOop;
		session: aSession;
		yourself
]

{ #category : 'execution' }
GbxExecBlockTool >> value [
	"Execute block with no arguments"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'accessing' }
GbxExecBlockTool >> blockOop [
	^ blockOop
]

{ #category : 'accessing' }
GbxExecBlockTool >> blockOop: anOop [
	blockOop := anOop
]

{ #category : 'accessing' }
GbxExecBlockTool >> numArgs [
	^ numArgs ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxExecBlockTool >> numArgs: anInteger [
	numArgs := anInteger
]

{ #category : 'accessing' }
GbxExecBlockTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxExecBlockTool >> session: aSession [
	session := aSession
]
