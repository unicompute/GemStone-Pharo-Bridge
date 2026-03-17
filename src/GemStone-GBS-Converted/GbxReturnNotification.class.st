Class {
	#name : 'GbxReturnNotification',
	#superclass : 'Notification',
	#instVars : [
		'returnValue'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'constants' }
GbxReturnNotification >> defaultReturnValue
[

	^returnValue
]

{ #category : 'accessing' }
GbxReturnNotification >> returnValue
[

	^returnValue
]

{ #category : 'accessing' }
GbxReturnNotification >> returnValue: anObject
[

	returnValue := anObject
]

{ #category : 'instance creation' }
GbxReturnNotification class >> returning: anObject
[

	^(self new)
		returnValue: anObject;
		yourself
]

