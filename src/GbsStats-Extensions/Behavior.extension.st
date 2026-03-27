Extension { #name : 'Behavior' }

{ #category : '*GbsStats-Extensions' }
Behavior >> gbxBytesCached
[

	"A Behavior is not typically faulted into the client at runtime - it preexists in
	 the image, and therefore is not considered to be cached (though there is
	 a mapping in the GBS structures to associated it with a GemStone behavior)."

	^0
]

