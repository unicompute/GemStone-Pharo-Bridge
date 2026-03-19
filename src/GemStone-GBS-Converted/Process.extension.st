Extension { #name : #'Process' }

{ #category : '*GemStone-GBS-Converted-private' }
Process >> finalTerminate [
	"This is the place to put in final processing before a process ends"
	Processor removePausedProcess: self.

	^self primTerminate
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Process >> privateDebug [
	Processor activeProcess == self
		ifTrue:
			[self
				suspendResumable: false
				do: [:proc | proc privateDebug].
			^self		"We should never reach this."].
	suspendedContext isNil
		ifTrue: [^self].	"nothing to debug"
	Processor removePausedProcess: self.
	[myList isNil
		ifTrue: [self resume].
	self uninterruptablyDo: [self suspend]] valueUnpreemptively.
	[Notifier current
		openOnHandle: (ProcessHandle
			on: self
			at: suspendedContext
			interrupted: true)
		label: (#DebugProcess << #pdp >> 'Debug process').] forkAt: Processor userSchedulingPriority
]

{ #category : '*GemStone-GBS-Converted-user-interface' }
Process >> inspectorExtraAttributes [
	
	^Array
		with:
			(TextAttribute
				label: #identityHash
				text: self identityHash printString)
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Process class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Process class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Process class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Process >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Process >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Process >> isRunningUnderAssertingVM [
	^false
]

