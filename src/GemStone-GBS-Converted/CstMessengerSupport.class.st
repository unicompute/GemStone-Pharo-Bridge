Class {
	#name : 'CstMessengerSupport',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
CstMessengerSupport class >> notice [
	| dispatcher |
	dispatcher := Smalltalk globals at: #CstMessageDispatcher ifAbsent: [ nil ].
	(dispatcher notNil and: [ dispatcher respondsTo: #license ])
		ifTrue: [ ^ dispatcher license ].
	^ 'CstMessengerSupport'
]

{ #category : 'packaging' }
CstMessengerSupport class >> packagerIgnoreReferencesInSelectors [
	^ #(convertString:)
]

{ #category : 'packaging' }
CstMessengerSupport class >> packagerIncludeClasses [
	| handlerClass selected |
	handlerClass := Smalltalk globals at: #CstMessageHandler ifAbsent: [ nil ].
	handlerClass ifNil: [ ^ #() ].
	selected := (handlerClass respondsTo: #selectCorrectBehavior)
		ifTrue: [ handlerClass selectCorrectBehavior ]
		ifFalse: [ handlerClass ].
	^ { selected }
]

{ #category : 'lifecycle' }
CstMessengerSupport class >> removing [
	| dispatcher |
	dispatcher := Smalltalk globals at: #CstMessageDispatcher ifAbsent: [ nil ].
	(dispatcher notNil and: [ dispatcher respondsTo: #initialize ])
		ifTrue: [ dispatcher initialize ].
]
