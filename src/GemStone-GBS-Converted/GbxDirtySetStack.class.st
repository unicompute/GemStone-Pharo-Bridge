Class {
	#name : 'GbxDirtySetStack',
	#superclass : 'Object',
	#instVars : [
		'session',
		'stack',
		'top'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxDirtySetStack >> popTo: aQueue
	"Pop 0 or 1 item, until aQueue is the top. Signal error if aQueue cannot be the top after 0 or 1 pop"

	self top == aQueue
		ifFalse: 
			[| nextIndex |
			nextIndex := top - 1.
			(nextIndex > 0 and: [(stack at: nextIndex) == aQueue])
				ifTrue: [self pop]
				ifFalse: 
					[self gbsMessenger error: 'Internal error. Specified queue not found.']]

{ #category : 'accessing' }
GbxDirtySetStack >> addObject: anObject
	"Add the given object to the top queue"

	self top add: anObject

{ #category : 'accessing' }
GbxDirtySetStack >> top
	"Answer the set on the top of the stack."

	^stack at: top

{ #category : 'accessing' }
GbxDirtySetStack >> pop
	"Pop and answer a queue from the stack. That queue *should* be empty."

	| result |
	result := self top.
	stack at: top put: nil.
	top := top - 1.
	[self assertAllCleanIn: result] gbxAssert.
	^result

{ #category : 'accessing' }
GbxDirtySetStack >> size
	"Used only for statistic gathering. Answer the total size of all queues."

	| total |
	total := 0.
	1 to: top do: [:i | total := total + (stack at: i) size].
	^total

{ #category : 'accessing' }
GbxDirtySetStack >> emptyInto: resultCollection

	1 to: top
		do: 
			[:i |
			| set |
			set := stack at: i.
			set emptyInto: resultCollection forSession: session].
	self initialize

{ #category : 'accessing' }
GbxDirtySetStack >> grow
	"Nesting of dirty sets is strictly bounded. The default limit of 5 should be enough for all known situations."

	self gbsMessenger error: 'Maximum stack depth exceeded.'

{ #category : 'accessing' }
GbxDirtySetStack >> push
	"Push an empty set to the stack."

	top >= stack size ifTrue: [self grow].
	top := top + 1.
	stack at: top
		put: (GbxDirtySet new: session configuration initialDirtyPoolSize)

{ #category : 'testing' }
GbxDirtySetStack >> isEmpty
	"Note that this will answer true even if non-top queues are not empty.
	This is not intuitive.
	However, this behavior matches the semantics of the previous set-aside-the-dirty-pool semantics."

	^self top isEmpty

{ #category : 'asserting' }
GbxDirtySetStack >> assertAllCleanIn: aDirtySet
	"Report assertion failure if I contain any objects with dirty delegates.
	This clears the set's contents, and is intended to be used after the 
	set has been used and all dirty objects packed."

	aDirtySet destructiveDo: 
			[:each |
			(session cacheAtST: each) isStDirty
				ifTrue: 
					[self gbsMessenger failure: 'Discarding dirty object from DirtyPool'.
					^false]].
	^true

{ #category : 'initialize-release' }
GbxDirtySetStack >> session: aGbsSession

	session := aGbsSession

{ #category : 'initialize-release' }
GbxDirtySetStack >> initialize

	stack := Array new: 5.
	top := 0.
	self push

{ #category : 'instance creation' }
GbxDirtySetStack class >> newForSession: aGbsSession

	^(self new)
		session: aGbsSession;
		initialize;
		yourself

