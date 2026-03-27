Extension { #name : 'Visit' }

{ #category : '*GbsTrippy-Extensions' }
Visit >> setObject: anObject
[
	"change the object underneath without disturbing the owner. Used for gs parts"

	object := Tools.Trippy.Inspector wrappedOrNot: anObject
]

{ #category : '*GbsTrippy-Extensions' }
Visit >> resetObjectWhileSessionTerminating: anObject
[
	"if we don't want to try to wrap up the object, such
	as when the session is terminating, then use this.

	private to GBS"

	object := anObject
]

