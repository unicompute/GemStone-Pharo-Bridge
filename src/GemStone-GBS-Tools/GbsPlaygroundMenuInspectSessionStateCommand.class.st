Class {
	#name : 'GbsPlaygroundMenuInspectSessionStateCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuInspectSessionStateCommand class >> defaultDescription [
	^ 'Inspect a GemStone session-state entry by key.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuInspectSessionStateCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuInspectSessionStateCommand class >> defaultName [
	^ 'GS-Inspect Session State Key...'
]

{ #category : 'defaults' }
GbsPlaygroundMenuInspectSessionStateCommand class >> order [
	^ 905
]

{ #category : 'executing' }
GbsPlaygroundMenuInspectSessionStateCommand >> execute [
	^ GbsPlaygroundActions gsInspectSessionStateKeyIn: context
]
