Class {
	#name : 'GbsPlaygroundMenuDoItCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuDoItCommand class >> defaultDescription [
	^ 'Evaluate selection in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuDoItCommand class >> defaultIconName [
	^ #smallDoIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuDoItCommand class >> defaultName [
	^ 'GS-Do it'
]

{ #category : 'defaults' }
GbsPlaygroundMenuDoItCommand class >> order [
	^ 900
]

{ #category : 'executing' }
GbsPlaygroundMenuDoItCommand >> execute [
	^ GbsPlaygroundActions gsDoItIn: context
]
