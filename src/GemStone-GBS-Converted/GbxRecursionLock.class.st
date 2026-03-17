Class {
	#name : 'GbxRecursionLock',
	#superclass : 'GbxSemaphore',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'mutual exclusion' }
GbxRecursionLock >> critical: mutuallyExcludedBlock
[
	"Answer the result of evaluating criticalBlock while allowing
	 the receiver to synchronize processing with other processes.
	Use a terminationProtectionBlock so that the ensure: is sent 
	immediately after the waitIfCurtailedSignal, with no place
	that the Process could be terminated in between."

	| terminationProtectionBlock activeProcess |
	activeProcess := Processor activeProcess.
	lockingProcess == activeProcess ifTrue: [^mutuallyExcludedBlock value].
	terminationProtectionBlock :=
			[lockingProcess := activeProcess.
			mutuallyExcludedBlock value].
	self waitIfCurtailedSignal.
	^terminationProtectionBlock ensure: 
			[lockingProcess := nil.
			self signal]
]

{ #category : 'private GBS' }
GbxRecursionLock >> critical: mutuallyExcludedBlock unlessBlocked: altBlock
[
	"Answer the result of evaluating criticalBlock while allowing
	 the receiver to synchronize processing with other processes; however,
	 if the activeProcess would have to wait then just run altBlock."

	lockingProcess == Processor activeProcess
		ifTrue: [^mutuallyExcludedBlock value].
	^super critical: mutuallyExcludedBlock unlessBlocked: altBlock
]

{ #category : 'private GBS' }
GbxRecursionLock >> critical: mutuallyExcludedBlock waitingUpTo: milliseconds ifTimeout: altBlock
[
	"Answer the result of evaluating criticalBlock while allowing
	 the receiver to synchronize processing with other processes; however,
	 if the activeProcess would have to wait then just run altBlock."

	lockingProcess == Processor activeProcess
		ifTrue: [^mutuallyExcludedBlock value].
	^super
		critical: mutuallyExcludedBlock
		waitingUpTo: milliseconds
		ifTimeout: altBlock
]

