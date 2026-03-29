Class {
	#name : 'GbxIncGcStateStat',
	#superclass : 'GbxObjectMemoryStat',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'archiving' }
GbxIncGcStateStat >> numericValueFrom: anObjectMemory [
	| rawValue letter position |

	rawValue := super numericValueFrom: anObjectMemory.
	rawValue isInteger ifTrue: [ ^ rawValue ].
	rawValue ifNil: [ ^ 0 ].
	letter := rawValue isCharacter
		ifTrue: [ rawValue ]
		ifFalse: [ rawValue asString ifEmpty: [ ^ 0 ] ifNotEmpty: [ rawValue asString first ] ].
	position := 'rmas' indexOf: letter ifAbsent: [ ^ 0 ].
	^ position - 1
]
