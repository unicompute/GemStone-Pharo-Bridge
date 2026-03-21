[
	(Smalltalk at: #GbsPharoBootstrap ifAbsent: [ nil ])
		ifNil: [
			Transcript show: 'REPAIR_ERROR: GbsPharoBootstrap not present in image'; cr ]
		ifNotNil: [ :bootstrap |
			bootstrap activateCompatibilityInCurrentImage.
			Transcript show: 'REPAIR_OK'; cr ].
] on: Error do: [ :ex |
	Transcript show: 'REPAIR_ERROR: ', ex messageText; cr
].

Smalltalk snapshot: true andQuit: true
