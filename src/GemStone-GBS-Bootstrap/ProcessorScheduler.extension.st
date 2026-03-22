Extension { #name : 'ProcessorScheduler' }

{ #category : '*GemStone-GBS-Bootstrap' }
ProcessorScheduler >> backgroundPriority
[
	"VisualWorks compatibility - return low priority"
	^self lowPriority
]

{ #category : '*GemStone-GBS-Bootstrap' }
ProcessorScheduler >> userBackgroundPriority
[
	"VisualWorks compatibility - return normal priority"
	^self normalPriority
]

{ #category : '*GemStone-GBS-Bootstrap' }
ProcessorScheduler >> lowIOPriority
[
	"VisualWorks compatibility - return low priority for I/O operations"
	^self lowPriority
]

{ #category : '*GemStone-GBS-Bootstrap' }
ProcessorScheduler >> userSchedulingPriority
[
	"VisualWorks compatibility - return normal priority for user scheduling"
	^self normalPriority
]
