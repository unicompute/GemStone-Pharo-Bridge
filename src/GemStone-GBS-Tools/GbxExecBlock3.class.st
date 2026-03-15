Class {
	#name : 'GbxExecBlock3',
	#superclass : 'GbxExecBlock',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock3 >> value: arg1 value: arg2 value: arg3 [
	"Execute block with 3 arguments"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value: ', arg1 asString, ' value: ', arg2 asString, ' value: ', arg3 asString, '
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'initialization' }
GbxExecBlock3 >> initialize [
	super initialize.
	numArgs := 3.
]
