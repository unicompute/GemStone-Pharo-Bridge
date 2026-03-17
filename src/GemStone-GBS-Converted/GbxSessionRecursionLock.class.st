Class {
	#name : #'GbxSessionRecursionLock',
	#superclass : #'GbxRecursionLock',
	#instVars : [ #'eventDetectorThread' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private GBS' }
GbxSessionRecursionLock >> critical: mutuallyExcludedBlock unlessBlocked: altBlock
	"if the event detector thread has the session semaphore, 
	we will wait up to one second as it is probably doing a GciPollForSignal
	which will be done soon. "

	^self isPolling
		ifTrue: 
			[self critical: mutuallyExcludedBlock waitingUpTo: 1000 ifTimeout: altBlock]
		ifFalse: [super critical: mutuallyExcludedBlock unlessBlocked: altBlock]

{ #category : #'private GBS' }
GbxSessionRecursionLock >> isPolling

	^lockingProcess == eventDetectorThread

{ #category : #'accessing' }
GbxSessionRecursionLock >> eventDetectorThread: anObject
	eventDetectorThread := anObject

{ #category : #'printing' }
GbxSessionRecursionLock >> semaphoreSummaryOn: aStream

	super semaphoreSummaryOn: aStream.
	aStream
		nextPutAll: ', Is Polling: ';
		print: self isPolling.

