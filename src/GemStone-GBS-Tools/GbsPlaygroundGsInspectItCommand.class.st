Class {
	#name : 'GbsPlaygroundGsInspectItCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsInspectItCommand class >> defaultDescription [
	^ 'Inspect selection result in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundGsInspectItCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsInspectItCommand class >> defaultName [
	^ 'GS-Inspect it'
]

{ #category : 'defaults' }
GbsPlaygroundGsInspectItCommand class >> order [
	^ 202
]

{ #category : 'executing' }
GbsPlaygroundGsInspectItCommand >> execute [
	^ GbsPlaygroundActions gsInspectItIn: context
]
