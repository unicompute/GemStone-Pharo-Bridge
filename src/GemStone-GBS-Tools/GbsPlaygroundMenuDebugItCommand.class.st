Class {
	#name : 'GbsPlaygroundMenuDebugItCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuDebugItCommand class >> defaultDescription [
	^ 'Debug selection in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuDebugItCommand class >> defaultIconName [
	^ #smallDebug
]

{ #category : 'defaults' }
GbsPlaygroundMenuDebugItCommand class >> defaultName [
	^ 'GS-Debug it'
]

{ #category : 'defaults' }
GbsPlaygroundMenuDebugItCommand class >> order [
	^ 903
]

{ #category : 'executing' }
GbsPlaygroundMenuDebugItCommand >> execute [
	^ GbsPlaygroundActions gsDebugItIn: context
]
