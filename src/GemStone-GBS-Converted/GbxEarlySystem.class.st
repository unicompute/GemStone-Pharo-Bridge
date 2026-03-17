Class {
	#name : 'GbxEarlySystem',
	#superclass : 'Subsystem',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxEarlySystem >> canActivate
[
	"If GBSM is not available we don't activate the GbxSystem. 
	An example is loading GBS from parcel or Store where we can't set up GBSM until
	GBS is completely loaded."

	^(self gbxResolve: #GBSM)
		ifNil: [false]
		ifNotNil: [:gbsm | gbsm isInitialized == true "legitimate values are true, false, or nil"]
]

{ #category : 'actions' }
GbxEarlySystem >> setUp
[

	super setUp.
	GbxGciCallSequencer nilPrimInterface.
	GBSM gbsImageStartup
]

{ #category : 'actions' }
GbxEarlySystem >> tearDown
[

	super tearDown.
	GBSM ifNotNil: [GBSM aboutToQuit]
]

{ #category : 'prerequisites' }
GbxEarlySystem >> prerequisiteSystems
[

	^Array with: EarlyInterestNotificationSystem
]

{ #category : 'options' }
GbxEarlySystem class >> activationEvent
[
	"If this system reacts to system events, which system event should cause it to activate"

	^#earlySystemInstallation.
]

