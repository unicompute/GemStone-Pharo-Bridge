Class {
	#name : 'GbxContextInspector',
	#superclass : 'GbsInspector',
	#instVars : [
		'contextOop',
		'activation',
		'service',
		'object',
		'properties'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxContextInspector class >> inspectContext: aContextOop session: aSession [
	"Inspect a GemStone context (Activation)"
	| inspector |
	
	inspector := self new.
	inspector inspectContextOop: aContextOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'instance creation' }
GbxContextInspector class >> inspectActivation: anActivation session: aSession [
	"Inspect a GbxActivation object"
	| inspector |
	
	inspector := self new.
	inspector inspectActivation: anActivation session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'accessing' }
GbxContextInspector >> inspectActivation: anActivation session: aSession [
	activation := anActivation.
	contextOop := anActivation contextOop.
	
	self inspectContextOop: contextOop session: aSession.
]

{ #category : 'accessing' }
GbxContextInspector >> inspectContextOop: aContextOop session: aSession [
	| className printString rawData parsedItems items |
	
	contextOop := aContextOop.
	oop := aContextOop.
	session := aSession.
	evaluationContextOop := aContextOop.

	"1. Get context info"
	className := session executeAndFetch: '(Object _objectForOop: ', aContextOop asString, ') class name asString'.
	classLabel label: 'Context: ', className.
	printString := self fetchContextPrintString.

	"2. Initialize table with context info"
	items := OrderedCollection new.
	items add: { 'self (context)' . printString . aContextOop }.

	"3. Fetch context instance variables"
	rawData := self fetchContextFields.
	parsedItems := self class parseReflectionString: rawData.
	items addAll: parsedItems.

	stateTable items: items.

	"4. Double-click to inspect"
	stateTable whenActivatedDo: [ :selection |
		| selectedItem childOop |
		selectedItem := selection selectedItem.
		childOop := selectedItem third.
		childOop > 20 ifTrue: [
			GbsInspector inspect: childOop session: session context: contextOop
		].
	].
]

{ #category : 'fetching' }
GbxContextInspector >> fetchContextPrintString [
	"Fetch a descriptive string for the context"
	| script |
	
	script := '[
		| ctx stream |
		ctx := Object _objectForOop: ', contextOop asString, '.
		stream := WriteStream on: String new.
		stream
			nextPutAll: ctx class name;
			nextPutAll: '' - '';
			nextPutAll: ctx method selector asString.
		ctx ip ifNotNil: [ :ip |
			stream
				nextPutAll: '' @'';
				nextPutAll: ip asString ].
		stream contents
	] value'.
	
	^ session executeAndFetch: script
]

{ #category : 'fetching' }
GbxContextInspector >> fetchContextFields [
	"Fetch context instance variables from server"
	| script |
	
	script := '[
		| ctx stream names childVal childOop |
		ctx := Object _objectForOop: ', contextOop asString, '.
		stream := WriteStream on: String new.
		names := ctx class allInstVarNames.
		1 to: names size do: [ :i |
			childVal := ctx instVarAt: i.
			childOop := Reflection oopOf: childVal.
			stream
				nextPutAll: (names at: i) asString; nextPutAll: ''::::'';
				nextPutAll: childVal printString; nextPutAll: ''::::'';
				nextPutAll: childOop asString; lf.
		].
		stream contents
	] value'.
	
	^ session executeAndFetch: script
]

{ #category : 'initialization' }
GbxContextInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Context Inspector';
		initialExtent: 450 @ 500.
]
