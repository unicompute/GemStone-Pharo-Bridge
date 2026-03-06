Class {
	#name : 'GbsPlaygroundMenuPrintItCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuPrintItCommand class >> defaultDescription [
	^ 'Print selection in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuPrintItCommand class >> defaultIconName [
	^ #smallPrintIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuPrintItCommand class >> defaultName [
	^ 'GS-Print it'
]

{ #category : 'defaults' }
GbsPlaygroundMenuPrintItCommand class >> order [
	^ 901
]

{ #category : 'executing' }
GbsPlaygroundMenuPrintItCommand >> execute [
	^ GbsPlaygroundActions gsPrintItIn: context
]
