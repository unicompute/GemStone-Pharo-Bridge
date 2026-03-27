Extension { #name : 'GbxLargeIdentityDictionary' }

{ #category : '*GbsTrippy-Extensions' }
GbxLargeIdentityDictionary >> inspect
[
	"If shift is down, bring up the non-Trippy inspector. Then use alt for pre-trippy behavior special behavior"

	| inspectorClass |
	InputState default altDown 
		ifTrue: 
			[inspectorClass := InputState default altDown 
						ifTrue: [nil inspectorClass]
						ifFalse: [Dictionary new inspectorClass].
			GBSM showBusyWhile: [inspectorClass openOn: self]]
		ifFalse: [super inspect]
]

