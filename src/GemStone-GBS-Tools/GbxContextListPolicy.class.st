"
GbxContextListPolicy handles context list management for the GemStone remote debugger.

Its main responsibility is assembling the logical stack visible in the debugger.
The logical stack contains contexts from GemStone server execution as well as 
client Smalltalk execution. It follows a logical thread of execution that may 
pass from the client to the server in an execute, remotePerform, or forwarder send, 
and may pass back to the client in a clientForwarder send, and so on back and forth.

Usually, the user of the debugger doesn't want to see the ""glue"" code used by 
GBS to implement sends between client and server, so GbxContextListPolicy omits 
these glue contexts from its logical stack. For tough debugging scenarios, however, 
the user can choose to show the glue and see the entire true stack.

Based on VisualWorks GbxContextListPolicy class.
"
Class {
	#name : 'GbxContextListPolicy',
	#superclass : 'Object',
	#instVars : [
		'glueIsHidden',
		'contextList',
		'serverCallContext',
		'debugger'
	],
	#classVars : [
		'GlueIsHiddenDefault'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'class initialization' }
GbxContextListPolicy class >> initialize [
	GlueIsHiddenDefault := true
]

{ #category : 'instance creation' }
GbxContextListPolicy class >> debugger: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'initialization' }
GbxContextListPolicy >> debugger: aDebugger [
	debugger := aDebugger.
	glueIsHidden := GlueIsHiddenDefault
]

{ #category : 'accessing' }
GbxContextListPolicy >> glueIsHidden [
	^ glueIsHidden
]

{ #category : 'accessing' }
GbxContextListPolicy >> glueIsHidden: aBoolean [
	glueIsHidden := aBoolean
]

{ #category : 'context list' }
GbxContextListPolicy >> contextList [
	^ contextList ifNil: [ #( ) ]
]

{ #category : 'context list' }
GbxContextListPolicy >> computeContextList [
	"Compute the logical context list from the GemStone process"
	| allContexts |
	
	allContexts := self fetchServerContexts.
	
	glueIsHidden 
		ifTrue: [ contextList := self filterOutGlue: allContexts ]
		ifFalse: [ contextList := allContexts ].
	
	^ contextList
]

{ #category : 'context list' }
GbxContextListPolicy >> fetchServerContexts [
	"Fetch all server contexts from GemStone"
	| processOop script rawData contexts |
	
	processOop := debugger processOop.
	(processOop isNil or: [ processOop = 20 ]) ifTrue: [ ^ #( ) ].
	
	script := '[
		| proc stream |
		proc := Object _objectForOop: ', processOop asString, '.
		stream := WriteStream on: String new.
		proc ifNotNil: [
			1 to: (proc stackDepth min: 50) do: [ :level |
				| frameId fullEntry methodOrNil selector className |
				frameId := proc _gsiStackReportFromLevel: level toLevel: level.
				frameId ifNotNil: [
					fullEntry := frameId first.
					fullEntry ifNotNil: [
						methodOrNil := fullEntry first.
						selector := fullEntry size >= 4 ifTrue: [ fullEntry at: 4 ] ifFalse: [ nil ].
						className := methodOrNil ifNotNil: [ 
							methodOrNil inClass ifNotNil: [ methodOrNil inClass name ] 
						] ifNil: [ nil ].
						stream 
							nextPutAll: level asString; tab;
							nextPutAll: (className ifNil: [ ''<unknown>'' ] ifNotNil: [ className ]); tab;
							nextPutAll: (selector ifNil: [ ''<unknown>'' ] ifNotNil: [ selector asString ]);
							lf.
					].
				].
			]
		].
		stream contents
	] value'.
	
	rawData := [ debugger session evaluate: script ] on: Error do: [ nil ].
	(rawData respondsTo: #asLocalString) ifTrue: [ rawData := rawData asLocalString ].
	rawData ifNil: [ rawData := '' ].
	rawData = 'nil' ifTrue: [ rawData := '' ].
	contexts := (rawData splitOn: Character lf) 
		collect: [ :line | 
			| parts |
			parts := line splitOn: Character tab.
			parts size >= 3 ifTrue: [
				GbxActivation new
					level: (parts first asInteger);
					session: debugger session;
					processOop: processOop;
					gsMethodId: (parts at: 2);
					selector: (parts at: 3) asSymbol;
					yourself
			]
		] thenSelect: #isNotNil.
	
	^ contexts
]

{ #category : 'context list' }
GbxContextListPolicy >> filterOutGlue: contexts [
	"Filter out GBS glue contexts from the context list"
	| filtered |
	filtered := contexts select: [ :ctx | 
		self isGlueContext: ctx not
	].
	^ filtered
]

{ #category : 'testing' }
GbxContextListPolicy >> isGlueContext: aContext [
	"Check if a context is GBS glue code"
	| className selector |
	className := aContext methodClass ifNil: [ ^ false ].
	selector := aContext selector ifNil: [ ^ false ].
	
	"GBS glue classes"
	(className beginsWith: 'Gbs') ifTrue: [ ^ true ].
	(className beginsWith: 'Gbx') ifTrue: [ 
		"Some Gbx classes are glue, some are not"
		#( #apiGciExecuteStr:context:env: #gciExecute:context:env: #execute: #evaluate: ) 
			includes: selector 
			ifTrue: [ ^ true ]
	].
	
	^ false
]

{ #category : 'context list' }
GbxContextListPolicy >> topServerContext [
	"Return the topmost server context"
	| list |
	list := self contextList.
	^ list ifEmpty: [ nil ] ifNotEmpty: [ list first ]
]

{ #category : 'context list' }
GbxContextListPolicy >> firstClientContextAbove: gsContext [
	"Find the first client context above a server context"
	"Currently not implemented - would need client stack integration"
	^ nil
]

{ #category : 'context list' }
GbxContextListPolicy >> isHiddenGlue: aContext [
	"Check if a context should be hidden as glue"
	^ glueIsHidden and: [ self isGlueContext: aContext ]
]

{ #category : 'context list' }
GbxContextListPolicy >> updateContextList [
	"Update the context list and notify the debugger"
	self computeContextList.
	debugger updateStackList: self contextList
]
