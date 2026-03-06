Class {
	#name : 'GbsPlaygroundGsFileItInCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsFileItInCommand class >> defaultDescription [
	^ 'Execute selection as GemStone file-in code.'
]

{ #category : 'defaults' }
GbsPlaygroundGsFileItInCommand class >> defaultIconName [
	^ #smallSave
]

{ #category : 'defaults' }
GbsPlaygroundGsFileItInCommand class >> defaultName [
	^ 'GS-File it in'
]

{ #category : 'defaults' }
GbsPlaygroundGsFileItInCommand class >> order [
	^ 204
]

{ #category : 'executing' }
GbsPlaygroundGsFileItInCommand >> execute [
	^ GbsPlaygroundActions gsFileItInIn: context
]
