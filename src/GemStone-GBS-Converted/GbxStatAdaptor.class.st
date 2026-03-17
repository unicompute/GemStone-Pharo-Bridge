Class {
	#name : 'GbxStatAdaptor',
	#superclass : 'Object',
	#instVars : [
		'statResource',
		'incrementTimeSelector',
		'incrementCountSelector'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxStatAdaptor >> statResource: aStatResource incrementCountSelector: countSelector incrementTimeSelector: timeSelector

	statResource := aStatResource.
	incrementCountSelector := countSelector.
	incrementTimeSelector := timeSelector

{ #category : 'stat updating' }
GbxStatAdaptor >> incrementTime: delta

	statResource perform: incrementTimeSelector with: delta

{ #category : 'stat updating' }
GbxStatAdaptor >> endCall: startTime 
	"This is called some time after startCall - figure out the elapsed time
	 and increment the time stat (unless the incrementTimeSelector is nil)"

	incrementTimeSelector isNil 
		ifFalse: [self incrementTime: Time gbxClock - startTime]

{ #category : 'stat updating' }
GbxStatAdaptor >> incrementCount

	statResource perform: incrementCountSelector

{ #category : 'stat updating' }
GbxStatAdaptor >> startCall
	"Increment the count and return the current time"

	self incrementCount.
	incrementTimeSelector isNil ifFalse: [^Time gbxClock]

{ #category : 'instance creation' }
GbxStatAdaptor class >> statResource: aStatResource incrementCountSelector: countSelector incrementTimeSelector: timeSelector 
	^super new 
		statResource: aStatResource
		incrementCountSelector: countSelector
		incrementTimeSelector: timeSelector

