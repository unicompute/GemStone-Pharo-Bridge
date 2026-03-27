Extension { #name : 'DocumentInspector' }

{ #category : '*GbsToolsOverrides-Extensions' }
DocumentInspector >> refresh
[
	"Martin wants VW 9.x to preserve the long string truncation that was present in 8.x."

	self documentHolder value: (self gbxTrimLongString: self object)
]

