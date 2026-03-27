Extension { #name : 'BasicInspector' }

{ #category : '*GbsToolsOverrides-Extensions' }
BasicInspector >> refresh
[
	"Overridden so dynamicInstVars are visible. The must be added
	before the refresh, but after the namedFields."

	fixedFields := (Array with: self selfAttribute) , self derivedFields
				, self namedFields , self dynamicInstVarFields.
	super refresh
]

