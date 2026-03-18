Class {
	#name : 'MessageNotUnderstood',
	#superclass : 'MessageNotUnderstood',
	#instVars : [
		'selector',
		'envId',
		'receiver'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
MessageNotUnderstood >> reportedReceiver
[

	^receiver
]

{ #category : 'accessing' }
MessageNotUnderstood >> envId
[

	^envId
]

{ #category : 'accessing' }
MessageNotUnderstood >> selector
[

	^selector
]
