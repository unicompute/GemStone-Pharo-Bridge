Class {
	#name : 'GbsFatalError',
	#superclass : 'GbsGemStoneError',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsFatalError class >> mayResume
[
	"Resuming a fatal error is generally useless."

	^false
]

