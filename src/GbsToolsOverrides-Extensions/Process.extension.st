Extension { #name : 'Process' }

{ #category : '*GbsToolsOverrides-Extensions' }
Process >> finalTerminate
[
	"This is the place to put in final processing before a process ends"
	Processor removePausedProcess: self.

	^self primTerminate
]

{ #category : '*GbsToolsOverrides-Extensions' }
Process >> privateDebug
[
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

