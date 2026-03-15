Class {
	#name : 'GbxExecBlockN',
	#superclass : 'GbxExecBlock',
	#instVars : [
		'arguments'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxExecBlockN class >> oop: anOop session: aSession args: argArray [
	^ self new
		blockOop: anOop;
		session: aSession;
		arguments: argArray;
		yourself
]

{ #category : 'execution' }
GbxExecBlockN >> valueWithArguments: argArray [
	"Execute block with N arguments"
	| script argsString |
	
	session ifNil: [ ^ nil ].
	
	argsString := argArray collect: [ :arg | arg asString ].
	argsString := argsString inject: '' into: [ :sum :each |
		sum isEmpty ifTrue: [ each ] ifFalse: [ sum, ' ', each ]
	].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk perform: #valueWithArguments: with: { ', argsString, ' }
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'accessing' }
GbxExecBlockN >> arguments [
	^ arguments
]

{ #category : 'accessing' }
GbxExecBlockN >> arguments: aCollection [
	arguments := aCollection.
	numArgs := aCollection size.
]

{ #category : 'initialization' }
GbxExecBlockN >> initialize [
	super initialize.
	arguments := #().
]
