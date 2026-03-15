Class {
	#name : 'GbxExecBlock',
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
GbxExecBlock class >> oop: anOop session: aSession [
	^ self new
		blockOop: anOop;
		session: aSession;
		yourself
]

{ #category : 'execution' }
GbxExecBlock >> value [
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
GbxExecBlock >> blockOop [
	^ blockOop
]

{ #category : 'accessing' }
GbxExecBlock >> blockOop: anOop [
	blockOop := anOop
]

{ #category : 'accessing' }
GbxExecBlock >> numArgs [
	^ numArgs ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxExecBlock >> numArgs: anInteger [
	numArgs := anInteger
]

{ #category : 'accessing' }
GbxExecBlock >> session [
	^ session
]

{ #category : 'accessing' }
GbxExecBlock >> session: aSession [
	session := aSession
]
