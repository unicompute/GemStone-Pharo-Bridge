Class {
	#name : 'GbxDelay',
	#superclass : 'Object',
	#instVars : [
		'delay',
		'waitSemaphore',
		'timerProcess',
		'stateProtect',
		'completed'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
GbxDelay class >> forMilliseconds: aNumber
[
	^ self new
		delay: (Delay forMilliseconds: (aNumber max: 0));
		yourself
]

{ #category : 'instance creation' }
GbxDelay class >> forSeconds: aNumber
[
	^ self forMilliseconds: (aNumber * 1000) rounded
]

{ #category : 'instance creation' }
GbxDelay class >> untilMilliseconds: millisecondClockValue
[
	| now delta |
	now := Time millisecondClockValue.
	delta := millisecondClockValue - now.
	delta < 0 ifTrue: [ delta := 0 ].
	^ self forMilliseconds: delta
]

{ #category : 'private' }
GbxDelay >> completeWait
[
	stateProtect critical: [
		completed ifTrue: [ ^ self ].
		completed := true.
		timerProcess := nil.
		waitSemaphore ifNotNil: [ waitSemaphore signal ] ].
	^ self
]

{ #category : 'private' }
GbxDelay >> delay: aDelay
[
	delay := aDelay.
	^ self
]

{ #category : 'private' }
GbxDelay >> gbxDisregard
[
	stateProtect critical: [
		(waitSemaphore isNil or: [ completed ]) ifTrue: [ ^ self ].
		completed := true.
		timerProcess ifNotNil: [
			[ timerProcess terminate ] on: Error do: [ ] ].
		timerProcess := nil.
		waitSemaphore signal ].
	^ self
]

{ #category : 'initialize-release' }
GbxDelay >> initialize
[
	super initialize.
	stateProtect := Semaphore forMutualExclusion.
	completed := false.
	^ self
]

{ #category : 'waiting' }
GbxDelay >> wait
[
	| localSemaphore |
	stateProtect critical: [
		completed ifTrue: [ ^ self ].
		waitSemaphore := Semaphore new.
		localSemaphore := waitSemaphore.
		timerProcess := [
			[ delay wait ] ensure: [ self completeWait ] ]
				forkAt: Processor userBackgroundPriority ].
	localSemaphore wait.
	stateProtect critical: [
		waitSemaphore == localSemaphore ifTrue: [ waitSemaphore := nil ] ].
	^ self
]
