Class {
	#name : 'Notifier',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
Notifier class >> current [
	^ self new
]

{ #category : 'opening' }
Notifier >> openOnHandle: aProcessHandle label: aString [
	"Compatibility stub for the old VW process debugger hook."
	^ self
]
