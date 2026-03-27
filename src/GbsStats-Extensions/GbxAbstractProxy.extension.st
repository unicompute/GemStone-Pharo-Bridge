Extension { #name : 'GbxAbstractProxy' }

{ #category : '*GbsStats-Extensions' }
GbxAbstractProxy >> gbxBytesCached
[
	"Count only the bytes consumed by the stub itself.  Do not recursively
	 count the stubs slots, even though they may reference objects if stub
	 slot nilling is false, because those objects are typically referenced from
	 the cache directly, and will be therefore be counted when iterating the
	 cache for stats."

	| om bpw headerBytes bodyWords cls |
	om := ObjectMemory current.
	headerBytes := om bytesPerOTE.
	bpw := om bytesPerOOP.
	cls := self gbxBasicClass.
	cls isBits
		ifTrue: 
			[| bytes |
			bytes := self gbxBasicSize.	"Byte objects occupy integral number of words, so pad"
			bodyWords := bytes // bpw.
			bytes \\ bpw == 0 ifFalse: [bodyWords := bodyWords + 1]]
		ifFalse: 
			[bodyWords := cls instSize.
			cls isVariable ifTrue: [bodyWords := bodyWords + self gbxBasicSize]].
	^headerBytes + (bodyWords * bpw)
]

