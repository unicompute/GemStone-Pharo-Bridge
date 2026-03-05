Class {
	#name : 'GbxFakeInspectorForService',
	#superclass : 'Object',
	#classVars : [
		'LastOop',
		'LastSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'instance creation' }
GbxFakeInspectorForService class >> inspect: anOop session: aSession [
	LastOop := anOop.
	LastSession := aSession.
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
GbxFakeInspectorForService class >> reset [
	LastOop := nil.
	LastSession := nil
]
