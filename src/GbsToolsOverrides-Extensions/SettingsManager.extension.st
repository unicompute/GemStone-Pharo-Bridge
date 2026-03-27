Extension { #name : 'SettingsManager' }

{ #category : '*GbsToolsOverrides-Extensions' }
SettingsManager >> acceptAllPages
[

	[triggerChannel value: true] on: InvalidSettingValueError
		do: [:ex | ex resume].
	pageListHolder list do: [:wrapper | wrapper value accepted].
	self showAcceptedStateUI
]

{ #category : '*GbsToolsOverrides-Extensions' }
SettingsManager >> pageSelected
[

	| page |
	page := self pageListHolder selection.
	page isNil ifTrue: [^self].
	page gbxWasSelected.
	(self widgetAt: #GroupBox) label: ((LabelAndIcon with: page label)
				offset: 2 @ 0;
				icon: page listIcon).
	page builder: nil.
	(self widgetAt: #Subcanvas)
		client: page
		spec: page spec
		builder: self builder newSubBuilder.
	self enlargeWindowIfContentDoesNotFit.
]

