Class {
	#name : 'GbxExecBlock2',
	#superclass : 'GbxExecBlock',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock2 >> value: arg1 value: arg2 [
	"Execute block with 2 arguments"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value: ', arg1 asString, ' value: ', arg2 asString, '
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'initialization' }
GbxExecBlock2 >> initialize [
	super initialize.
	numArgs := 2.
]
