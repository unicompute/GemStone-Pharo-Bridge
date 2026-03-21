Class {
	#name : 'GbxDialog',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'private' }
GbxDialog class >> chooseIndexFrom: labels title: messageString
[
	^ [ UIManager default
		chooseFrom: labels
		title: (self normalizedMessage: messageString) ]
		on: Error
		do: [ 0 ]
]

{ #category : 'multiple choice dialogs' }
GbxDialog class >> choose: messageString fromList: list values: listValues lines: maxLines cancel: cancelBlock
[
	| index |
	index := self chooseIndexFrom: list title: messageString.
	index = 0 ifTrue: [ ^ cancelBlock value ].
	^ listValues at: index ifAbsent: [ cancelBlock value ]
]

{ #category : 'multiple choice dialogs' }
GbxDialog class >> choose: messageString labels: labels values: values default: defaultValue
[
	| index |
	index := self chooseIndexFrom: labels title: messageString.
	index = 0 ifTrue: [ ^ defaultValue ].
	^ values at: index ifAbsent: [ defaultValue ]
]

{ #category : 'multiple choice dialogs' }
GbxDialog class >> confirm: messageString
[
	^ [ UIManager default confirm: (self normalizedMessage: messageString) ]
		on: Error
		do: [ false ]
]

{ #category : 'multiple choice dialogs' }
GbxDialog class >> confirm: messageString for: anApplicationWindow
[
	^ self confirm: messageString
]

{ #category : 'information dialogs' }
GbxDialog class >> notify: messageString
[
	^ self warn: messageString
]

{ #category : 'private' }
GbxDialog class >> normalizedMessage: aString
[
	^ aString asString copyReplaceAll: '\' with: String cr
]

{ #category : 'fill in the blank dialogs' }
GbxDialog class >> request: messageString
[
	^ self request: messageString initialAnswer: ''
]

{ #category : 'fill in the blank dialogs' }
GbxDialog class >> request: messageString initialAnswer: aString
[
	^ [ UIManager default
		request: (self normalizedMessage: messageString)
		initialAnswer: aString asString ]
		on: Error
		do: [ aString asString ]
]

{ #category : 'fill in the blank dialogs' }
GbxDialog class >> request: messageString initialAnswer: aString for: anApplicationWindow
[
	^ self request: messageString initialAnswer: aString
]

{ #category : 'file name dialogs' }
GbxDialog class >> requestFileName: message default: default version: versionType ifFail: failBlock
[
	| answer exists |
	answer := self request: message initialAnswer: default.
	(answer isNil or: [ answer isEmpty ]) ifTrue: [ ^ failBlock value ].
	exists := [ (GbxFilename named: answer) exists ] on: Error do: [ false ].
	(versionType = #new and: [ exists ]) ifTrue: [
		(self confirm: answer , ' exists. Use it anyway?')
			ifFalse: [ ^ failBlock value ] ].
	(versionType = #old and: [ exists not ]) ifTrue: [
		(self confirm: answer , ' does not exist. Try again?')
			ifTrue: [
				^ self
					requestFileName: message
					default: default
					version: versionType
					ifFail: failBlock ].
		^ failBlock value ].
	^ answer
]

{ #category : 'file name dialogs' }
GbxDialog class >> requestNewFileName: message default: default
[
	^ self
		requestFileName: message
		default: default
		version: #new
		ifFail: [ '' ]
]

{ #category : 'information dialogs' }
GbxDialog class >> shucks: messageString
[
	self warn: messageString.
	^ nil
]

{ #category : 'information dialogs' }
GbxDialog class >> warn: messageString
[
	^ [ UIManager default inform: (self normalizedMessage: messageString) ]
		on: Error
		do: [ messageString ]
]

{ #category : 'information dialogs' }
GbxDialog class >> warn: messageString for: anApplicationWindow
[
	^ self warn: messageString
]

{ #category : 'multiple choice dialogs' }
GbxDialog class >> yesNoCancel: messageString
[
	^ self
		choose: messageString
		labels: #('yes' 'no' 'cancel')
		values: #(true false nil)
		default: nil
]
