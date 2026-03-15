Class {
	#name : 'GbxMethodHolder',
	#superclass : 'GbxDelegate',
	#instVars : [
		'selector',
		'methodClass',
		'category',
		'sourceCode',
		'compiledMethod',
		'session'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxMethodHolder class >> selector: aSymbol class: aClassName [
	^ self new
		selector: aSymbol;
		methodClass: aClassName;
		yourself
]

{ #category : 'instance creation' }
GbxMethodHolder class >> selector: aSymbol class: aClassName source: aString [
	^ self new
		selector: aSymbol;
		methodClass: aClassName;
		sourceCode: aString;
		yourself
]

{ #category : 'instance creation' }
GbxMethodHolder class >> selector: aSymbol class: aClassName source: aString category: aCategory [
	^ self new
		selector: aSymbol;
		methodClass: aClassName;
		sourceCode: aString;
		category: aCategory;
		yourself
]

{ #category : 'comparing' }
GbxMethodHolder >> = anObject [
	^ (anObject isKindOf: GbxMethodHolder)
		and: [ selector = anObject selector
		and: [ methodClass = anObject methodClass ] ]
]

{ #category : 'accessing' }
GbxMethodHolder >> asString [
	^ methodClass, '>>', selector
]

{ #category : 'accessing' }
GbxMethodHolder >> category [
	^ category
]

{ #category : 'accessing' }
GbxMethodHolder >> category: aString [
	category := aString
]

{ #category : 'accessing' }
GbxMethodHolder >> compiledMethod [
	^ compiledMethod
]

{ #category : 'accessing' }
GbxMethodHolder >> compiledMethod: aMethod [
	compiledMethod := aMethod
]

{ #category : 'accessing' }
GbxMethodHolder >> fetchSourceFromServer [
	"Fetch method source code from GemStone"
	| script |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| cls meth |
		cls := Object _objectForOop: ', methodClass oop asString, '.
		meth := cls compiledMethodAt: #', selector, ' ifAbsent: [ nil ].
		meth ifNil: [ '''' ] ifNotNil: [ meth source ]
	] value'.
	
	sourceCode := session executeAndFetch: script.
]

{ #category : 'accessing' }
GbxMethodHolder >> hash [
	^ selector hash bitXor: methodClass hash
]

{ #category : 'accessing' }
GbxMethodHolder >> isCompiledMethod [
	^ true
]

{ #category : 'accessing' }
GbxMethodHolder >> methodClass [
	^ methodClass
]

{ #category : 'accessing' }
GbxMethodHolder >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
GbxMethodHolder >> printString [
	^ methodClass, '>>', selector
]

{ #category : 'accessing' }
GbxMethodHolder >> selector [
	^ selector
]

{ #category : 'accessing' }
GbxMethodHolder >> selector: aSymbol [
	selector := aSymbol
]

{ #category : 'accessing' }
GbxMethodHolder >> session [
	^ session
]

{ #category : 'accessing' }
GbxMethodHolder >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxMethodHolder >> sourceCode [
	^ sourceCode ifNil: [ 
		self fetchSourceFromServer.
		sourceCode 
	]
]

{ #category : 'accessing' }
GbxMethodHolder >> sourceCode: aString [
	sourceCode := aString
]
