Class {
	#name : 'GbxContextualMessageDispatcher',
	#superclass : 'GbxMessageDispatcher',
	#instVars : [
		'appModelContext'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxContextualMessageDispatcher >> basicWarn: aString
[

	self builder isNil
		ifTrue: [^super basicWarn: aString].
	^GbxDialog
		warn: aString
		for: self builder window.
]

{ #category : 'private' }
GbxContextualMessageDispatcher >> basicRequest: aString default: defaultString
[
	"Raise a generic GemStone error signal with aString for the notifier string."

	self builder isNil
		ifTrue: [^super basicRequest: aString default: defaultString].
	^GbxDialog
		request: aString
		initialAnswer: defaultString
		for: self builder window
]

{ #category : 'private' }
GbxContextualMessageDispatcher >> basicConfirm: aString
[
	" Answer true or false from the user."

	self builder isNil
		ifTrue: [^super basicConfirm: aString].
	^GbxDialog
		confirm: aString
		for: self builder window.
]

{ #category : 'accessing' }
GbxContextualMessageDispatcher >> appModelContext
[
	"Answer the application model for which the message dispatch may
	 apply too. This allows any dialog windows opened by the receiver to
	 to be related to their parent window."

	^appModelContext
]

{ #category : 'accessing' }
GbxContextualMessageDispatcher >> appModelContext: anAppModel
[
	"Answer the application model for which the message dispatch may
	 apply too. This allows any dialog windows opened by the receiver to
	 to be related to their parent window."

	appModelContext := anAppModel.
	^self
]

{ #category : 'accessing' }
GbxContextualMessageDispatcher >> builder
[

	^self appModelContext builder
]

{ #category : 'instance creation' }
GbxContextualMessageDispatcher class >> newForContext: anAppModel
[

	anAppModel isNil ifTrue: [^self singleton].
	(anAppModel respondsTo: #builder) ifFalse: [^self singleton].
	^self new appModelContext: anAppModel
]
