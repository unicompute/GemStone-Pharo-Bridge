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
	"Fetch server activations using the VW flow:
	serverCall/error oop -> gbsError -> serverProcess -> stack report."
	| processOop script rawData contexts |
	
	processOop := debugger processOop.
	(processOop isNil or: [ processOop = 20 ]) ifTrue: [ ^ #( ) ].
	
	script := '[
		| obj gbsError gsProcess ctx stream maxDepth level stackReport fullEntry frameId methodOrNil className selectorName source ctxOop |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ '''' ].
		stream := WriteStream on: String new.
		gbsError := nil.
		gsProcess := nil.
		ctx := nil.

		(obj respondsTo: #serverProcess) ifTrue: [ gbsError := obj ].
		gbsError isNil ifTrue: [
			(obj respondsTo: #gbxResult)
				ifTrue: [ gbsError := [ obj gbxResult ] on: Error do: [ nil ] ]
		].
		gbsError notNil ifTrue: [
			gsProcess := [ gbsError serverProcess ] on: Error do: [ nil ]
		].
		gsProcess isNil ifTrue: [
			(obj respondsTo: #_gsiStackReportFromLevel:toLevel:)
				ifTrue: [ gsProcess := obj ]
		].
		gsProcess isNil ifTrue: [
			(obj respondsTo: #process)
				ifTrue: [ gsProcess := [ obj process ] on: Error do: [ nil ] ]
		].
		(gsProcess isNil and: [ obj respondsTo: #topContext ]) ifTrue: [
			ctx := [ obj topContext ] on: Error do: [ nil ].
			(ctx notNil and: [ ctx respondsTo: #process ])
				ifTrue: [ gsProcess := [ ctx process ] on: Error do: [ nil ] ]
		].

		((gsProcess notNil) and: [ gsProcess respondsTo: #_gsiStackReportFromLevel:toLevel: ]) ifTrue: [
			maxDepth := 200.
			level := 1.
			[ level <= maxDepth ] whileTrue: [
				stackReport := [ gsProcess _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
				(stackReport isNil or: [ stackReport size < 2 ])
					ifTrue: [ level := maxDepth + 1 ]
					ifFalse: [
						frameId := stackReport at: 1.
						fullEntry := stackReport at: 2.
						methodOrNil := (fullEntry notNil and: [ fullEntry isEmpty not ])
							ifTrue: [ fullEntry first ]
							ifFalse: [ nil ].
						className := [
							methodOrNil ifNil: [ ''<unknown>'' ] ifNotNil: [
								methodOrNil inClass ifNil: [ ''<unknown>'' ] ifNotNil: [ methodOrNil inClass name ]
							]
						] on: Error do: [ ''<unknown>'' ].
						selectorName := [
							(fullEntry notNil and: [ fullEntry size >= 4 ])
								ifTrue: [
									(fullEntry at: 4)
										ifNil: [ ''<unknown>'' ]
										ifNotNil: [ :sel | sel asString ]
								]
								ifFalse: [ ''<unknown>'' ]
						] on: Error do: [ ''<unknown>'' ].
						source := [
							(fullEntry notNil and: [ fullEntry size >= 9 ])
								ifTrue: [
									(fullEntry at: 9)
										ifNil: [ '''' ]
										ifNotNil: [ :src | src asString ]
								]
								ifFalse: [ '''' ]
						] on: Error do: [ '''' ].
						source := source
							copyReplaceAll: String cr with: '' '';
							copyReplaceAll: String lf with: '' '';
							copyReplaceAll: Character tab asString with: '' ''.
						ctxOop := [ frameId asString ] on: Error do: [ ''0'' ].
						stream
							nextPutAll: level asString; tab;
							nextPutAll: className; tab;
							nextPutAll: selectorName; tab;
							nextPutAll: source; tab;
							nextPutAll: ctxOop;
							lf.
						level := level + 1
					]
			]
		].

		"Fallback: sender-chain walk when stack report is unavailable."
		stream position = 0 ifTrue: [
			ctx isNil ifTrue: [
				(obj respondsTo: #sender) ifTrue: [ ctx := obj ].
				(ctx isNil and: [ gsProcess notNil and: [ gsProcess respondsTo: #topContext ] ])
					ifTrue: [ ctx := [ gsProcess topContext ] on: Error do: [ nil ] ]
			].
			maxDepth := 200.
			level := 1.
			[ ctx notNil and: [ level <= maxDepth ] ] whileTrue: [
				className := [ ctx method inClass name ] on: Error do: [ ''<unknown>'' ].
				selectorName := [ ctx selector asString ] on: Error do: [ ''<unknown>'' ].
				source := [ ctx sourceCode ] on: Error do: [ '''' ].
				source := source ifNil: [ '''' ].
				source := source
					copyReplaceAll: String cr with: '' '';
					copyReplaceAll: String lf with: '' '';
					copyReplaceAll: Character tab asString with: '' ''.
				ctxOop := [ ctx asOop printString ] on: Error do: [ ''0'' ].
				stream
					nextPutAll: level asString; tab;
					nextPutAll: className; tab;
					nextPutAll: selectorName; tab;
					nextPutAll: source; tab;
					nextPutAll: ctxOop;
					lf.
				ctx := [ ctx sender ] on: Error do: [ nil ].
				level := level + 1
			]
		].
		stream contents
	] value'.
	
	rawData := [ debugger session evaluate: script ] on: Error do: [ nil ].
	(rawData respondsTo: #asLocalString) ifTrue: [ rawData := rawData asLocalString ].
	rawData ifNil: [ rawData := '' ].
	rawData = 'nil' ifTrue: [ rawData := '' ].
	rawData isEmpty ifTrue: [
		Transcript
			show: 'fetchServerContexts: empty stack data for processOop=';
			show: processOop asString;
			cr
	].
	contexts := (rawData splitOn: Character lf) 
		collect: [ :line | 
			| parts |
			parts := line splitOn: Character tab.
			parts size >= 5 ifTrue: [
				| activation selectorSymbol ctxOop |
				selectorSymbol := [ (parts at: 3) asSymbol ] on: Error do: [ #unboundMethod ].
				ctxOop := [ (parts at: 5) asInteger ] on: Error do: [ processOop ].
				activation := GbxActivation new.
				activation
					session: debugger session;
					level: ([ parts first asInteger ] on: Error do: [ 1 ]);
					initializeFromClass: (parts at: 2)
						selector: selectorSymbol
						source: (parts at: 4)
						contextOop: ctxOop;
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
		(self isGlueContext: ctx) not
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
		(#( #apiGciExecuteStr:context:env: #gciExecute:context:env: #execute: #evaluate: )
			includes: selector)
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
