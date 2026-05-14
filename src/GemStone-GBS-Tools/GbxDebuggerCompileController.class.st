Class {
	#name : 'GbxDebuggerCompileController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerCompileController class >> on: aService [
	^ self new
		service: aService;
		yourself
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerCompileController >> acceptTextFrom: textController [
	"Accept/compile text from editor.
	Calls gbxRecompileMethod: for server contexts."
	service currentContext gbxIsServerContext
		ifTrue: [ self gbxRecompileMethod: textController text notifying: textController ]
		ifFalse: [
			"For client contexts, use standard evaluation"
			service evaluateCodeInCurrentFrame: textController text ]
]

{ #category : 'evaluation' }
GbxDebuggerCompileController >> clearCompileError [
	service compileErrorValue: nil
]

{ #category : 'evaluation' }
GbxDebuggerCompileController >> correctCurrentSelectorWithSource: sourceText [
	| raw |
	self clearCompileError.
	raw := self
		remoteCompileResponseForSource: sourceText
		correctingSelector: true.
	raw ifNil: [
		service compileErrorValue: 'Correct selector failed: no response from GemStone'.
		^ false ].
	(raw = 'OK') ifTrue: [ ^ true ].
	service compileErrorValue: (self normalizedCompileErrorFrom: raw).
	^ false
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerCompileController >> gbxRecompileMethod: sourceText notifying: requestor [
	"Recompile the method in the receiver's current stack frame using sourceText.
	Answer true if compilation is successful, otherwise false.
	Displays compiler errors in the requestor (text editor)."
	| gbxMethod method sess result myErrorText error |
	gbxMethod := service selectedMethod.
	gbxMethod ifNil: [ ^ false ].
	method := gbxMethod methodDelegate.
	method ifNil: [ ^ false ].
	sess := method session.
	sess ifNil: [ ^ false ].

	"Check if method class is nil (unbound method)"
	(gbxMethod methodClass = sess oopNil) ifTrue: [
		^ false "Can't recompile unbound method" ].

	"Save old method in case it needs to be restored"
	result := [
		sess unsynchronizedEvaluateBlock: '[:meth :source | meth _recompileWithSource: source]'
			with: method
			with: (sourceText gbxConvertToServerLineDelimiter ifNil: [ sourceText ])
	] on: Error do: [ :ex | ex messageText ].

	"Check for compilation failure"
	result ~~ true & (result ~~ false) ifTrue: [
		"Compilation failed in 32-bit server or error occurred"
		error := result isEmpty ifTrue: [ nil ] ifFalse: [ result at: 1 ].
		myErrorText := error size < 3 ifTrue: [ 'error' ] ifFalse: [ error at: 3 ].
		requestor ifNotNil: [
			(requestor respondsTo: #insertAndSelect:at:) ifTrue: [
				requestor insertAndSelect: myErrorText , '->' at: (error at: 2) ] ].
		^ false ].

	result ifTrue: [
		"Success, same selector - notify method changed"
		service gbxMethodChanged: sourceText.
		^ true ].

	"Changed the method selector on recompilation"
	service scheduleTextUpdate.
	service processEvents.
	^ true
]

{ #category : 'evaluation' }
GbxDebuggerCompileController >> lastCompileError [
	^ service compileErrorValue
]

{ #category : 'evaluation' }
GbxDebuggerCompileController >> normalizedCompileErrorFrom: rawResult [
	| text |
	text := rawResult asString.
	(text beginsWith: 'ERROR|')
		ifTrue: [ ^ (text copyFrom: 7 to: text size) ].
	^ text
]

{ #category : 'evaluation' }
GbxDebuggerCompileController >> recompileCurrentMethodWithSource: sourceText [
	| raw |
	self clearCompileError.
	raw := self
		remoteCompileResponseForSource: sourceText
		correctingSelector: false.
	raw ifNil: [
		service compileErrorValue: 'Compile failed: no response from GemStone'.
		^ false ].
	(raw = 'OK') ifTrue: [ ^ true ].
	service compileErrorValue: (self normalizedCompileErrorFrom: raw).
	^ false
]

{ #category : 'accessing' }
GbxDebuggerCompileController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerCompileController >> service: aService [
	service := aService
]

{ #category : 'private' }
GbxDebuggerCompileController >> remoteCompileLookup [
	| className selector isMeta classLookupName |
	service currentContext ifNil: [ ^ nil ].
	service isSessionUsable ifFalse: [ ^ nil ].
	className := service selectedMethodClassName.
	selector := service selectedMethodSelector.
	(className isNil or: [ selector isNil or: [ selector = #unboundMethod ] ]) ifTrue: [ ^ nil ].

	isMeta := className asString endsWith: ' class'.
	classLookupName := isMeta
		ifTrue: [ className asString allButLast: 6 ]
		ifFalse: [ className asString ].
	^ {
		classLookupName.
		selector asSymbol.
		isMeta }
]

{ #category : 'private' }
GbxDebuggerCompileController >> remoteCompileResponseForSource: sourceText correctingSelector: allowSelectorCorrection [
	| lookup body raw |
	lookup := self remoteCompileLookup.
	lookup ifNil: [ ^ nil ].
	body := '
		| cls oldSel protocol result newSel source |
		cls := System myUserProfile symbolList objectNamed: className asSymbol.
		cls ifNil: [ ^ ''ERROR|Class not found'' ].
		isMeta ifTrue: [ cls := cls class ].
		oldSel := selector.
		source := sourceText.
		protocol := [ cls categoryOfSelector: oldSel ] on: Error do: [ ''as yet unclassified'' ].
		protocol ifNil: [ protocol := ''as yet unclassified'' ].
		result := [ cls compileMethod: source category: protocol ] on: Error do: [ :ex | ''ERROR|'', ex description ].
		(result isString and: [ result beginsWith: ''ERROR|'' ]) ifTrue: [ ^ result ].
		(result isKindOf: Array) ifTrue: [ ^ ''ERROR|Compilation failed'' ].
		allowSelectorCorrection ifTrue: [
			newSel := [ result selector ] on: Error do: [ oldSel ].
			(newSel ~= oldSel and: [ cls includesSelector: oldSel ]) ifTrue: [
				[ cls removeSelector: oldSel ] on: Error do: [ :ex | ] ] ].
		''OK''
	'.
	raw := [
		GbsRemoteExecutionDispatcher
			fetchCommandBody: body
			literalBindings: (Dictionary new
				at: 'allowSelectorCorrection' put: allowSelectorCorrection;
				at: 'className' put: lookup first;
				at: 'isMeta' put: lookup third;
				at: 'selector' put: lookup second;
				at: 'sourceText' put: (sourceText
					ifNil: [ '' ]
					ifNotNil: [ :each | each asString copyReplaceAll: String cr with: String lf ]);
				yourself)
			oopBindings: Dictionary new
			in: service session
			context: service session sessionOop ]
		on: Error
		do: [ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]
