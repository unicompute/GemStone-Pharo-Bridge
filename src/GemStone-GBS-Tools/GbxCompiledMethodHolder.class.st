Class {
	#name : 'GbxCompiledMethodHolder',
	#superclass : 'GbxMethodHolder',
	#instVars : [
		'oop'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxCompiledMethodHolder class >> on: aCompiledMethod [
	"Create a holder for a GemStone compiled method (forwarder or proxy)"
	^ self new
		compiledMethod: aCompiledMethod;
		yourself
]

{ #category : 'instance creation' }
GbxCompiledMethodHolder class >> selector: aSymbol class: aClassName oop: methodOop [
	^ self new
		selector: aSymbol;
		methodClass: aClassName;
		oop: methodOop;
		yourself
]

{ #category : 'instance creation' }
GbxCompiledMethodHolder class >> selector: aSymbol class: aClassName oop: methodOop session: aSession [
	^ self new
		selector: aSymbol;
		methodClass: aClassName;
		oop: methodOop;
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbxCompiledMethodHolder >> fetchDetailsFromServer [
	"Fetch method details from GemStone"
	| script result parts |
	
	(oop isNil or: [ session isNil ]) ifTrue: [ ^ self ].
	
	script := '[
		| meth stream |
		meth := Object _objectForOop: ', oop asString, '.
		stream := WriteStream on: String new.
		stream
			nextPutAll: meth selector asString; nextPutAll: ''|'';
			nextPutAll: meth inClass name asString; nextPutAll: ''|'';
			nextPutAll: meth category asString; nextPutAll: ''|'';
			nextPutAll: meth source.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	parts := result splitOn: $|.
	parts size >= 4 ifTrue: [
		selector := parts first asSymbol.
		methodClass := parts second.
		category := parts third.
		sourceCode := parts fourth.
	].
]

{ #category : 'accessing' }
GbxCompiledMethodHolder >> oop [
	^ oop
]

{ #category : 'accessing' }
GbxCompiledMethodHolder >> oop: anOop [
	oop := anOop.
	compiledMethod ifNil: [ 
		"Create a proxy from the OOP if we don't have a compiled method"
		session ifNotNil: [
			compiledMethod := session objectFromOop: anOop.
		]
	].
]

{ #category : 'accessing' }
GbxCompiledMethodHolder >> printString [
	^ methodClass, '>>', selector, ' (oop: ', (oop ifNil: [ 'nil' ] ifNotNil: [ oop asString ]), ')'
]
