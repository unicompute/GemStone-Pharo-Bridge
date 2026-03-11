Class {
	#name : 'CstMessageHandlerVw',
	#superclass : 'CstMessageHandler',
	#instVars : [
		'hostSignal',
		'hostPrompter'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance selection' }
CstMessageHandlerVw class >> mightApplyForImage [
	| sysVersion |
	sysVersion := [ SystemVersion current imageVersionString ] on: Error do: [ '' ].
	^ sysVersion includesSubstring: 'VisualWorks'
]

{ #category : 'initialization' }
CstMessageHandlerVw >> initialize [
	super initialize.
	hostSignal := Error.
	hostPrompter := UIManager default.
	^ self
]

{ #category : 'accessing' }
CstMessageHandlerVw >> hostErrorSignal [
	^ hostSignal ifNil: [ Error ]
]

{ #category : 'accessing' }
CstMessageHandlerVw >> prompter [
	^ hostPrompter
]

{ #category : 'printing' }
CstMessageHandlerVw >> convertString: aString [
	^ (super convertString: aString) copyReplaceAll: '\' with: String cr
]

{ #category : 'reporting' }
CstMessageHandlerVw >> reportComment: aString [
	self reportCommentAdd: String cr, aString.
	^ aString
]

{ #category : 'prompts' }
CstMessageHandlerVw >> request: message default: initialAnswer [
	^ (self prompter request: message initialAnswer: initialAnswer)
		ifNil: [ super request: message default: initialAnswer ]
]

{ #category : 'prompts' }
CstMessageHandlerVw >> choose: promptString fromList: list values: values lines: lines cancel: cancelBlock [
	| index |
	index := self uiChooseFrom: list title: promptString.
	index = 0 ifTrue: [ ^ cancelBlock value ].
	^ values at: index ifAbsent: [ cancelBlock value ]
]

{ #category : 'prompts' }
CstMessageHandlerVw >> choose: messageString labels: labels values: values default: defaultValue [
	| index |
	index := self uiChooseFrom: labels title: messageString.
	index = 0 ifTrue: [ ^ defaultValue ].
	^ values at: index ifAbsent: [ defaultValue ]
]

{ #category : 'prompts' }
CstMessageHandlerVw >> confirm: aString [
	^ self uiConfirm: aString
]

{ #category : 'prompts' }
CstMessageHandlerVw >> confirmOrCancel: aString [
	^ self
		choose: aString
		labels: #('Yes' 'No' 'Cancel')
		values: #(true false nil)
		default: nil
]

{ #category : 'reporting' }
CstMessageHandlerVw >> notify: aString [
	(self uiManager respondsTo: #inform:)
		ifTrue: [ self uiManager inform: aString ].
	^ aString
]

{ #category : 'prompts' }
CstMessageHandlerVw >> requestFileName: prompt default: default version: versionType ifFail: failBlock [
	| filePath exists |
	filePath := self openFileSelectionForPrompt: prompt.
	filePath ifNil: [
		filePath := self uiRequest: prompt initialAnswer: default ].
	(filePath isNil or: [ filePath isEmpty ]) ifTrue: [ ^ failBlock value ].
	exists := self fileExistsAtPath: filePath.
	(versionType = #new and: [ exists ]) ifTrue: [
		(self uiConfirm: filePath, ' exists - use anyway?')
			ifFalse: [ ^ failBlock value ] ].
	(versionType = #old and: [ exists not ]) ifTrue: [
		(self uiConfirm: filePath, ' does not exist - try again?')
			ifTrue: [ ^ self requestFileName: prompt default: default version: versionType ifFail: failBlock ]
			ifFalse: [ ^ failBlock value ] ].
	^ filePath
]

{ #category : 'accessing' }
CstMessageHandlerVw >> formattedTimestamp [
	| ts pad |
	ts := DateAndTime now.
	pad := [ :n :width |
		| s |
		s := n asString.
		[ s size < width ] whileTrue: [ s := '0', s ].
		s ].
	^ String streamContents: [ :s |
		s
			nextPutAll: (pad value: ts year value: 4);
			nextPut: $-;
			nextPutAll: (pad value: ts month value: 2);
			nextPut: $-;
			nextPutAll: (pad value: ts dayOfMonth value: 2);
			nextPut: Character space;
			nextPutAll: (pad value: ts hour value: 2);
			nextPut: $:;
			nextPutAll: (pad value: ts minute value: 2);
			nextPut: $:;
			nextPutAll: (pad value: ts second value: 2);
			nextPut: $:;
			nextPutAll: (pad value: ts nanoSecond // 1000000 value: 3) ]
]

{ #category : 'private-ui' }
CstMessageHandlerVw >> uiManager [
	^ UIManager default
]

{ #category : 'private-ui' }
CstMessageHandlerVw >> uiChooseFrom: labels title: aTitle [
	^ self uiManager chooseFrom: labels title: aTitle
]

{ #category : 'private-ui' }
CstMessageHandlerVw >> uiConfirm: aString [
	^ self uiManager confirm: aString
]

{ #category : 'private-ui' }
CstMessageHandlerVw >> uiRequest: prompt initialAnswer: defaultString [
	^ self uiManager request: prompt initialAnswer: defaultString
]

{ #category : 'private-ui' }
CstMessageHandlerVw >> openFileSelectionForPrompt: prompt [
	| presenter selected |
	presenter := Smalltalk at: #StOpenFilePresenter ifAbsent: [ nil ].
	presenter ifNil: [ ^ nil ].
	selected := [
		| dlg result |
		dlg := presenter new.
		(dlg respondsTo: #title:) ifTrue: [ dlg title: prompt ].
		result := dlg openModal.
		result
	] on: Error do: [ nil ].
	selected ifNil: [ ^ nil ].
	(selected isCollection and: [ selected isEmpty not ])
		ifTrue: [ ^ selected first asString ].
	^ selected asString
]

{ #category : 'private-ui' }
CstMessageHandlerVw >> fileExistsAtPath: pathString [
	^ [ pathString asFileReference exists ] on: Error do: [ false ]
]

{ #category : 'printing' }
CstMessageHandlerVw >> printArgument: anArg on: aStream [
	[ anArg cstArgumentPrintOn: aStream ]
		on: self hostErrorSignal
		do: [ :ex |
			aStream nextPutAll: '<#printOn: Error>'.
			ex return: nil ]
]
