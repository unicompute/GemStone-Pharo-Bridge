"
Signaled when a GemStone commit fails because of a transaction conflict. Carries the structured conflict
report (conflicts) -- a dictionary keyed by VisualWorks-style conflict-kind symbols (#'Read-Write',
#'Write-Write', #'Write-Read', #'Read-ExclusiveLock', #'Write-ReadLock', #'Write-WriteLock') whose values
are arrays of the conflicting server object OOPs -- so a handler can inspect what conflicted.
"
Class {
	#name : 'GbsCommitConflictError',
	#superclass : 'Error',
	#instVars : [
		'conflicts'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'accessing' }
GbsCommitConflictError >> conflicts [
	"The conflict report dictionary (kind -> array of conflicting OOPs), or an empty dictionary when none
	was captured."
	^ conflicts ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
GbsCommitConflictError >> conflicts: aDictionary [
	conflicts := aDictionary
]

{ #category : 'testing' }
GbsCommitConflictError >> hasConflicts [
	^ self conflicts notEmpty
]

{ #category : 'accessing' }
GbsCommitConflictError >> conflictKinds [
	"The conflict-kind symbols present in the report (the keys with non-empty conflict sets)."
	^ (self conflicts associations
		select: [ :each | each value notNil and: [ each value notEmpty ] ])
		collect: [ :each | each key ]
]
