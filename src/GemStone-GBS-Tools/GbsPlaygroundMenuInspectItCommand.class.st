Class {
	#name : 'GbsPlaygroundMenuInspectItCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuInspectItCommand class >> defaultDescription [
	^ 'Inspect selection result in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuInspectItCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuInspectItCommand class >> defaultName [
	^ 'GS-Inspect it'
]

{ #category : 'defaults' }
GbsPlaygroundMenuInspectItCommand class >> order [
	^ 902
]

{ #category : 'executing' }
GbsPlaygroundMenuInspectItCommand >> execute [
	^ GbsPlaygroundActions gsInspectItIn: context
]
