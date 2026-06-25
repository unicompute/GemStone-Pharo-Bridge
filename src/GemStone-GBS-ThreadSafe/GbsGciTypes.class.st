"
Pool of C type aliases used by the thread-safe GCI (GciTs*) bindings.

Ported from PharoGemStoneFFI (GciTypes) so the GemStone-Pharo-Bridge can call
the reentrant, session-pointer-based thread-safe GCI without the global
current-session state that the legacy linked GCI relies on.
"
Class {
	#name : 'GbsGciTypes',
	#superclass : 'SharedPool',
	#classVars : [
		'BoolType',
		'CharArray1025',
		'OopType',
		'OopTypeArray10'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'class initialization' }
GbsGciTypes class >> initialize [
	"GbsGciTypes initialize"
	OopType := #uint64.
	OopTypeArray10 := FFIArray newArrayTypeOf: #uint64 size: 10.
	CharArray1025 := FFIArray newArrayTypeOf: #char size: 1025.
	BoolType := #int32
]
