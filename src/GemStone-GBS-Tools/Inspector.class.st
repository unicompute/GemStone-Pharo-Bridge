Class {
	#name : 'Inspector',
	#superclass : 'ApplicationModel',
	#instVars : [
		'object',
		'container',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'text' }
Inspector >> text
[
	"Answer the text displayed by the receiver."

	| string |
	field == nil ifTrue: [^Text new].
	string := [5 seconds
				toFinish: [field = 'self'
						ifTrue: [self fieldValue inspectString]
						ifFalse: [self fieldValue gbxDebugPrintString]]
				orElse: [self basicObjectPrintString: self fieldValue]]
				on: Error , BreakInterrupt
				do: [:ex | self protectedBasicObjectPrintString: self fieldValue].
	^string asText
]

{ #category : 'utilities-printing' }
Inspector class >> basicObjectPrintString: anObject
[
	"Answer a basic print string of anObject without sending any messages to it."

	| aStream |
	aStream := WriteStream on: (String new: 16).
	anObject basicPrintOn: aStream.
	^aStream contents
]

{ #category : 'utilities-printing' }
Inspector class >> safeLabelStringOf: anObject
[
	"Answer a string representation of anObject short enough and line break-free,
	for use in contexts such as a list view. Unlike safeDisplayString, favor the
	programmer perspective (that is, printString) and try hard to give a useful
	answer by falling back to basic print string if printString fails."

	^[ | string |
	anObject gbxIsProxy
		ifTrue: [^anObject basicPrintString]
		ifFalse: [string := anObject gbxDebugPrintString].
	(string size > 40 or: [string trimBlanks isEmpty or: [(string includes: Character cr) or: [string includes: Character lf]]])
		ifTrue: [anObject basicPrintString]
		ifFalse: [string]
	]
		on: Error, BreakInterrupt
		do: [:ex | ex return: (self safeBasicPrintStringOf: anObject)]
]

{ #category : 'utilities-printing' }
Inspector class >> safePrintStringOf: anObject
[
	"wrapping the object to retrieve the printString is a handy way of getting 
	a printString that reflects both client and delegate if available"

	^[(GemStone.Gbs.GbxInspectionWrapper on: anObject) printString]
		on: self safePrintingErrors
		do:
			[:ex | 
			ex
				return:
					(#ErrorPrintingObject << #dialogs >> '[Error printing the object: <1s>]'
						expandMacrosWith: ex description)]
]

