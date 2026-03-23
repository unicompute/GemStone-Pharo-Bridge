Class {
	#name : 'GbsGemStoneError',
	#superclass : 'GbxAbstractException',
	#instVars : [
		'serverArguments'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'constants' }
GbsGemStoneError >> defaultResumeValue
[
	"Answer the default value to resume server execution with.
		The default is to leave the server argument stack alone."

	^GbxKernelPomOop oopIllegal
]

{ #category : 'defaults' }
GbsGemStoneError >> defaultAction
[
	self isFatalError
		ifTrue: [ ^ super defaultAction ].
	^ self resume
]

{ #category : 'testing' }
GbsGemStoneError >> isFatalError
[
	^ self originator
		ifNil: [ false ]
		ifNotNil: [ :error | error isFatalError ]
]

{ #category : 'testing' }
GbsGemStoneError >> isResumable
[
	^ self isFatalError not
]

{ #category : 'accessing' }
GbsGemStoneError >> exceptionOop
[
	| error |
	error := self originator.
	(error respondsTo: #exceptionOop) ifFalse: [ ^ nil ].
	^ error exceptionOop
]

{ #category : 'accessing' }
GbsGemStoneError >> serverProcessOop
[
	| error |
	error := self originator.
	(error respondsTo: #serverProcessOop) ifFalse: [ ^ nil ].
	^ error serverProcessOop
]

{ #category : 'accessing' }
GbsGemStoneError >> tag
[
	| error |
	error := self originator.
	(error respondsTo: #tag) ifFalse: [ ^ nil ].
	^ error tag
]

{ #category : 'accessing' }
GbsGemStoneError >> serverArguments
[

	"Return an array of arguments to this exception.  These are the client replicates
	 of the GemStone error arguments"

	| gbsErr |
	gbsErr := self originator.
	(serverArguments isNil and: [gbsErr notNil]) ifTrue: [
		"Lazily initialize client replicates of GemStone error arguments"
		serverArguments := Array new: gbsErr arguments size.
		1 to: serverArguments size do: [ :i |
			| gsObj |
			gsObj := gbsErr arguments at: i.
			serverArguments at: i put: gsObj asLocalObject.
		]].

	^serverArguments
]

{ #category : 'accessing' }
GbsGemStoneError >> serverArguments: anArray
[
	serverArguments := anArray
]

{ #category : 'constants' }
GbsGemStoneError class >> gemStoneErrorNumber6430
[
	"Return the number GemStone uses to identify this error.  There are a
	 few GemStone errors that are known by more than one number (the 
	 number changed from one version of the server to the next) - for those
	 errors, this method returns an array of numbers."
	"For most error classes, the number is the same in 32 and 64-bit & 64-bit v3.
	Errors that don't exist in one or the other won't define the method, so answer nil."
	
	^nil
]
