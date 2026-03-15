Class {
	#name : 'GbxExecBlock5',
	#superclass : 'GbxExecBlock',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock5 >> value: arg1 value: arg2 value: arg3 value: arg4 value: arg5 [
	"Execute block with 5 arguments"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value: ', arg1 asString, ' value: ', arg2 asString, ' value: ', arg3 asString, ' value: ', arg4 asString, ' value: ', arg5 asString, '
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'initialization' }
GbxExecBlock5 >> initialize [
	super initialize.
	numArgs := 5.
]
