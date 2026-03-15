Class {
	#name : 'GbxStat',
	#superclass : 'Object',
	#instVars : [
		'name',
		'value',
		'delta',
		'lastValue',
		'timestamp'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStat class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'instance creation' }
GbxStat class >> named: aString value: aNumber [
	^ self new
		name: aString;
		value: aNumber;
		yourself
]

{ #category : 'comparing' }
GbxStat >> = anObject [
	^ (anObject isKindOf: GbxStat)
		and: [ name = anObject name ]
]

{ #category : 'accessing' }
GbxStat >> delta [
	^ delta ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxStat >> delta: aNumber [
	delta := aNumber
]

{ #category : 'accessing' }
GbxStat >> hash [
	^ name hash
]

{ #category : 'accessing' }
GbxStat >> lastValue [
	^ lastValue
]

{ #category : 'accessing' }
GbxStat >> lastValue: aNumber [
	lastValue := aNumber
]

{ #category : 'accessing' }
GbxStat >> name [
	^ name
]

{ #category : 'accessing' }
GbxStat >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxStat >> printString [
	^ name, ': ', value asString, ' (Δ', delta asString, ')'
]

{ #category : 'accessing' }
GbxStat >> reset [
	"Reset the stat to zero"
	lastValue := value.
	value := 0.
	delta := 0.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxStat >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
GbxStat >> timestamp: aDateAndTime [
	timestamp := aDateAndTime
]

{ #category : 'accessing' }
GbxStat >> update [
	"Update the stat value and calculate delta"
	lastValue := value.
	delta := value - lastValue.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxStat >> updateValue: aNumber [
	"Update the stat value and calculate delta"
	lastValue := value.
	value := aNumber.
	delta := value - lastValue.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxStat >> value [
	^ value ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxStat >> value: aNumber [
	value := aNumber
]
