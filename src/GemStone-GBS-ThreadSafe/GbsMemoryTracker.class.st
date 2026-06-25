"
A simple OrderedCollection that tracks C-heap memory allocated for thread-safe
GCI calls. Send #freeAll to free every tracked allocation and empty the
collection. Ported from PharoGemStoneFFI (GsMemoryTracker).

Use one tracker per GCI call and #freeAll it on every exit path so error paths
cannot strand OS-heap allocations -- the failure mode the bridge currently risks
across its many ad-hoc ExternalAddress allocate/free sites.
"
Class {
	#name : 'GbsMemoryTracker',
	#superclass : 'OrderedCollection',
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'releasing memory' }
GbsMemoryTracker >> freeAll [
	self do: [ :e | e free ].
	self removeAll
]
