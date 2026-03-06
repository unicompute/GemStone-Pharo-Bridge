Class {
	#name : 'GbsPlaygroundMenuFileItInCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuFileItInCommand class >> defaultDescription [
	^ 'Execute selection as GemStone file-in code.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuFileItInCommand class >> defaultIconName [
	^ #smallSave
]

{ #category : 'defaults' }
GbsPlaygroundMenuFileItInCommand class >> defaultName [
	^ 'GS-File it in'
]

{ #category : 'defaults' }
GbsPlaygroundMenuFileItInCommand class >> order [
	^ 904
]

{ #category : 'executing' }
GbsPlaygroundMenuFileItInCommand >> execute [
	^ GbsPlaygroundActions gsFileItInIn: context
]
