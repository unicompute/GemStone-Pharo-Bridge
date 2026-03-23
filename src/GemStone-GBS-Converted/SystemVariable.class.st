Class {
	#name : 'SystemVariable',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
SystemVariable class >> named: aString [
	^ self new name: aString
]

{ #category : 'accessing' }
SystemVariable >> value [
	^ OSEnvironment current at: 'PWD' ifAbsent: [ '.' ]
]

{ #category : 'accessing' }
SystemVariable >> name: aString [
	"Ignore for now, we only support PWD via this stub"
]
