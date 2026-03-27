Extension { #name : 'SourceCodeEditor' }

{ #category : '*GbsToolsOverrides-Extensions' }
SourceCodeEditor >> compileExpressionBetween: start and: stop reason: aReason retry: aRetryBlock
[
	"Compile an expression between start..stop.
	compile into the doItReceiver's class, which could not be the same as doItReceiverClass,
	when evaluating code in the RB. Then the doItReceiver is the selected class, which is also doItReceiverClass.
	In such a case it would not be possible evaluate an expression in the RB, it raise a primitiveFailed error"

	| previousParseTree |
	previousParseTree := parseTree.
	^[
		self
			compileBetween: start
			and: stop
			reason: aReason
			retry: aRetryBlock
			isMethod: false
			postCompilationDo: self evaluationPragmas
			doItContext: self doItContext
			class: (GemStone.Gbs.GbxReflection classOf: self doItReceiver)
	] ensure: [
		self isWorkspace ifFalse: [parseTree := previousParseTree]]
]

{ #category : '*GbsToolsOverrides-Extensions' }
SourceCodeEditor >> defaultParserClass
[
	"extended so that if the default parser is chosen, we use the Gbs variant
	which extends squiggly braces, - see RBParser>>parsePrimitiveObject"

	| cls |
	cls := (self class class canUnderstand: #defaultParsers)
				ifTrue: [self class defaultParsers at: self language ifAbsent: [RBParser]]
				ifFalse: 
					[self languageServices
						language: self language
						category: #parserClass
						ifAbsent: [RBParser]].
	^cls == RBParser ifTrue: [GemStone.Gbs.GbxRBParser] ifFalse: [cls]
]

