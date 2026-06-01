Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Converted' }
Object >> gbxConsiderModified [
	"Best-effort Pharo port of the VW dirty-mark hook. If the receiver does not
	participate in the GemBuilder replicate/proxy protocol, this is a no-op."
	| configuration delegate isImmutable |
	(self respondsTo: #gbxDelegate) ifFalse: [ ^ self ].
	delegate := [ self gbxDelegate ] on: Error do: [ nil ].
	(delegate notNil and: [ delegate respondsTo: #markStDirty: ])
		ifFalse: [ ^ self ].
	configuration := [ GbsConfiguration current ] on: Error do: [ ^ self ].
	(configuration respondsTo: #autoMarkDirty) ifFalse: [ ^ self ].
	configuration autoMarkDirty ifFalse: [ ^ self ].
	isImmutable := (self respondsTo: #gbxIsImmutable)
		ifTrue: [ [ self gbxIsImmutable ] on: Error do: [ false ] ]
		ifFalse: [ false ].
	isImmutable ifTrue: [ ^ self ].
	delegate markStDirty: self.
	^ self
]
