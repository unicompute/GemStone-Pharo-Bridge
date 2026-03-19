Class {
	#name : 'GbxGciErrSType',
	#superclass : 'GbxStructure',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxGciErrSType >> asGbsErrorForSession: aGbsSession
[
	"Return a new instance of GbsError initialized from the contents of this struct.
	If this is the first fatal error for aGbsSession, record it as the cause of death.
	If aGbsSession already has a cause of death, include its description in
	this errors description.

	Sender must hold GciCallProtect."
	"Note that aGbsSession will be nil if an error is encountered in a call for GBSM's CInterface.
	This should be rare, most calls made by GBSM cannot fail."

	| haveSession preexistingCauseOfDeath category serverProcess arguments description fatal newError |
	haveSession := aGbsSession ~~ nil.
	haveSession
		ifTrue: 
			[preexistingCauseOfDeath := aGbsSession causeOfDeath.
			category := GbxDelegate oopValue: self category session: aGbsSession.
			serverProcess := GbxDelegate oopValue: self context session: aGbsSession.
			arguments := self argDelegatesForSession: aGbsSession].	"If no session, the above variables will be nil."
	description := self message.
	fatal := self fatal.
	newError := (GbsError new)
				category: category;
				number: self number;
				serverProcess: serverProcess;
				fatal: fatal;
				arguments: arguments;
				errorText: description causeOfDeath: preexistingCauseOfDeath;
				session: aGbsSession;
				yourself.
	((fatal and: [preexistingCauseOfDeath isNil]) and: [haveSession]) ifTrue: [aGbsSession causeOfDeath: newError].
	^newError
]

{ #category : 'accessing' }
GbxGciErrSType >> argDelegatesForSession: aGSSession
[

	| argCount oopArray |
	argCount := self argCount min: 10.
	oopArray := aGSSession oopArrayClass
		buffer: (data asByteArrayOfSize: self class fixedSize)
		offset: self argsOffset.
	^oopArray asDelegateArrayOfSize: argCount forSession: aGSSession
]

{ #category : 'accessing' }
GbxGciErrSType >> argCount
[
	^self uint32At: 109
]

{ #category : 'accessing' }
GbxGciErrSType >> argsOffset
[

	self subclassResponsibility
]

{ #category : 'accessing' }
GbxGciErrSType >> category
[
	^self oopAt: 1
]

{ #category : 'accessing' }
GbxGciErrSType >> context
[
	^self oopAt: 9
]

{ #category : 'accessing' }
GbxGciErrSType >> fatal
[
	^self boolAt: 113
]

{ #category : 'accessing' }
GbxGciErrSType >> message
[
	^self cStringAt: 114
]

{ #category : 'accessing' }
GbxGciErrSType >> number
[
	^data signedLongAt: 105
]

{ #category : 'printing' }
GbxGciErrSType >> printOn: aStream indent: indent
[
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'category = ' , self category printString.
	aStream crtab: indent.
	aStream nextPutAll: 'number = ' , self number printString.
	aStream crtab: indent.
	aStream nextPutAll: 'context = ' , self context printString.
	aStream crtab: indent.
	aStream nextPutAll: 'message = ' , self message printString.
	aStream crtab: indent.
	aStream nextPutAll: 'argCount = ' , self argCount printString.
	aStream crtab: indent.
	aStream nextPutAll: 'fatal = ' , self fatal printString
]
