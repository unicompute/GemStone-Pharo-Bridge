Class {
	#name : 'GbsPlaygroundGsInspectSessionStateCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsInspectSessionStateCommand class >> defaultDescription [
	^ 'Inspect a GemStone session-state entry by key.'
]

{ #category : 'defaults' }
GbsPlaygroundGsInspectSessionStateCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsInspectSessionStateCommand class >> defaultName [
	^ 'GS-Inspect Session State Key...'
]

{ #category : 'defaults' }
GbsPlaygroundGsInspectSessionStateCommand class >> order [
	^ 205
]

{ #category : 'executing' }
GbsPlaygroundGsInspectSessionStateCommand >> execute [
	^ GbsPlaygroundActions gsInspectSessionStateKeyIn: context
]
