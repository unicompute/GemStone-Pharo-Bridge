Class {
	#name : 'GbsRemoteDebuggerSourceResolver',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerSourceResolver class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourceResolver >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourceResolver >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'fetching' }
GbsRemoteDebuggerSourceResolver >> fetchFullSourceFor: aContext [
	| session processOop ctxProcessOop levelValue script raw |
	aContext ifNil: [ ^ '' ].
	session := debugger session.
	session ifNil: [ ^ '' ].
	processOop := debugger processOop.
	levelValue := (aContext respondsTo: #level)
		ifTrue: [ aContext level ifNil: [ 0 ] ]
		ifFalse: [ 0 ].
	levelValue <= 0 ifTrue: [ ^ '' ].
	ctxProcessOop := (aContext respondsTo: #processOop)
		ifTrue: [ aContext processOop ]
		ifFalse: [ processOop ].
	(ctxProcessOop isNil or: [ ctxProcessOop = 0 ]) ifTrue: [ ^ '' ].

	script := '[
		| obj stackReport fullEntry src ctx i |
		obj := Object _objectForOop: ', ctxProcessOop asString, '.
		obj ifNil: [ ^ '''' ].
		stackReport := [ obj _gsiStackReportFromLevel: ', levelValue asString, ' toLevel: ', levelValue asString, ' ] on: Error do: [ nil ].
		src := ''''.
		(stackReport notNil and: [ stackReport size >= 2 ]) ifTrue: [
			fullEntry := stackReport at: 2.
			(fullEntry notNil and: [ fullEntry size >= 9 ]) ifTrue: [
				src := [ fullEntry at: 9 ] on: Error do: [ '''' ].
				src ifNil: [ src := '''' ].
				src := src asString.
			]
		].

		"Fallback for do-it frames where stack report source can be truncated."
		((src includes: Character lf) not) ifTrue: [
			ctx := nil.
			(obj respondsTo: #topContext)
				ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
			(ctx isNil and: [ obj respondsTo: #sender ])
				ifTrue: [ ctx := obj ].
			ctx ifNotNil: [
				i := 1.
				[ i < ', levelValue asString, ' and: [ ctx notNil ] ] whileTrue: [
					ctx := [ ctx sender ] on: Error do: [ nil ].
					i := i + 1
				].
				ctx ifNotNil: [
					src := [ ctx sourceCode ] on: Error do: [ src ].
					src ifNil: [ src := '''' ].
					src := src asString.
				]
			]
		].

		src isEmpty ifTrue: [ ^ '''' ].
		src := src
			copyReplaceAll: String cr with: ''<CR>'';
			copyReplaceAll: String lf with: ''<LF>'';
			copyReplaceAll: Character tab asString with: ''<TAB>''.
		src
	] value'.

	raw := [ session evaluate: script ] on: Error do: [ '' ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	raw ifNil: [ ^ '' ].
	^ ((raw copyReplaceAll: '<TAB>' with: Character tab asString)
		copyReplaceAll: '<CR>' with: String cr;
		copyReplaceAll: '<LF>' with: String lf)
]
