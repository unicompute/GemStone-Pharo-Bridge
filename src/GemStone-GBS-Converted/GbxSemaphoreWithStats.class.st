Class {
	#name : #'GbxSemaphoreWithStats',
	#superclass : #'Object',
	#instVars : [ #'semaphore' #'statAdaptor' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxSemaphoreWithStats >> semaphore: aSemaphore statAdaptor: aStatAdaptor

	semaphore := aSemaphore.
	statAdaptor := aStatAdaptor

{ #category : #'accessing' }
GbxSemaphoreWithStats >> eventDetectorThread: anObject
	semaphore eventDetectorThread: anObject

{ #category : #'accessing' }
GbxSemaphoreWithStats >> semaphore
	^semaphore

{ #category : #'printing' }
GbxSemaphoreWithStats >> semaphoreSummaryOn: aStream

	semaphore semaphoreSummaryOn: aStream

{ #category : #'stat enable/disable' }
GbxSemaphoreWithStats >> statAdaptor: aStatAdaptorOrNil 
	"Return the receiver if aStatAdaptorOrNil is non-nil - stats are already 
	 enabled.  If it's nil, return the semaphore - stats are being disabled."

	^aStatAdaptorOrNil isNil 
		ifTrue: [semaphore]
		ifFalse: 
			[statAdaptor := aStatAdaptorOrNil.
			self]

{ #category : #'dispatching' }
GbxSemaphoreWithStats >> isActiveProcessInCriticalRegion

	^semaphore isActiveProcessInCriticalRegion

{ #category : #'dispatching' }
GbxSemaphoreWithStats >> critical: aBlock

	| result start |
	start := statAdaptor startCall.
	result := semaphore critical: aBlock.
	statAdaptor endCall: start.
	^result

{ #category : #'dispatching' }
GbxSemaphoreWithStats >> critical: criticalBlock unlessBlocked: altBlock 
	| result start |
	start := statAdaptor startCall.
	result := semaphore critical: criticalBlock unlessBlocked: altBlock.
	statAdaptor endCall: start.
	^result

{ #category : #'instance creation' }
GbxSemaphoreWithStats class >> semaphore: aSemaphore statAdaptor: aStatAdaptor

	^super new semaphore: aSemaphore statAdaptor: aStatAdaptor

