Class {
	#name : 'GbxFinalizer',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'installation' }
GbxFinalizer class >> installGbxFinalizer [
	"Pharo compatibility stub. The bridge still expects the hook to exist, but the
	actual finalization strategy is provided by Pharo's native WeakArray support."

	^self
]
