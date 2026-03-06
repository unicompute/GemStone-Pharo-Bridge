Class {
	#name : 'GbsPlaygroundGsDoItCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsDoItCommand class >> defaultDescription [
	^ 'Evaluate selection in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundGsDoItCommand class >> defaultIconName [
	^ #smallDoIt
]

{ #category : 'defaults' }
GbsPlaygroundGsDoItCommand class >> defaultName [
	^ 'GS-Do it'
]

{ #category : 'defaults' }
GbsPlaygroundGsDoItCommand class >> order [
	^ 200
]

{ #category : 'executing' }
GbsPlaygroundGsDoItCommand >> execute [
	^ GbsPlaygroundActions gsDoItIn: context
]
