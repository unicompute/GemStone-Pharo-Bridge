Class {
	#name : 'GbxExecBlock4',
	#superclass : 'GbxExecBlock',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock4 >> value: arg1 value: arg2 value: arg3 value: arg4 [
	"Execute block with 4 arguments"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value: ', arg1 asString, ' value: ', arg2 asString, ' value: ', arg3 asString, ' value: ', arg4 asString, '
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'initialization' }
GbxExecBlock4 >> initialize [
	super initialize.
	numArgs := 4.
]
