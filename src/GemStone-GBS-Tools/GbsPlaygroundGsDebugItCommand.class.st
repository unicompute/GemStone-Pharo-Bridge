Class {
	#name : 'GbsPlaygroundGsDebugItCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsDebugItCommand class >> defaultDescription [
	^ 'Debug selection in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundGsDebugItCommand class >> defaultIconName [
	^ #smallDebug
]

{ #category : 'defaults' }
GbsPlaygroundGsDebugItCommand class >> defaultName [
	^ 'GS-Debug it'
]

{ #category : 'defaults' }
GbsPlaygroundGsDebugItCommand class >> order [
	^ 203
]

{ #category : 'executing' }
GbsPlaygroundGsDebugItCommand >> execute [
	^ GbsPlaygroundActions gsDebugItIn: context
]
