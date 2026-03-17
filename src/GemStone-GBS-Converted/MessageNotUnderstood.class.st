Class {
	#name : #'MessageNotUnderstood',
	#superclass : #'MessageNotUnderstood',
	#instVars : [ #'selector' #'envId' #'receiver' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
MessageNotUnderstood >> reportedReceiver

	^receiver

{ #category : #'accessing' }
MessageNotUnderstood >> envId

	^envId

{ #category : #'accessing' }
MessageNotUnderstood >> selector

	^selector

