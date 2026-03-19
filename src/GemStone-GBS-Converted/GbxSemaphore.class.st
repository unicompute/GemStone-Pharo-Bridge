Class {
	#name : 'GbxSemaphore',
	#superclass : 'Semaphore',
	#instVars : [
		'lockingProcess'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private GBS' }
GbxSemaphore >> critical: mutuallyExcludedBlock waitingUpTo: milliseconds ifTimeout: altBlock
[
	"Answer the result of evaluating criticalBlock while allowing
	 the receiver to synchronize processing with other processes; however,
	 if the activeProcess would have to wait then wait up to milliseconds, 
	if further waiting would be required evaluate altBlock.
	We set the priority to highest (as in #valueUnpreemptively) to ensure
	that we can't be preempted between testing the locking process and
	actually doing the wait. Then we drop priority as soon as we safely can.
	We're also careful to make sure that the semaphore's waits and signals
	are balanced, even in the face of process termination at odd moments."

	| acquired triedAtLeastOnce timeoutMs activeProcess oldPriority result |
	timeoutMs := Time millisecondClockValue + milliseconds.
	activeProcess := Processor activeProcess.
	oldPriority := activeProcess priority.
	acquired := false.
	triedAtLeastOnce := false.	"Short timeouts might fail the first time, so try at least once."
	
	[triedAtLeastOnce
		and: [acquired or: [Time millisecondClockValue > timeoutMs]]]
			whileFalse: 
				[triedAtLeastOnce := true.
				activeProcess priority: Processor highestPriority.
				
				[lockingProcess == nil
					ifTrue: 
						[acquired := true.
						self waitIfCurtailedSignal.
						
						[lockingProcess := activeProcess.
						activeProcess priority: oldPriority.
						result := mutuallyExcludedBlock value]
								ensure: 
									[lockingProcess := nil.
									self signal]]
					ifFalse: 
						[activeProcess priority: oldPriority.
						(Delay forMilliseconds: 1) wait]]
						ifCurtailed: [activeProcess priority: oldPriority]].
	^acquired ifTrue: [result] ifFalse: [altBlock value]
]

{ #category : 'private GBS' }
GbxSemaphore >> critical: mutuallyExcludedBlock unlessBlocked: altBlock
[
	"Answer the result of evaluating criticalBlock while allowing
	 the receiver to synchronize processing with other processes; however,
	 if the activeProcess would have to wait then just run altBlock.
	We set the priority to highest (as in #valueUnpreemptively) to ensure
	that we can't be preempted between testing the locking process and
	actually doing the wait. Then we drop priority as soon as we safely can.
	We're also careful to make sure that the semaphore's waits and signals
	are balanced, even in the face of process termination at odd moments."

	| activeProcess oldPriority result |
	activeProcess := Processor activeProcess.
	oldPriority := activeProcess priority.
	activeProcess priority: Processor highestPriority.
	
	[lockingProcess == nil
		ifTrue: 
			[self waitIfCurtailedSignal.
			
			[lockingProcess := activeProcess.
			activeProcess priority: oldPriority.
			result := mutuallyExcludedBlock value]
					ensure: 
						[lockingProcess := nil.
						self signal]]
		ifFalse: 
			[activeProcess priority: oldPriority.
			result := altBlock value]]
			ifCurtailed: [activeProcess priority: oldPriority].
	^result
]

{ #category : 'process termination handling' }
GbxSemaphore >> handleProcessTerminationOfWaitingContext: suspendedContext
[

	| homeMethod |
	homeMethod := suspendedContext homeMethod.
	(homeMethod == (GbxSemaphore compiledMethodAt: #waitIfCurtailedSignal)
		or: [homeMethod == (GbxSemaphore compiledMethodAt: #waitifCurtailedSignal)])
		ifTrue: [^suspendedContext home].
	^super handleProcessTerminationOfWaitingContext: suspendedContext
]

{ #category : 'private GBS' }
GbxSemaphore >> isActiveProcessInCriticalRegion
[

	"Return true if the active process is the one in this recursion lock's
	 critical region"

	^lockingProcess == Processor activeProcess
]

{ #category : 'initialize-release' }
GbxSemaphore >> statAdaptor: aStatAdaptorOrNil
[
	"Return a GbxSemaphoreWithStats wrapping the receiver, if aStatAdaptorOrNil
	is non-nil - stats are being enabled. If it's nil, return self - stats are
	already disabled."

	^aStatAdaptorOrNil isNil
		ifTrue: [self]
		ifFalse: [GbxSemaphoreWithStats semaphore: self statAdaptor: aStatAdaptorOrNil]
]

{ #category : 'mutual exclusion' }
GbxSemaphore >> critical: mutuallyExcludedBlock
[
	"Answer the result of evaluating criticalBlock while allowing
	 the receiver to synchronize processing with other processes.
	Use a terminationProtectionBlock so that the ensure: is sent 
	immediately after the waitIfCurtailedSignal, with no place
	that the Process could be terminated in between."

	| terminationProtectionBlock |
	terminationProtectionBlock :=
			[lockingProcess := Processor activeProcess.
			mutuallyExcludedBlock value].
	self waitIfCurtailedSignal.
	^terminationProtectionBlock ensure: 
			[lockingProcess := nil.
			self signal]
]

{ #category : 'private GBS' }
GbxSemaphore >> waitIfCurtailedSignal
[

	[self wait]
		ifCurtailed: [self signal]
]

{ #category : 'private GBS' }
GbxSemaphore >> waitifCurtailedSignal
[

	^self waitIfCurtailedSignal
]

{ #category : 'printing' }
GbxSemaphore >> printOn: aStream
[

	super printOn: aStream.
	aStream nextPut: $(.
	lockingProcess printOn: aStream.
	aStream nextPut: $).
]

{ #category : 'printing' }
GbxSemaphore >> semaphoreSummaryOn: aStream
[

	| size |
	aStream
		nextPutAll: self class name;
		space.
	size := 0.
	self do: [:each | size := size + 1].
	aStream
		print: self excessSignals;
		nextPutAll: ' Excess Signals, ';
		print: size;
		nextPutAll: ' Waiting Processes, Locking Process: ';
		print: lockingProcess.
]
