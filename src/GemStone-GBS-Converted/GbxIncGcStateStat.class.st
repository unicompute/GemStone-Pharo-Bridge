Class {
	#name : 'GbxIncGcStateStat',
	#superclass : 'GbxObjectMemoryStat',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'archiving' }
GbxIncGcStateStat >> numericValueFrom: anObjectMemory
[

	| letter |
	letter := super numericValueFrom: anObjectMemory.
	^('rmas' indexOf: letter
		ifAbsent: 
			[self gbsMessenger error: 'Unexpected incGC state' , (String with: letter)])
			- 1
]

