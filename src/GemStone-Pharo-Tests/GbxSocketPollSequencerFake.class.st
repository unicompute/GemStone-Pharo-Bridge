Class {
	#name : 'GbxSocketPollSequencerFake',
	#superclass : 'Object',
	#instVars : [
		'primInterface'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
GbxSocketPollSequencerFake >> initialize [
	super initialize.
	primInterface := GbxSocketPollPrimInterfaceFake new
]

{ #category : 'accessing' }
GbxSocketPollSequencerFake >> primInterface [
	^ primInterface
]
