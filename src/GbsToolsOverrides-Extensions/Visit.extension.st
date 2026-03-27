Extension { #name : 'Visit' }

{ #category : '*GbsToolsOverrides-Extensions' }
Visit >> object: anObject owner: aVisitOrNil
[
	"GBS: make sure we wrap up delegates if need be"

	object := Tools.Trippy.Inspector wrappedOrNot: anObject.
	owner := aVisitOrNil.
	owner notNil ifTrue: [owner addChild: self]
]

