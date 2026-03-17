Class {
	#name : #'GbxConflictFreePipeElement',
	#superclass : #'Object',
	#instVars : [ #'nextElement' #'payload' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'public' }
GbxConflictFreePipeElement >> removePayload

	| aPayload |
	aPayload := payload.
	payload := nil.	"So we don't keep it alive."
	^aPayload

{ #category : #'accessing' }
GbxConflictFreePipeElement >> nextElement: anObject

	nextElement := anObject

{ #category : #'accessing' }
GbxConflictFreePipeElement >> payload: anObject

	payload := anObject

{ #category : #'accessing' }
GbxConflictFreePipeElement >> nextElement

	^nextElement

