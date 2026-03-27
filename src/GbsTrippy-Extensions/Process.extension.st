Extension { #name : 'Process' }

{ #category : '*GbsTrippy-Extensions' }
Process >> inspectorExtraAttributes
[
	
	^Array
		with:
			(Tools.Trippy.TextAttribute
				label: #identityHash
				text: self identityHash printString)
]

