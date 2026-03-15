Class {
	#name : 'GbxStackInspector',
	#superclass : 'GbxContextInspector',
	#instVars : [
		'processOop',
		'stackList',
		'selectedFieldName'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStackInspector class >> inspectStackOfProcess: processOop session: aSession [
	"Inspect the stack of a GemStone process"
	| inspector |
	
	inspector := self new.
	inspector inspectProcess: processOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'accessing' }
GbxStackInspector >> inspectProcess: aProcessOop session: aSession [
	| stackData items |
	
	processOop := aProcessOop.
	session := aSession.
	
	classLabel label: 'Stack for Process: ', aProcessOop asString.
	
	"Fetch stack frames"
	stackData := self fetchStackFrames.
	
	"Build items list"
	items := OrderedCollection new.
	stackData doWithIndex: [ :frame :index |
		items add: { 
			'Frame ', index asString. 
			frame at: 1.  "description"
			frame at: 2.  "contextOop"
		}
	].
	
	stateTable items: items.
	
	"Double-click to inspect context"
	stateTable whenActivatedDo: [ :selection |
		| selectedItem contextOop |
		selectedItem := selection selectedItem.
		contextOop := selectedItem third.
		contextOop ifNotNil: [
			GbxContextInspector inspectContext: contextOop session: session
		].
	].
]

{ #category : 'fetching' }
GbxStackInspector >> fetchStackFrames [
	"Fetch stack frames from the server process"
	| script result |
	
	script := '[
		| proc stream level stackReport fullEntry methodOrNil className selectorName ctxOop |
		proc := Object _objectForOop: ', processOop asString, '.
		stream := WriteStream on: String new.
		level := 1.
		[ level <= 50 ] whileTrue: [
			stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
			(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
				ifFalse: [ level := 51 ]
				ifTrue: [
					fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
					fullEntry ifNotNil: [
						methodOrNil := ((fullEntry respondsTo: #at:) and: [ fullEntry size >= 1 ])
							ifTrue: [ [ fullEntry at: 1 ] on: Error do: [ nil ] ]
							ifFalse: [ nil ].
						className := [ methodOrNil ifNil: [ ''<unknown>'' ] ifNotNil: [ methodOrNil inClass name ] ] on: Error do: [ ''<unknown>'' ].
						selectorName := [ (fullEntry at: 4) ifNil: [ ''<unknown>'' ] ifNotNil: [ :s | s asString ] ] on: Error do: [ ''<unknown>'' ].
						ctxOop := [ Reflection oopOf: proc ] on: Error do: [ ''0'' ].
						stream
							nextPutAll: className; nextPutAll: ''>>''; nextPutAll: selectorName;
							nextPutAll: ''::::'';
							nextPutAll: ctxOop asString;
							lf
					]
				].
			level := level + 1
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	^ self parseStackFrames: result
]

{ #category : 'fetching' }
GbxStackInspector >> parseStackFrames: aString [
	"Parse stack frame string into array of { description . contextOop }"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: '::::'.
			parts size >= 2 ifTrue: [
				items add: { 
					parts first. 
					(parts second asInteger > 20) ifTrue: [ parts second asInteger ] ifFalse: [ nil ]
				}
			]
		]
	].
	^ items asArray
]

{ #category : 'initialization' }
GbxStackInspector >> initializePresenters [
	super initializePresenters.
	
	"Remove code editor for stack inspector - read-only"
	codeEditor ifNotNil: [
		codeEditor beReadOnly.
	].
]

{ #category : 'initialization' }
GbxStackInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Stack Inspector';
		initialExtent: 500 @ 600.
]
