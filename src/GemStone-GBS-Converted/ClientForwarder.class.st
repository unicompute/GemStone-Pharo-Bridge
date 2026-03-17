Class {
	#name : 'ClientForwarder',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'dirtying' }
ClientForwarder >> markDirty
[
	"A clientForwarder instance should never be flushed, so I ignore this message.
	Actually, since I have no state, flushing me would probably not change anything, but
	there is certainly no need to flush me."
]

