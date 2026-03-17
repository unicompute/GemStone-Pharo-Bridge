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
		buffer: (Core.UninterpretedBytes from: data contents datum asByteArray)
		offset: self argsOffset.
	^oopArray asDelegateArrayOfSize: argCount forSession: aGSSession
]

{ #category : 'accessing' }
GbxGciErrSType >> argsOffset
[

	self subclassResponsibility
]

