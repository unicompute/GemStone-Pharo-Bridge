Class {
	#name : 'GbxFakeInspectorForService',
	#superclass : 'Object',
	#classVars : [
		'LastOop',
		'LastSession',
		'LastContext'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'instance creation' }
GbxFakeInspectorForService class >> inspect: anOop session: aSession [
	LastOop := anOop.
	LastSession := aSession.
	LastContext := nil.
	^ self new
]

{ #category : 'instance creation' }
GbxFakeInspectorForService class >> inspect: anOop session: aSession context: aContextOop [
	LastOop := anOop.
	LastSession := aSession.
	LastContext := aContextOop.
	^ self new
]

{ #category : 'accessing' }
GbxFakeInspectorForService class >> lastOop [
	^ LastOop
]

{ #category : 'accessing' }
GbxFakeInspectorForService class >> lastSession [
	^ LastSession
]

{ #category : 'accessing' }
GbxFakeInspectorForService class >> lastContext [
	^ LastContext
]

{ #category : 'accessing' }
GbxFakeInspectorForService class >> reset [
	LastOop := nil.
	LastSession := nil.
	LastContext := nil
]
