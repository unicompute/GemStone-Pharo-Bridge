Extension { #name : 'DebuggerService' }

{ #category : '*GbsToolsOverrides-Extensions' }
DebuggerService >> text
[
	| theText meth |
	currentContext isNil
		ifTrue: [^Text new].
	^[theText := currentContext sourceCode asText.
	currentContext method homeMethod usuallyHasSelector
		ifTrue: 
			[self makeSelectorOf: theText boldIn: currentContext	"<<<GemStone change here"].
	(meth := self selectedMethod) isProbed
		ifTrue: [meth highlightProbesIn: theText].
	theText] 
		on: MethodDictionary keyNotFoundSignal
		do:  [:ex |
			((#noSourceCodeFor1s << #pdp >> 'no source code for <1s>')
			expandMacrosWith: currentContext printString) asText emphasizeAllWith: #italic;
				yourself].
]

{ #category : '*GbsToolsOverrides-Extensions' }
DebuggerService class >> openContext: haltContext label: aString proceedable: aBoolean interrupted: interrupted
[
	"Create and schedule an instance of me viewing a Debugger on haltContext.
	The view will be labeled with aString, and will show a short sender stack."
	
	"GbxDebuggerService redefines this method and changes it internally. 
	However, we want to know if the VisualWorks version ever changes so
	GBS can make similar changes. Therefore, we override this method and
	hope our 'base greater than override' detection scheme notifies us."

	| displayPoint contentsString dbr |
	self prepareForDebugging.
	contentsString := self shortStackFor: haltContext ofSize: 5.
	displayPoint := self getDisplayPoint.
	thisContext unwindDebuggerSupportUpTo: haltContext.
	dbr := self context: haltContext proceedable: aBoolean interrupted: interrupted.
	Processor activeProcess
		suspendResumable: false
		do: [:proc |
			self openDebugger: dbr
				contents: contentsString
				label: aString
				proceed: aBoolean
				displayAt: displayPoint.
			self enableWindowsIfNotEventFaithfulFor: proc].
]

{ #category : '*GbsToolsOverrides-Extensions' }
DebuggerService class >> logErrorFor: aDebugger label: label
[
	"Overridden in GbsPDPDebug package so we can 
	use the GbxContextDumpPolicy. Without this change, 
	stack frames that included GbxActivations would give
	errors."
	"Log the error to a file in case the notifier can't come up."
	"If you want to enable logging of notifiers, change the first 'false'
	to 'true', which will cause logging to be enabled.  Then edit the
	file name (the default is 'visual.err') to whatever file you want to
	write the logs to.  Make sure that the file is writable, and that
	there is enough disk space.  If there is any error writing the log
	file, the error will be silently ignored--otherwise the system would
	go into infinite recursion and run out of memory."
	| end printSymbol |
	false
		ifFalse: [^self].
	end := 10.	"Number of stack items to be dumped.  Set to nil to dump full stack."
"	printSymbol := #printSimple."
	printSymbol := #printVerbose. 

	[| file cp |
	file := 'visual.err' asFilename appendStream.
	[file cr; cr.
	cp := GbxContextDumpPolicy new initialize.
	cp stream: file.
	cp errorMessage: label.
	cp stack: aDebugger contextList	.
	cp numberToDump: end.
	cp perform: printSymbol.
	file cr]
		ensure: [file close]
	]
		on: Object errorSignal
		do: [:ex | ex inspect. ex return].
]

