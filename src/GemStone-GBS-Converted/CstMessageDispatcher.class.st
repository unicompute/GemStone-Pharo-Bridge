Class {
	#name : 'CstMessageDispatcher',
	#superclass : 'Object',
	#instVars : [
		'handler'
	],
	#classInstVars : [
		'singleton'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'class initialization' }
CstMessageDispatcher class >> new [
	^ super new initialize
]

{ #category : 'class initialization' }
CstMessageDispatcher class >> singleton [
	singleton ifNil: [ singleton := self new ].
	^ singleton
]

{ #category : 'class initialization' }
CstMessageDispatcher class >> singleton: aDispatcher [
	singleton := aDispatcher
]

{ #category : 'class initialization' }
CstMessageDispatcher class >> initialize [
	self allSubclasses do: [ :ea | ea singleton: nil ].
	self singleton: nil
]

{ #category : 'documentation' }
CstMessageDispatcher class >> copyright [
	^ 'Copyright (C) 2000 GemStone Systems, Inc.  All Rights Reserved.'
]

{ #category : 'documentation' }
CstMessageDispatcher class >> license [
	^ 'The contents of this file are subject to the Mozilla Public License Version 1.1.'
]

{ #category : 'initialization' }
CstMessageDispatcher >> initialize [
	handler := self newDefaultHandler.
	^ self
]

{ #category : 'accessing' }
CstMessageDispatcher >> handler [
	handler ifNil: [ handler := self newDefaultHandler ].
	^ handler
]

{ #category : 'accessing' }
CstMessageDispatcher >> handler: aMessageHandler [
	handler := aMessageHandler
]

{ #category : 'private' }
CstMessageDispatcher >> newDefaultHandler [
	^ CstMessageHandler newOwner: self
]

{ #category : 'private' }
CstMessageDispatcher >> basicTranscript [
	^ Transcript
]

{ #category : 'private' }
CstMessageDispatcher >> basicComment: aString [
	^ self handler reportComment: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicCommentAdd: aString [
	^ self handler reportCommentAdd: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicNotify: aString [
	^ self handler notify: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicWarn: aString [
	^ self handler reportWarning: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicError: aString [
	^ self handler reportError: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicFailure: aString [
	^ self handler reportFailure: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicConfirm: aString [
	^ self handler confirm: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicConfirmOrCancel: aString [
	^ self handler confirmOrCancel: aString
]

{ #category : 'private' }
CstMessageDispatcher >> basicRequest: aString default: defaultString [
	^ self handler request: aString default: defaultString
]

{ #category : 'printing' }
CstMessageDispatcher >> convertString: aString [
	^ self handler convertString: aString
]

{ #category : 'printing' }
CstMessageDispatcher >> printArgument: anArg on: aStream [
	self handler printArgument: anArg on: aStream
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString [
	^ self print: aString withArguments: #()
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString with: arg1 [
	^ self print: aString withArguments: (Array with: arg1)
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString with: arg1 with: arg2 [
	^ self print: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString with: arg1 with: arg2 with: arg3 [
	^ self print: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	^ self print: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString withArguments: args [
	| stream |
	args isEmpty ifTrue: [ ^ self convertString: aString ].
	stream := WriteStream on: (String new: aString size + 32).
	self print: aString on: stream withArguments: args.
	^ stream contents
]

{ #category : 'printing' }
CstMessageDispatcher >> print: aString on: aStream withArguments: args [
	| rStream source |
	source := self convertString: aString.
	args isEmpty ifTrue: [ aStream nextPutAll: source. ^ self ].
	rStream := ReadStream on: source.
	[ aStream nextPutAll: (rStream upTo: $%).
	rStream atEnd ] whileFalse: [
		rStream peek isDigit
			ifFalse: [ aStream nextPut: $% ]
			ifTrue: [
				| index |
				index := rStream next digitValue.
				(index between: 1 and: args size)
					ifTrue: [ self printArgument: (args at: index) on: aStream ]
					ifFalse: [ aStream nextPut: $%; nextPutAll: index asString ] ] ]
]

{ #category : 'reporting' }
CstMessageDispatcher >> comment: aString [
	self comment: aString withArguments: #()
]

{ #category : 'reporting' }
CstMessageDispatcher >> comment: aString with: arg1 [
	self comment: aString withArguments: (Array with: arg1)
]

{ #category : 'reporting' }
CstMessageDispatcher >> comment: aString with: arg1 with: arg2 [
	self comment: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'reporting' }
CstMessageDispatcher >> comment: aString with: arg1 with: arg2 with: arg3 [
	self comment: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'reporting' }
CstMessageDispatcher >> comment: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	self comment: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'reporting' }
CstMessageDispatcher >> comment: aString withArguments: args [
	self basicComment: (self print: aString withArguments: args)
]

{ #category : 'reporting' }
CstMessageDispatcher >> commentAdd: aString [
	self commentAdd: aString withArguments: #()
]

{ #category : 'reporting' }
CstMessageDispatcher >> commentAdd: aString with: arg1 [
	self commentAdd: aString withArguments: (Array with: arg1)
]

{ #category : 'reporting' }
CstMessageDispatcher >> commentAdd: aString with: arg1 with: arg2 [
	self commentAdd: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'reporting' }
CstMessageDispatcher >> commentAdd: aString with: arg1 with: arg2 with: arg3 [
	self commentAdd: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'reporting' }
CstMessageDispatcher >> commentAdd: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	self commentAdd: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'reporting' }
CstMessageDispatcher >> commentAdd: aString withArguments: args [
	self basicCommentAdd: (self print: aString withArguments: args)
]

{ #category : 'reporting' }
CstMessageDispatcher >> notify: aString [
	^ self notify: aString withArguments: #()
]

{ #category : 'reporting' }
CstMessageDispatcher >> notify: aString with: arg1 [
	^ self notify: aString withArguments: (Array with: arg1)
]

{ #category : 'reporting' }
CstMessageDispatcher >> notify: aString with: arg1 with: arg2 [
	^ self notify: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'reporting' }
CstMessageDispatcher >> notify: aString with: arg1 with: arg2 with: arg3 [
	^ self notify: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'reporting' }
CstMessageDispatcher >> notify: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	^ self notify: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'reporting' }
CstMessageDispatcher >> notify: aString withArguments: args [
	^ self basicNotify: (self print: aString withArguments: args)
]

{ #category : 'reporting' }
CstMessageDispatcher >> warn: aString [
	^ self warn: aString withArguments: #()
]

{ #category : 'reporting' }
CstMessageDispatcher >> warn: aString with: arg1 [
	^ self warn: aString withArguments: (Array with: arg1)
]

{ #category : 'reporting' }
CstMessageDispatcher >> warn: aString with: arg1 with: arg2 [
	^ self warn: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'reporting' }
CstMessageDispatcher >> warn: aString with: arg1 with: arg2 with: arg3 [
	^ self warn: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'reporting' }
CstMessageDispatcher >> warn: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	^ self warn: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'reporting' }
CstMessageDispatcher >> warn: aString withArguments: args [
	^ self basicWarn: (self print: aString withArguments: args)
]

{ #category : 'reporting' }
CstMessageDispatcher >> error: aString [
	^ self error: aString withArguments: #()
]

{ #category : 'reporting' }
CstMessageDispatcher >> error: aString with: arg1 [
	^ self error: aString withArguments: (Array with: arg1)
]

{ #category : 'reporting' }
CstMessageDispatcher >> error: aString with: arg1 with: arg2 [
	^ self error: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'reporting' }
CstMessageDispatcher >> error: aString with: arg1 with: arg2 with: arg3 [
	^ self error: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'reporting' }
CstMessageDispatcher >> error: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	^ self error: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'reporting' }
CstMessageDispatcher >> error: aString withArguments: args [
	self basicError: (self print: aString withArguments: args)
]

{ #category : 'reporting' }
CstMessageDispatcher >> failure: aString [
	self failure: aString withArguments: #()
]

{ #category : 'reporting' }
CstMessageDispatcher >> failure: aString with: arg1 [
	self failure: aString withArguments: (Array with: arg1)
]

{ #category : 'reporting' }
CstMessageDispatcher >> failure: aString with: arg1 with: arg2 [
	self failure: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'reporting' }
CstMessageDispatcher >> failure: aString with: arg1 with: arg2 with: arg3 [
	self failure: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'reporting' }
CstMessageDispatcher >> failure: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	self failure: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'reporting' }
CstMessageDispatcher >> failure: aString withArguments: args [
	self reportFailures ifFalse: [ ^ self ].
	self basicFailure: (self print: aString withArguments: args)
]

{ #category : 'querying' }
CstMessageDispatcher >> reportFailures [
	^ self handler reportFailures
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirm: aString [
	^ self confirm: aString withArguments: #()
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirm: aString with: arg1 [
	^ self confirm: aString withArguments: (Array with: arg1)
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirm: aString with: arg1 with: arg2 [
	^ self confirm: aString withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirm: aString with: arg1 with: arg2 with: arg3 [
	^ self confirm: aString withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirm: aString with: arg1 with: arg2 with: arg3 with: arg4 [
	^ self confirm: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirm: aString withArguments: args [
	^ self basicConfirm: (self print: aString withArguments: args)
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirmOrCancel: aString [
	^ self confirmOrCancel: aString withArguments: #()
]

{ #category : 'user prompts' }
CstMessageDispatcher >> confirmOrCancel: aString withArguments: args [
	^ self basicConfirmOrCancel: (self print: aString withArguments: args)
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString [
	^ self request: aString withArguments: #() default: ''
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString default: defaultString [
	^ self request: aString withArguments: #() default: defaultString
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString with: arg1 default: defaultString [
	^ self request: aString withArguments: (Array with: arg1) default: defaultString
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString with: arg1 with: arg2 default: defaultString [
	^ self request: aString withArguments: (Array with: arg1 with: arg2) default: defaultString
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString with: arg1 with: arg2 with: arg3 default: defaultString [
	^ self request: aString withArguments: (Array with: arg1 with: arg2 with: arg3) default: defaultString
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString with: arg1 with: arg2 with: arg3 with: arg4 default: defaultString [
	^ self request: aString withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4) default: defaultString
]

{ #category : 'user prompts' }
CstMessageDispatcher >> request: aString withArguments: args default: defaultString [
	^ self basicRequest: (self print: aString withArguments: args) default: defaultString
]

{ #category : 'user prompts' }
CstMessageDispatcher >> choose: promptString fromList: list values: values lines: lines cancel: cancelBlock [
	^ self handler
		choose: promptString
		fromList: list
		values: values
		lines: lines
		cancel: cancelBlock
]

{ #category : 'user prompts' }
CstMessageDispatcher >> choose: messageString labels: labels values: values default: defaultValue [
	^ self handler
		choose: messageString
		labels: labels
		values: values
		default: defaultValue
]

{ #category : 'user prompts' }
CstMessageDispatcher >> requestFileName: prompt default: default version: version ifFail: failBlock [
	^ self handler
		requestFileName: prompt
		default: default
		version: version
		ifFail: failBlock
]

{ #category : 'accessing' }
CstMessageDispatcher >> transcript [
	^ self handler transcript
]

{ #category : 'accessing' }
CstMessageDispatcher >> timestampForFilename [
	^ (self handler formattedTimestamp copyReplaceAll: ' ' with: '-') copyReplaceAll: ':' with: '.'
]
