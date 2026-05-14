Class {
	#name : 'GbxDebuggerServerExecutionController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerServerExecutionController class >> on: aDebuggerService [
	^ self new
		service: aDebuggerService;
		yourself
]

{ #category : 'server stepping' }
GbxDebuggerServerExecutionController >> basicSendIntoServer [
	| gbsErr initial |
	service requestServerSingleStep.

	[ service privateStep ]
		on: Error
		do: [ :ex |
			gbsErr := ex parameter.
			(gbsErr isNil or: [
				(gbsErr respondsTo: #creator) ifFalse: [ true ]
				ifTrue: [ gbsErr creator ~~ (service gbsErrorClass signalFor: #rtErrStep) ] ])
					ifTrue: [ ex pass ] ].

	gbsErr ifNotNil: [
		initial := (gbsErr respondsTo: #initialContext)
			ifTrue: [ [ gbsErr initialContext ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		initial ifNotNil: [ service currentContext: initial ].
		service selectTopServerContext ]
]

{ #category : 'server stepping' }
GbxDebuggerServerExecutionController >> basicServerStepInLevel: level [
	| gbsError scContext result |
	gbsError := service currentContext gbsError.
	gbsError ifNil: [ ^ service ].
	gbsError stepLevel: level.
	scContext := service currentContext serverCallContext.
	scContext ifNil: [ ^ service ].
	service currentContext: scContext.
	service resetPCSelection.
	service stepUntilPC: 31.
	service currentContext == scContext ifFalse: [ ^ service ].
	service stepUntilPC: 10.
	result := (scContext respondsTo: #gbxResult)
		ifTrue: [ scContext gbxResult ]
		ifFalse: [ nil ].
	(result notNil and: [
		(result respondsTo: #gbxIsGSError) and: [ result gbxIsGSError ] ])
			ifTrue: [ service selectTopServerContext ]
			ifFalse: [ service stepOutOfServerIntoClient ]
]

{ #category : 'accessing' }
GbxDebuggerServerExecutionController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerServerExecutionController >> service: aDebuggerService [
	service := aDebuggerService
]

{ #category : 'server stepping' }
GbxDebuggerServerExecutionController >> stepOutOfServerIntoClient [
	| itsSender aContext |
	itsSender := service currentContext.

	[
		aContext := itsSender.
		itsSender := itsSender sender.
		(aContext respondsTo: #gbxIsGsBottomGlue)
			and: [ aContext gbxIsGsBottomGlue
			and: [ itsSender notNil
			and: [ (itsSender respondsTo: #gbxIsGsBottomGlue)
				ifTrue: [ itsSender gbxIsGsBottomGlue not ]
				ifFalse: [ true ] ] ] ] ]
		whileTrue.

	itsSender ifNotNil: [
		service currentContext: itsSender.
		service stepOver.
		service selectContext: service currentContext ]
]

