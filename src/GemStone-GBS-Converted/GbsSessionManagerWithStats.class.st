Class {
	#name : 'GbsSessionManagerWithStats',
	#superclass : 'GbsSessionManager',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbsSessionManagerWithStats >> initializeStatAdaptors
	"Initialize components that have stat adaptors - enable stats"

	GbxGciCallSequencer gciCallProtectStatAdaptor: (GbxStatAdaptor 
				statResource: stats
				incrementCountSelector: #incGciCallProtectInvocations
				incrementTimeSelector: nil)

{ #category : 'initialize-release' }
GbsSessionManagerWithStats >> newServerInterface

	"Create a new c interface instance to be used by the receiver.  Initialize its stat resource."

	serverInterface := super newServerInterface.
	self initializeStatAdaptors.
	^serverInterface

{ #category : 'reimplemented to update stats' }
GbsSessionManagerWithStats >> sessionListCritical: aBlock

	stats incSessionListProtectInvocations.
	^super sessionListCritical: aBlock

