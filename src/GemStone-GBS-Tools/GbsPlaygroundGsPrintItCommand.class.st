Class {
	#name : 'GbsPlaygroundGsPrintItCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsPrintItCommand class >> defaultDescription [
	^ 'Print selection in GemStone.'
]

{ #category : 'defaults' }
GbsPlaygroundGsPrintItCommand class >> defaultIconName [
	^ #smallPrintIt
]

{ #category : 'defaults' }
GbsPlaygroundGsPrintItCommand class >> defaultName [
	^ 'GS-Print it'
]

{ #category : 'defaults' }
GbsPlaygroundGsPrintItCommand class >> order [
	^ 201
]

{ #category : 'executing' }
GbsPlaygroundGsPrintItCommand >> execute [
	^ GbsPlaygroundActions gsPrintItIn: context
]
