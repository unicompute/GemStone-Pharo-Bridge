Class {
	#name : 'CstMessageHandler',
	#superclass : 'Object',
	#instVars : [
		'owner',
		'hostPrompter',
		'hostSignal'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance selection' }
CstMessageHandler class >> mightApplyForImage [
	^ false
]

{ #category : 'instance creation' }
CstMessageHandler class >> new [
	^ super new initialize
]

{ #category : 'instance creation' }
CstMessageHandler class >> newOwner: aMessageDispatcher [
	^ self selectCorrectBehavior new owner: aMessageDispatcher; yourself
]

{ #category : 'instance selection' }
CstMessageHandler class >> selectCorrectBehavior [
	| candidates |
	candidates := self withAllSubclasses select: [ :ea | ea mightApplyForImage ].
	candidates isEmpty ifTrue: [ ^ self ].
	candidates size = 1 ifTrue: [ ^ candidates first ].
	^ candidates last
]

{ #category : 'initialization' }
CstMessageHandler >> initialize [
	hostSignal := Error.
	hostPrompter := UIManager default.
	^ self
]

{ #category : 'accessing' }
CstMessageHandler >> owner [
	^ owner
]

{ #category : 'accessing' }
CstMessageHandler >> owner: aMessageDispatcher [
	owner := aMessageDispatcher.
	^ self
]

{ #category : 'accessing' }
CstMessageHandler >> cstMessenger [
	^ self owner ifNil: [ CstMessageDispatcher singleton ]
]

{ #category : 'printing' }
CstMessageHandler >> translate: aString [
	^ aString
]

{ #category : 'printing' }
CstMessageHandler >> convertString: aString [
	| string |
	string := self translate: aString.
	^ string copyReplaceAll: '\' with: String cr
]

{ #category : 'printing' }
CstMessageHandler >> printArgument: anArg on: aStream [
	[ anArg cstArgumentPrintOn: aStream ]
		on: Error
		do: [ :ex |
			aStream nextPutAll: '<#printOn: Error>'.
			ex return: nil ]
]

{ #category : 'reporting' }
CstMessageHandler >> reportComment: aString [
	self transcript cr.
	self reportCommentAdd: aString.
	^ aString
]

{ #category : 'reporting' }
CstMessageHandler >> reportCommentAdd: aString [
	self transcript show: aString.
	^ aString
]

{ #category : 'reporting' }
CstMessageHandler >> reportError: aString [
	self error: aString
]

{ #category : 'reporting' }
CstMessageHandler >> reportFailure: aString [
	^ self reportError: (self cstMessenger print: 'Failure-%1' with: aString)
]

{ #category : 'reporting' }
CstMessageHandler >> reportWarning: aString [
	^ self notify: (self cstMessenger print: 'Warning: %1' with: aString)
]

{ #category : 'reporting' }
CstMessageHandler >> reportFailures [
	^ true
]

{ #category : 'reporting' }
CstMessageHandler >> notify: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : 'prompts' }
CstMessageHandler >> confirm: aString [
	^ UIManager default confirm: aString
]

{ #category : 'prompts' }
CstMessageHandler >> confirmOrCancel: aString [
	| index |
	index := UIManager default chooseFrom: #('Yes' 'No' 'Cancel') title: aString.
	index = 1 ifTrue: [ ^ true ].
	index = 2 ifTrue: [ ^ false ].
	^ nil
]

{ #category : 'prompts' }
CstMessageHandler >> request: aString default: defaultString [
	^ UIManager default request: aString initialAnswer: defaultString
]

{ #category : 'prompts' }
CstMessageHandler >> choose: promptString fromList: list values: values lines: lines cancel: cancelBlock [
	| index |
	index := UIManager default chooseFrom: list title: promptString.
	index = 0 ifTrue: [ ^ cancelBlock value ].
	^ values at: index ifAbsent: [ cancelBlock value ]
]

{ #category : 'prompts' }
CstMessageHandler >> choose: multilineMessage labels: labelArray values: returnValueArray default: defaultValue [
	| index |
	index := UIManager default chooseFrom: labelArray title: multilineMessage.
	index = 0 ifTrue: [ ^ defaultValue ].
	^ returnValueArray at: index ifAbsent: [ defaultValue ]
]

{ #category : 'prompts' }
CstMessageHandler >> requestFileName: prompt default: default version: version ifFail: failBlock [
	| path |
	path := UIManager default request: prompt initialAnswer: default.
	(path isNil or: [ path isEmpty ]) ifTrue: [ ^ failBlock value ].
	^ path
]

{ #category : 'accessing' }
CstMessageHandler >> transcript [
	self owner ifNil: [ ^ Transcript ].
	^ self owner basicTranscript
]

{ #category : 'accessing' }
CstMessageHandler >> formattedTimestamp [
	| dt |
	dt := DateAndTime now.
	^ dt asString
]
