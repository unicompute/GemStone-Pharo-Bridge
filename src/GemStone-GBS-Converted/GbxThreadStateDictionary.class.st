Class {
	#name : #'GbxThreadStateDictionary',
	#superclass : #'Object',
	#instVars : [ #'keys' #'values' #'tally' #'needFinalization' #'capacity' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxThreadStateDictionary >> initialize

	| tableSize |
	tableSize := Set goodSizeFrom: 5.
	capacity := tableSize * 7 // 10.
	keys := WeakArray new: tableSize.
	keys addDependent: self.
	values := Array new: tableSize.
	tally := 0.
	needFinalization := false

{ #category : #'public' }
GbxThreadStateDictionary >> value: aValue
	"Associate the given value with the executing thread.
	Sender must hold my session's sessionProtect."

	| activeProcess index |
	activeProcess := Processor activeProcess.
	index := self indexForKey: activeProcess.
	(keys at: index)
		ifNil: 
			["Updating three things, protect against process termination in the middle"
			[] ensure: 
					[keys at: index put: activeProcess.
					values at: index put: aValue.
					tally := tally + 1.
					"Include rehash in termination protection. Otherwise, repeated process 
					terminations during this ensure block could exhaust all space and cause 
					indexForKey: to loop infinitely."
					self rehashIfNeeded]]
		ifNotNil: [values at: index put: aValue].
	^aValue

{ #category : #'public' }
GbxThreadStateDictionary >> value
	"Answer the value set for the current thread, or nil if the current thread has never set a value.
	Sender must hold my session's sessionProtect."

	| activeProcess index |
	activeProcess := Processor activeProcess.
	index := self indexForKey: activeProcess.
	^(keys at: index) == activeProcess
		ifTrue: [values at: index]
		ifFalse: [nil]

{ #category : #'finalization' }
GbxThreadStateDictionary >> update: anAspectSymbol with: aParameter from: aSender
	"If I'm being told that I need finalization, record that fact.
	During a rehash, notification could come from old or new keys,
	so just accept an update from any source."

	anAspectSymbol = #ElementExpired ifTrue: [needFinalization := true]

{ #category : #'private' }
GbxThreadStateDictionary >> indexForKey: aProcess
	"Answer the index at which aProcess appears, or the index where it would be if it were present.
	keyArray is an identity-hashed open-addressing with linear probing table.
	Sender must hold my session's sessionProtect."

	| tableSize currentIndex currentKey |
	tableSize := keys size.
	currentIndex := aProcess identityHash \\ tableSize + 1.
	
	[currentKey := keys at: currentIndex.
	currentKey == nil or: [currentKey == aProcess]]
			whileFalse: 
				[currentIndex := currentIndex + 1.
				currentIndex > tableSize ifTrue: [currentIndex := 1]].
	^currentIndex

{ #category : #'private' }
GbxThreadStateDictionary >> rehashToTableOfSize: newTableSize
	"Copy the table to a new table of the given size, which should be a 'good' prime, 
	then replace the old table with the new one. Omit any tombstones while copying.

	Sender must hold my session's sessionProtect.
	Sender must be within an ensure block to guard against process termination."

	| newKeys newValues newTally |
	needFinalization := false.	"About to finalize, but a GC during finalization could add more tombstones and reset needFinalization to true."
	newKeys := WeakArray new: newTableSize.
	newKeys addDependent: self.	"If a key gets collected during the rehash, we should get notified from the old array, but better safe than sorry."
	newValues := Array new: newTableSize.
	newTally := 0.
	keys with: values
		do: 
			[:key :value |
			| newIndex currentKey |
			key ~~ nil & (key ~~ 0)
				ifTrue: 
					[newIndex := key identityHash \\ newTableSize + 1.
					
					[currentKey := newKeys at: newIndex.
					currentKey == nil] whileFalse: 
								[newIndex := newIndex + 1.
								newIndex > newTableSize ifTrue: [newIndex := 1]].
					newValues at: newIndex put: value.
					newKeys at: newIndex put: key.
					newTally := newTally + 1]].
	"New keys/values now ready, Swap them in. Sender protects against process termination."
	keys := newKeys.
	values := newValues.
	capacity := newTableSize * 7 // 10.
	tally := newTally
	"Old keys and values arrays are now unreferenced. I'm still a dependent of the old keys WeakArray, so it's possible
	needsFinalization could be set by both new and old keys arrays before the old keys is GCed, but this is harmless."

{ #category : #'private' }
GbxThreadStateDictionary >> rehash
	"Sender must hold my session's sessionProtect."
	"If we're finalizing, keep the same table size, since we are about to free some space. 
	Otherwise we need to grow to a prime more than twice our current table size."

	self rehashToTableOfSize: (needFinalization
				ifTrue: [keys size]
				ifFalse: [Set goodSizeFrom: keys size * 2])

{ #category : #'private' }
GbxThreadStateDictionary >> rehashIfNeeded
	"We rehash for either of two reasons: the VM has notified us that there are 
  tombstones to collect, or we are too full and need to grow."

	(needFinalization or: [tally >= capacity]) ifTrue: [self rehash]

{ #category : #'instance creation' }
GbxThreadStateDictionary class >> new

	^super new initialize

