Class {
	#name : 'GbxExecBlock0Tool',
	#superclass : 'GbxExecBlockTool',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock0Tool >> value [
	"Execute block with 0 arguments"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| blk |
		blk := Object _objectForOop: ', blockOop asString, '.
		blk value
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'initialization' }
GbxExecBlock0Tool >> initialize [
	super initialize.
	numArgs := 0.
]
