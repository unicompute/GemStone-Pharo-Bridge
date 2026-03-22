Class {
	#name : 'GbxReceiverInspectorTool',
	#superclass : 'GbxContextInspectorTool',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxReceiverInspectorTool class >> inspectReceiverOf: anActivation session: aSession [
	"Inspect the receiver of the given activation (context)"
	| receiverOop inspector |
	
	receiverOop := anActivation receiverOop.
	receiverOop ifNil: [ 
		"Fetch receiver from server if not cached"
		receiverOop := self fetchReceiverOopFor: anActivation session: aSession.
	].
	
	receiverOop ifNil: [ ^ nil ].
	
	inspector := self new.
	inspector inspectOop: receiverOop session: aSession context: anActivation contextOop.
	inspector open.
	^ inspector
]

{ #category : 'instance creation' }
GbxReceiverInspectorTool class >> inspectReceiverOfContext: contextOop session: aSession [
	"Inspect the receiver of the given context OOP"
	| script receiverOop inspector |
	
	script := '[
		| ctx obj |
		ctx := Object _objectForOop: ', contextOop asString, '.
		obj := ctx receiver.
		Reflection oopOf: obj
	] value'.
	
	receiverOop := aSession executeAndFetch: script.
	receiverOop ifNil: [ ^ nil ].
	
	inspector := self new.
	inspector inspectOop: receiverOop session: aSession context: contextOop.
	inspector open.
	^ inspector
]

{ #category : 'fetching' }
GbxReceiverInspectorTool class >> fetchReceiverOopFor: anActivation session: aSession [
	"Fetch the receiver OOP from the server for an activation"
	| script |
	
	anActivation contextOop ifNil: [ ^ nil ].
	
	script := '[
		| ctx obj |
		ctx := Object _objectForOop: ', anActivation contextOop asString, '.
		obj := ctx receiver.
		Reflection oopOf: obj
	] value'.
	
	^ aSession executeAndFetch: script
]

{ #category : 'initialization' }
GbxReceiverInspectorTool >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Receiver Inspector';
		initialExtent: 450 @ 500.
]
