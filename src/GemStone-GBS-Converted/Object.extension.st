Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Converted' }
Object >> addExtensionEntryMenuItemsTo: aMenu [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> addExtensionMethodMenuItemsTo: aMenuGroup [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> addExtensionPreviewMenuItemsTo: aMenu [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> addExtensionReportOptionsToLabels: labels actions: actions [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> addExtensionSessionMenuItemsTo: aMenuGroup [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> addExtensionWorkspaceMenuItemsTo: aMenuGroup [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> configureExtensionStructuredInspector: presenter [
	^ self
]

{ #category : '*GemStone-GBS-Converted' }
Object >> gbxConsiderModified [
	"Best-effort Pharo port of the VW dirty-mark hook. If the receiver does not
	participate in the GemBuilder replicate/proxy protocol, this is a no-op."
	| configuration delegate isImmutable |
	configuration := [ GbsConfiguration current ] on: Error do: [ ^ self ].
	(configuration respondsTo: #autoMarkDirty) ifFalse: [ ^ self ].
	configuration autoMarkDirty ifFalse: [ ^ self ].
	isImmutable := (self respondsTo: #gbxIsImmutable)
		ifTrue: [ [ self gbxIsImmutable ] on: Error do: [ false ] ]
		ifFalse: [ false ].
	isImmutable ifFalse: [ ^ self ].
	(self respondsTo: #gbxDelegate) ifFalse: [ ^ self ].
	delegate := [ self gbxDelegate ] on: Error do: [ nil ].
	(delegate notNil and: [ delegate respondsTo: #markStDirty: ])
		ifTrue: [ delegate markStDirty: self ].
	^ self
]
