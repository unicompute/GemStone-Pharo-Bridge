Class {
	#name : 'GbxExecBlock1Tool',
	#superclass : 'GbxExecBlockTool',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock1Tool >> value: arg1 [
	"Execute block with 1 argument"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value: ', arg1 asString, '
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'initialization' }
GbxExecBlock1Tool >> initialize [
	super initialize.
	numArgs := 1.
]
