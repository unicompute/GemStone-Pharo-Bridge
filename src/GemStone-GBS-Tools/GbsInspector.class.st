Class {
	#name : 'GbsInspector',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'oop',
		'classLabel',
		'stateTable',
		'codeEditor',
		'doItButton',
		'printItButton',
		'inspectItButton',
		'evaluationContextOop'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'reflection' }
GbsInspector class >> fetchReflectionStringFor: anOop session: aSession [
	"Sends the reflection script to GemStone and returns the raw formatted string"
	| script |
	script := '[
		| obj stream names childVal childOop |
		obj := Object _objectForOop: ', anOop asString, '.
		stream := WriteStream on: String new.
		names := obj class allInstVarNames.
		1 to: names size do: [ :i |
			childVal := obj instVarAt: i.
			childOop := Reflection oopOf: childVal.
			stream 
				nextPutAll: (names at: i) asString; nextPutAll: ''::::''; 
				nextPutAll: childVal printString; nextPutAll: ''::::'';
				nextPutAll: childOop asString; lf.
		].
		stream contents
	] value'.
	
	^ aSession executeAndFetch: script.
]

{ #category : 'instance creation' }
GbsInspector class >> inspect: anOop session: aSession [
	| inspector |
	inspector := self new.
	inspector inspectOop: anOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'instance creation' }
GbsInspector class >> inspect: anOop session: aSession context: aContextOop [
	| inspector |
	inspector := self new.
	inspector inspectOop: anOop session: aSession context: aContextOop.
	inspector open.
	^ inspector
]

{ #category : 'reflection' }
GbsInspector class >> parseReflectionString: aString [
	"Converts the GemStone string into an Array of { Name . Value . OOP }"
	| items lines parts |
	items := OrderedCollection new.
	
	(aString isNil or: [ aString beginsWith: 'Error:' ]) ifTrue: [ ^ items ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [ 
			parts := line splitOn: '::::'.
			parts size = 3 ifTrue: [ 
				items add: { parts first . parts second . parts third asInteger } 
			]
		]
	].
	^ items asArray
]

{ #category : 'layout' }
GbsInspector >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: classLabel height: 30;
		add: stateTable;
		add: (SpBoxLayout newHorizontal
			add: doItButton;
			add: printItButton;
			add: inspectItButton;
			yourself) height: 30;
		add: codeEditor;
		yourself
]

{ #category : 'initialization' }
GbsInspector >> initializePresenters [
	classLabel := self newLabel.
	stateTable := self newTable.
	codeEditor := self newCode.
	doItButton := self newButton
		label: 'GS-Do it';
		action: [ self gsDoIt ].
	printItButton := self newButton
		label: 'GS-Print it';
		action: [ self gsPrintIt ].
	inspectItButton := self newButton
		label: 'GS-Inspect it';
		action: [ self gsInspectIt ].
	
	stateTable 
		addColumn: (SpStringTableColumn title: 'Variable' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).
]

{ #category : 'initialization' }
GbsInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter 
		title: 'GemStone Live Inspector';
		initialExtent: 450 @ 500.
]

{ #category : 'accessing' }
GbsInspector >> inspectOop: anOop session: aSession [
	self inspectOop: anOop session: aSession context: nil
]

{ #category : 'accessing' }
GbsInspector >> inspectOop: anOop session: aSession context: aContextOop [
	| className printString rawData parsedItems items |
	oop := anOop.
	session := aSession.
	evaluationContextOop := aContextOop.
	
	"1. Get Basic Info"
	className := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') class name asString'.
	classLabel label: 'Remote Class: ', className.
	printString := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') printString'.
	
	"2. Initialize table with 'self'"
	items := OrderedCollection new.
	items add: { 'self' . printString . anOop }.
	
	"3. Fetch and Parse using our GREEN TDD methods!"
	rawData := self class fetchReflectionStringFor: anOop session: session.
	parsedItems := self class parseReflectionString: rawData.
	items addAll: parsedItems.
	
	stateTable items: items.
	
	"4. DOUBLE-CLICK TO DIVE DEEPER!"
	stateTable whenActivatedDo: [ :selection |
		| selectedItem childOop |
		selectedItem := selection selectedItem.
		childOop := selectedItem third. 
		"Only inspect real objects, ignore nil (20)"
		childOop > 20 ifTrue: [ 
			GbsInspector inspect: childOop session: session 
		].
	].
]

{ #category : 'evaluation' }
GbsInspector >> evaluationContextOop [
	((evaluationContextOop isNumber) and: [ evaluationContextOop > 20 ])
		ifTrue: [ ^ evaluationContextOop ].
	^ (session respondsTo: #sessionOop)
		ifTrue: [ session sessionOop ]
		ifFalse: [ 20 ]
]

{ #category : 'evaluation' }
GbsInspector >> evaluateCodeInContext: codeString [
	| contextOop raw |
	(codeString isString and: [ codeString isEmpty not ]) ifFalse: [ ^ nil ].
	session ifNil: [ ^ nil ].
	contextOop := self evaluationContextOop.
	raw := [ session executeAndFetch: codeString context: contextOop ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : 'evaluation' }
GbsInspector >> gsDoIt [
	| code |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ self gsDoIt: code
]

{ #category : 'evaluation' }
GbsInspector >> gsDoIt: codeString [
	| raw |
	raw := self evaluateCodeInContext: codeString.
	^ raw notNil and: [ (raw asString beginsWith: 'Error:') not ]
]

{ #category : 'evaluation' }
GbsInspector >> gsInspectIt [
	| code |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ self gsInspectIt: code
]

{ #category : 'evaluation' }
GbsInspector >> gsInspectIt: codeString [
	| contextOop resultOop |
	session ifNil: [ ^ false ].
	contextOop := self evaluationContextOop.
	resultOop := [
		session serverInterface
			apiGciExecuteStr: codeString
			context: contextOop
			env: 0
	] on: Error do: [ nil ].
	((resultOop isNumber and: [ resultOop > 20 ]) not) ifTrue: [ ^ false ].
	GbsInspector inspect: resultOop session: session context: contextOop.
	^ true
]

{ #category : 'evaluation' }
GbsInspector >> gsPrintIt [
	| code value currentText |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	value := self gsPrintIt: code.
	value ifNil: [ ^ false ].
	currentText := (codeEditor respondsTo: #text)
		ifTrue: [ codeEditor text asString ]
		ifFalse: [ '' ].
	(codeEditor respondsTo: #text:)
		ifTrue: [ codeEditor text: currentText, ' "', value asString, '"' ].
	^ true
]

{ #category : 'evaluation' }
GbsInspector >> gsPrintIt: codeString [
	| script |
	codeString ifNil: [ ^ nil ].
	script := '[ ', codeString, ' ] value printString'.
	^ self evaluateCodeInContext: script
]

{ #category : 'evaluation' }
GbsInspector >> selectedCodeOrAll [
	| fullText |
	codeEditor ifNil: [ ^ '' ].
	fullText := (codeEditor respondsTo: #text)
		ifTrue: [ codeEditor text asString ]
		ifFalse: [ '' ].
	^ fullText
]
