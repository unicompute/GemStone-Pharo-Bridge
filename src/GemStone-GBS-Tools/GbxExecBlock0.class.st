Class {
	#name : 'GbxExecBlock0',
	#superclass : 'GbxExecBlock',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbxExecBlock0 >> value [
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
GbxExecBlock0 >> initialize [
	super initialize.
	numArgs := 0.
]
