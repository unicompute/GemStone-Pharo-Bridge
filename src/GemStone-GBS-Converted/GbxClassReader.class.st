Class {
	#name : 'GbxClassReader',
	#superclass : 'Object',
	#instVars : [
		'lineNumber',
		'lastResult',
		'currentTokens',
		'currentMessages',
		'currentCategory',
		'currentClass',
		'inputStream',
		'session'
	],
	#classVars : [
		'Bytes',
		'KnownTokens',
		'NSC',
		'OCharacter',
		'OInteger',
		'OSmallInteger',
		'OSystem',
		'Pointers',
		'SetSubcommandHandlers',
		'Special'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxClassReader >> session: anObject
[

	session := anObject
]

{ #category : 'error handling' }
GbxClassReader >> error: anError
[

	"This method displays a file-in error box to let the user know that file-in has been terminated."

	^self gbsMessenger
		error: 'Error %1 during file-in at or near line %2'
		with: anError
		with: (lineNumber printString gbxCopyWrappedTo: 40)
]

{ #category : 'error handling' }
GbxClassReader >> error
[

	"This is the generic file-in error handler."

	^self error: 'Unsupported or unrecognized command found'
]

{ #category : 'error handling' }
GbxClassReader >> performObject: sourceObj at: index put: valueObj
[
	"This actually performs the object command using the arguments
	 we parsed out of the command line."

	| impl byteVal |
	sourceObj isGSObject
		ifFalse: 
			[self error: 'Cannot use OBJECT on a non-GSObject'.
			^#error].
	impl := sourceObj fetchImplementation.
	"If the valueObject is nil, the operation is equivalent to sourceObj at: index"
	valueObj = self session oopNil
		ifTrue: 
			[impl = Special
				ifTrue: 
					[self error: 'Cannot index special implementation objects'.
					^#error].
			impl = Bytes ifTrue: [^sourceObj fetchCharAt: index].
			(impl = NSC or: [impl = Pointers]) ifTrue: [^sourceObj fetchOOPAt: index].
			self error: 'Invalid object implementation type'.
			^#error].
	"If the valueObject is not nil, the operation is equivalent to sourceObj at: index put: valueObj"
	impl = Special
		ifTrue: 
			[self error: 'Cannot index special implementation objects'.
			^#error].
	impl = Bytes
		ifTrue: 
			[(valueObj performOnGsServer: #isKindOf:
				withArguments: (Array with: OSmallInteger))
					ifTrue: 
						[byteVal := valueObj asLocalObject.
						(byteVal < 0 or: [byteVal > 255])
							ifFalse: 
								[sourceObj storeByte: byteVal asCharacter at: index.
								^sourceObj].
						self error: 'Byte value out of range'.
						^#error].
			(valueObj performOnGsServer: #isKindOf:
				withArguments: (Array with: OCharacter))
					ifTrue: [sourceObj storeChar: valueObj asLocalObject at: index]
					ifFalse: [sourceObj remotePerform: #insert:at: with: valueObj with: index].
			^sourceObj].
	impl = Pointers
		ifTrue: 
			[sourceObj storeOOP: valueObj at: index.
			^sourceObj].
	impl = NSC
		ifTrue: 
			[self error: 'Cannot store into NSCs'.
			^#error].
	self error: 'Invalid object implementation type'.
	^#error
]

{ #category : 'private' }
GbxClassReader >> parseGemStoneSource
[

	"This method is used to parse the inputStream from the current
	 position of the stream to either the end of the stream or a line
	 beginning with '%'.  The resulting string object is returned."

	| lf aLine source |

	"Initialize"
	source := String new.
	lf := String with: (10 asCharacter).

	"Build source string, reading from the stream until % or end."
	[	aLine := (self nextLineReadingCommand: false) , lf.
		(aLine at: 1) = $% ifFalse: [
			source := source, aLine ].
		(self atEnd) or: [ (aLine at: 1) = $% ]]
	whileFalse: [ ].

	^source gbxLfsOnly
]

{ #category : 'private' }
GbxClassReader >> parseLine: aLine
[
	"This method takes the given line and parses it.  Tokens are
	 stored in 'currentTokens' and the messages that those tokens
	 represent are in 'currentMessages'."
	
	currentTokens := aLine gbxSubstrings.
	currentMessages := currentTokens
		collect:
			[:token | 
			KnownTokens
				at: token asLowercase
				ifAbsent: [#error]]
]

{ #category : 'private' }
GbxClassReader >> printObjectResult: anObject
[

	"This prints the result of an OBJECT command"

	self gbsMessenger
		comment: '---------- result of ''object'' command ---------- \%1\------------------------------------------------'
		with: (
			anObject isGSObject
			ifTrue: [ anObject remoteDescription ]
			ifFalse: [ anObject ]
		).
]

{ #category : 'private' }
GbxClassReader >> verifyClassName
[
	"This method aids method compilation by taking the second token and checking the name for existence in the user's symbol list.  If there is no 2nd token, then we return currentClass (if it is something other than ONil).  If there is a 2nd token, then we check to see if the object is a class defining object.  Errors are produced for object-not-found and non-class defining object situations.  In case of success, return the class defining object.  In case of error, return ONil.  As a side effect, we set the currentClass to the new class defining object."

	| classSymbol classObj |
	currentTokens size = 1
		ifTrue: 
			[currentClass = self session oopNil
				ifFalse: [^currentClass]
				ifTrue: 
					[self error: 'A class was not specified for the current operation, ' , (currentTokens at: 1).
					^self session oopNil]].
	classSymbol := (currentTokens at: 2) asSymbol.
	classObj := self session
				executeBlock: '
[:symbol |
| assoc probableClass |
assoc := GsSession currentSession resolveSymbol: symbol.
assoc == nil
	ifTrue: [nil]
	ifFalse: 
		[probableClass := assoc value.
		(probableClass isBehavior and: [probableClass isMeta not])
			ifTrue: [probableClass]
			ifFalse: [false]]]'
				with: classSymbol
				context: nil.
	classObj = self session oopNil
		ifTrue: 
			[self error: 'The specified class, ' , classSymbol , ', does not exist'.
			^self session oopNil].
	classObj = self session oopFalse
		ifTrue: 
			[self error: 'The specified class, ' , classSymbol , ', is not a class'.
			^self session oopNil].

	"If the current class changed, change display the new class name"
	currentClass = classObj
		ifFalse: 
			[currentClass := classObj.
			self gbsMessenger comment: 'Current class is %1.' with: classSymbol].
	^classObj
]

{ #category : 'private' }
GbxClassReader >> currentCategory: aString
[
	currentCategory := aString
]

{ #category : 'private' }
GbxClassReader >> genericExecution
[
	"This method will do executions for the RUN and OPAL commands.  It sets up an error block and does the execution until it returns successfully.  Users may bail out at any time (via notifiers).  As a by-product, if execution returns successfully, we store the result in 'lastResult' so we can use the '**' operator in OBJECT commands."
	
	| source |
	"Get the GemStoneObject for the text we will execute"
	source := self parseGemStoneSource.	"Now try to execute the text.  If we get a compiler error, we are allowed to correct it."
	[lastResult := self session execute: source]
		on: GbsCompilerError
		do:
			[:ex | | errorDescriptor |
			errorDescriptor := (ex originator arguments at: 1) asLocalObject.
			source := self
				handleCompilerError: errorDescriptor
				inSource: source.
			source isNil
				ifTrue: [ex return: nil]
				ifFalse: [ex retry]]
]

{ #category : 'private' }
GbxClassReader >> getInteger: aString
[
	"This method will convert the given string into an Integer.
	 If we cannot convert the string directly into an Integer, an
	 attempt is made to lookup the string in the user's symbol
	 list and see if that is an Integer.  In case of error, we notify
	 the user and return #error."

	| returnVal anAssoc |
	returnVal := aString asInteger.
	returnVal printString = aString
		ifFalse: 
			[anAssoc := (OSystem remotePerform: #myUserProfile) remotePerform: #resolveSymbol: with: aString asSymbol.
			anAssoc = self session oopNil
				ifTrue: 
					[self error: 'The specified value was not an Integer'.
					^#error].
			returnVal := anAssoc remotePerform: #value.
			(returnVal performOnGsServer: #isKindOf: withArguments: (Array with: OInteger))
				ifTrue: [^returnVal asLocalObject]
				ifFalse: 
					[self error: 'The specified value was not an Integer'.
					^#error]].
	^returnVal
]

{ #category : 'private' }
GbxClassReader >> currentClass: aClassObject
[
	currentClass := aClassObject
]

{ #category : 'private' }
GbxClassReader >> compileMethod
[
	"This method will compile a GemStone instance or class method.  currentTokens should have at least 2 tokens, the 2nd of which is the class name in which to compile the method."
	
	| methodSource |
	"Get the class object and method source"
	self verifyClassName.
	methodSource := self parseGemStoneSource.	"Now compile until the user gets a successful compilation"
	[(currentMessages at: 1) = #method
		ifTrue:
			[self session compileInstMethod: methodSource forClass: currentClass
				inMethodCategory: currentCategory]
		ifFalse:
			[self session compileClassMethod: methodSource forClass: currentClass
				inMethodCategory: currentCategory]]
		on: GbsCompilerError
		do:
			[:ex | 
			methodSource := self
				handleCompilerError: ex errorDescriptor
				inSource: methodSource.
			methodSource isNil
				ifTrue: [ex return: nil]
				ifFalse: [ex retry]]
]

{ #category : 'private' }
GbxClassReader >> getObjectSpec: aString 
[
	"Using the given string, return the OOP of the string interpreted
	 as an object specification.  Objects may be specified in the
	 following manner:

		 @<integer>     a signed 32-bit decimal OOP
		 <integer>      a 31-bit literal SmallInteger
		 <float>        a Float object
		 $<character>   a literal Character
		 'text'         a literal String
		 #text          a literal Symbol
		 **             the result of the last execution"

	"Do easy cases first"

	| anInt aNumber anAssoc |
	self gbxFixMe.	"This method is not covered by tests -- it was referring to GbsObject."
	aString size = 0 
		ifTrue: 
			[self error: 'Invalid object specification'.
			^#error].
	(aString at: 1) = $@ 
		ifTrue: 
			[aString size < 2 
				ifTrue: 
					[self error: 'Invalid object specification'.
					^#error].
			anInt := self getInteger: (aString copyFrom: 2 to: aString size).
			(anInt < 0 or: [anInt > 16rFFFFFFFFFF]) 
				ifTrue: 
					[self error: 'Specified OOP out of range'.
					^#error].
			^GbxDelegate oopValue: anInt session: self session].
	(aString at: 1) = $$ 
		ifTrue: 
			[aString size = 1 
				ifTrue: [^self session delegateForCharacter: (Character value: 32)].
			aString size > 2 
				ifTrue: 
					[self error: 'Invalid character specification'.
					^#error].
			^self session delegateForCharacter: (aString at: 2)].
	(aString at: 1) = $# 
		ifTrue: 
			[aString size = 1 ifTrue: [^'' asSymbol asGSObjectInSession: self session].
			^(aString copyFrom: 2 to: aString size) asSymbol 
				asGSObjectInSession: self session].
	(aString at: 1) = $' 
		ifTrue: 
			[(aString size = 1 or: [(aString at: aString size) ~= $']) 
				ifTrue: 
					[self error: 'Missing closing apostrophe'.
					^#error].
			^(aString copyFrom: 2 to: aString size - 1) asGSObjectInSession: self  session].
	(aString at: 1) = $* 
		ifTrue: 
			[(aString size = 2 and: [(aString at: 2) = $*]) 
				ifFalse: 
					[self error: 'Invalid object specification'.
					^#error].
			^lastResult].

	"If we got here, then we need to convert the string to a number"
	aNumber := Number readFrom: aString readStream.
	aNumber printString = aString 
		ifTrue: [^aNumber asGSObjectInSession: self session].

	"This is the last chance.  We will attempt to resolve the object
	 specification from the user's symbol list."
	anAssoc := (OSystem remotePerform: #myUserProfile) 
				remotePerform: #resolveSymbol:
				with: aString asSymbol.
	anAssoc = self session oopNil 
		ifTrue: 
			[self error: 'Invalid object specification'.
			^#error].
	^anAssoc remotePerform: #value
]

{ #category : 'private' }
GbxClassReader >> handleCompilerError: errorDescriptor inSource: sourceString
[
	"If the GbsTools are loaded, we can open a dialog to edit the erroneous expression.
	 Otherwise, we can only notify that the compile error occurred and let the user/developer deal with it."

	^(self respondsTo: #gsCompilerError:onSource:)
		ifTrue: [self gsCompilerError: errorDescriptor onSource: sourceString]
		ifFalse: 
			[self gbsMessenger
				warn: 'CompileError %1 occurred (a copy of this information will be recorded on the Transcript)\%2'
					with: errorDescriptor
					with: sourceString;
				comment: 'CompileError %1 occurred in\%2'
					with: errorDescriptor
					with: sourceString.
			nil]
]

{ #category : 'private' }
GbxClassReader >> inputStream: aStream
[
	inputStream := aStream
]

{ #category : 'private' }
GbxClassReader >> lastResult: anObject
[
	lastResult := anObject
]

{ #category : 'session' }
GbxClassReader >> session
[

	"Answer the GbsSession this instance is associated with.  If nil, attach to current session."
	session isNil ifTrue: [ session := GBSM currentSession ].
	^session
]

{ #category : 'file-in commands' }
GbxClassReader >> run
[

	"This method performs the 'run' command."

self genericExecution
]

{ #category : 'file-in commands' }
GbxClassReader >> env
[
	"Added in GemStone/64. Same behavior as
	set compile_env: 0"

	currentTokens size < 2 ifTrue: [^self error: 'Incomplete env command'].
	currentTokens size ~~ 2 ifTrue: [^self error: 'Malformed "env" command'].
	(currentTokens at: 2) ~= '0'
		ifTrue: [^self error: 'Only "env 0" is currently supported']
]

{ #category : 'file-in commands' }
GbxClassReader >> classmethod
[
	self compileMethod
]

{ #category : 'file-in commands' }
GbxClassReader >> removeAllClassMethods
[
	"Remove all classmethods in the current or specified class"

	"This command uses or sets current class"

	self verifyClassName.
	self session 
		unsynchronizedEvaluateBlock: '[self class removeAllMethods.
										nil]'
		context: currentClass
]

{ #category : 'file-in commands' }
GbxClassReader >> removeAllMethods
[
	"Remove all methods in the current or specified class"

	"This command uses or sets current class"

	self verifyClassName.
	self session 
		unsynchronizedEvaluateBlock: '[self removeAllMethods.
											nil]'
		context: currentClass
]

{ #category : 'file-in commands' }
GbxClassReader >> ignore
[

	"Some file-in commands are ignored by GBS file-in.  Any of those
	 commands send this message."

	self gbsMessenger
		comment: 'Warning ''%1'' ignored.'
		with: (currentTokens at: 1).
]

{ #category : 'file-in commands' }
GbxClassReader >> category
[

	"This method sets the current category for use in compiling methods.  The category name is formed by concatenating the rest of the tokens in currentTokens (from the 2nd upto the end of the array).  If the category name is encased in single quotes, then we eliminate those single quotes."

	| tempName |

	currentTokens size < 2
		ifTrue: [ ^self error: 'You must specify a category name' ].

	tempName := ''.
	2 to: currentTokens size do: [ :each |
		tempName := tempName , (currentTokens at: each) , ' ' ].
	tempName := tempName copyFrom: 1 to: (tempName size - 1).

	(tempName at: 1) = $'
		ifTrue: [ tempName := tempName copyFrom: 2 to: (tempName size) ].
	(tempName at: (tempName size)) = $'
		ifTrue: [ tempName := tempName copyFrom: 1 to: (tempName size - 1) ].

	currentCategory = tempName ifFalse: [
		currentCategory := tempName.
		self gbsMessenger
			comment: 'Compiling methods for category ''%1''.'
			with: currentCategory.
	]
]

{ #category : 'file-in commands' }
GbxClassReader >> silentIgnore
[
	"Some file-in commands are ignored by GBS file-in.
	Ones that are generated by a standard fileout are
	ignored silently, without the warning given by #ignore."
]

{ #category : 'file-in commands' }
GbxClassReader >> object
[
	"This method performs an OBJECT command.  There must be at least
	 one argument - the object specification.  Optional arguments
	 include 'at: anIndex' and 'put: anObjectSpec'."

	| tokenStream aToken sourceObj index valueObj syntaxString isAt oldSourceObj |
	self gbxFixMe.	"There is no test coverage for this message.."
	currentTokens size < 2 
		ifTrue: [^self error: 'You must specify an object in the OBJECT command'].

	"Set up a stream to parse the rest of the command line"
	syntaxString := 'Syntax error in OBJECT command'.
	tokenStream := ReadStream on: currentTokens.
	tokenStream next.

	"Now do the parse"
	sourceObj := self getObjectSpec: tokenStream next.
	tokenStream atEnd 
		ifTrue: [^self printObjectResult: sourceObj	"source object only"].
	
	[tokenStream atEnd 
		ifFalse: 
			[aToken := tokenStream next.
			isAt := aToken asUppercase match: 'AT:'.
			(isAt or: [aToken asUppercase match: 'PUT:']) 
				ifFalse: [^self error: syntaxString].
			isAt]
		ifTrue: [false]] 
			whileTrue: 
				[tokenStream atEnd ifTrue: [^self error: syntaxString].
				index := self getInteger: tokenStream next.
				index = #error ifTrue: [^self].
				(index > 0 and: [index < 16r3FFFFFFF]) 
					ifFalse: [^self error: 'Index out of range'].
				"sourceObj at: index"
				oldSourceObj := sourceObj.
				sourceObj := self 
							performObject: sourceObj
							at: index
							put: self session oopNil.
				sourceObj = #error ifTrue: [^self]].
	tokenStream atEnd ifTrue: [^self printObjectResult: sourceObj].
	(aToken asUppercase match: 'PUT:') 
		ifTrue: 
			[tokenStream atEnd ifTrue: [^self error: syntaxString].
			valueObj := self getObjectSpec: tokenStream next]
		ifFalse: [^self error: syntaxString].

	"sourceObj at: index put: valueObj"
	sourceObj := self 
				performObject: oldSourceObj
				at: index
				put: valueObj.
	sourceObj = #error ifTrue: [^self].
	^self printObjectResult: sourceObj
]

{ #category : 'file-in commands' }
GbxClassReader >> commit
[

	"This method performs a commit to the GemStone repository.  As the
	 commit we will do will not allow us to continue file-in should it fail,
	 we do not worry about error blocks here."

	| committed |
	self gbsMessenger comment: 'Committing...'.
	committed := self session commitTransaction.
	committed isNil
		ifTrue: [ ^self gbsMessenger commentAdd: '...denied' ].
	committed
		ifTrue: [ self gbsMessenger commentAdd: '...succeeded.' ]
		ifFalse: [ self gbsMessenger commentAdd: '...failed.' ].
]

{ #category : 'file-in commands' }
GbxClassReader >> set
[
	"In fileins, we currently only recognize a subset of set commands.
	 All other sets are erroneous."
	
	currentTokens size < 2 ifTrue: [^self error: 'Incomplete set command'].
	self perform: (SetSubcommandHandlers
		at: (currentTokens at: 2) asLowercase
		ifAbsent: [^self error: 'Unrecognized set sub-command']).
]

{ #category : 'file-in commands' }
GbxClassReader >> method
[
	self compileMethod
]

{ #category : 'file-in commands' }
GbxClassReader >> input
[

	"During a file-in, the 'input' command specifies another file to file in.  When the input command completes, the outer filein will continue."

	| filename stream anotherClassReader |
	filename := currentTokens at: 2.
	stream := (GbxFilename named: filename) readStream.
	[
		self gbsMessenger
			comment: 'GemStone file-in from %1...'
			with: filename.
		anotherClassReader := self class on: stream.
		anotherClassReader fileIn.
		self gbsMessenger commentAdd: 'done.'.
	] ensure:
	[
		stream close
	]
]

{ #category : 'file-in commands' }
GbxClassReader >> fileIn
[

	"This method actually performs a GemStone file-in operation."

	| aLine |

	GBSM showBusyWhile: [
		lineNumber := 0.
		[ self atEnd ] whileFalse: [
		    aLine := self nextLineReadingCommand: true.
		    ((aLine size = 0) or: [ (aLine at: 1) = $! ])
		        ifFalse: [
		            self parseLine: aLine.
		            self perform: (currentMessages at: 1).
		            (currentMessages at: 1) = #error
		                ifTrue: [ ^self ]]]]
]

{ #category : 'streaming' }
GbxClassReader >> nextLineReadingCommand: aBoolean
[

	"This method fetches the next line of input from the inputStream
	 so we may parse it.  In addition, we add to the line count so that
	 the error handler may use it.  If the input boolean is TRUE, then
	 we strip unneeded spaces and tabs from the beginning of the line."

	| aLine |

self atEnd
	ifTrue: [ ^'' ].

aLine := ''.
lineNumber := lineNumber + 1.
aBoolean
	ifTrue: [
		[ ((self peek = $ )
			or: [ self peek = (Character tab) ])
			and: [ self atEnd not ] ]
		whileTrue: [ self next ].
	].
self atEnd
	ifTrue: [ ^aLine ].
[
	aLine := aLine , self next.
	(aLine at: (aLine size)) = (10 asCharacter)
		ifTrue: [
			^aLine copyFrom: 1 to: (aLine size - 1)
		].
	(aLine at: (aLine size)) = (13 asCharacter)
		ifTrue: [
			self peekFor: (10 asCharacter).
			^aLine copyFrom: 1 to: (aLine size - 1)
		].
	self atEnd not
] whileTrue: [].

^aLine copyFrom: 1 to: aLine size
]

{ #category : 'streaming' }
GbxClassReader >> peek
[
	^inputStream peek
]

{ #category : 'streaming' }
GbxClassReader >> peekFor: aCharacter
[
	^inputStream peekFor: aCharacter
]

{ #category : 'streaming' }
GbxClassReader >> next
[
	| temp |
	temp := (String new: 1).
	temp at: 1 put: (inputStream next).
	^temp
]

{ #category : 'streaming' }
GbxClassReader >> atEnd
[
	^inputStream atEnd
]

{ #category : 'set sub-commands' }
GbxClassReader >> setSourceStringClass
[
	"In fileins, we currently only recognize setting the source 
	string class to String. All others are erroneous."
	
	currentTokens size ~~ 3 ifTrue: [^self error: 'Malformed "set sourcestringclass" command'].
	(currentTokens at: 3) ~= 'String'
		ifTrue: [^self error: 'Only "set sourcestringclass String" is currently supported']
]

{ #category : 'set sub-commands' }
GbxClassReader >> setCompileEnvironment
[
	"In fileins, we currently only recognize setting the compile 
	environment number to 0. All others are erroneous."
	
	currentTokens size ~~ 3 ifTrue: [^self error: 'Malformed "set compile_env:" command'].
	(currentTokens at: 3) ~= '0'
		ifTrue: [^self error: 'Only "set compile_env: 0" is currently supported']
]

{ #category : 'class initialization' }
GbxClassReader class >> initializeKnownTokens
[
	"GbxClassReader initializeKnownTokens"
	
	KnownTokens := Dictionary new.
	KnownTokens
		at: 'abort' put: #error;
		at: 'break' put: #error;
		at: 'category:' put: #category;
		at: 'classmethod' put: #classmethod;
		at: 'classmethod:' put: #classmethod;
		at: 'commit' put: #commit;
		at: 'compress' put: #error;
		at: 'continue' put: #error;
		at: 'define' put: #error;
		at: 'display' put: #ignore;
		at: 'doit' put: #run;
		at: 'dump' put: #error;
		at: 'edit' put: #error;
		at: 'env' put: #env;
		at: 'exit' put: #error;
		at: 'expectvalue' put: #silentIgnore;
		at: 'fileformat' put: #silentIgnore;
		at: 'fileout' put: #error;
		at: 'help' put: #error;
		at: 'input' put: #input;
		at: 'level' put: #ignore;
		at: 'limit' put: #ignore;
		at: 'list' put: #ignore;
		at: 'load' put: #error;
		at: 'login' put: #error;
		at: 'logout' put: #error;
		at: 'method' put: #method;
		at: 'method:' put: #method;
		at: 'object' put: #error;
		at: 'omit' put: #ignore;
		at: 'opal' put: #run;
		at: 'output' put: #ignore;
		at: 'printit' put: #run;
		at: 'remark' put: #ignore;
		at: 'removeallclassmethods' put: #removeAllClassMethods;
		at: 'removeallmethods' put: #removeAllMethods;
		at: 'run' put: #run;
		at: 'send' put: #error;
		at: 'set' put: #set;
		at: 'spawn' put: #error;
		at: 'stack' put: #error;
		at: 'status' put: #ignore;
		at: 'step' put: #error;
		at: 'temporary' put: #error;
		at: 'time' put: #ignore;
		at: 'uncompress' put: #error
]

{ #category : 'class initialization' }
GbxClassReader class >> initialize
[
	"GbxClassReader initialize"

	self
		initializeKnownTokens;
		initializeSetSubcommandHandlers
]

{ #category : 'class initialization' }
GbxClassReader class >> initializeSetSubcommandHandlers
[
	"GbxClassReader initializeSetSubcommandHandlers"
	
	SetSubcommandHandlers := Dictionary new.
	SetSubcommandHandlers
		at: 'compile_env:' put: #setCompileEnvironment;
		at: 'sourcestringclass' put: #setSourceStringClass
]

{ #category : 'instance creation' }
GbxClassReader class >> on: aStream 
[
	"This method creates a new instance of GemStoneClassReader on the given stream."

	| instance |
	instance := super new.
	instance inputStream: aStream.
	instance currentCategory: '(as yet unclassified)'.
	instance currentClass: GBSM currentSession oopNil.
	instance lastResult: GBSM currentSession oopNil.
	^instance
]
