Extension { #name : 'Window' }

{ #category : '*GbsToolsOverrides-Extensions' }
Window >> checkForEventsViaWindowManager
[
	"Check for events from the sensor."

	self sensor ifNil: [^self].

	"Windows can be opened and closed fast enough that
	 repair events come in after the window has closed.
	 Ignore any that do."
	handle ifNil: [^self].

	self repairDamages
]

