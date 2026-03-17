Class {
	#name : #'GbxLateSystem',
	#superclass : #'Subsystem',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'default actions' }
GbxLateSystem >> setUp

	super setUp.
	GbxFinalizer installGbxFinalizer

{ #category : #'prerequisites' }
GbxLateSystem >> prerequisiteSystems
	"Must install the GbxFinalizer *after* the system installs its finalizer."

	^Array with: FinalizationSystem

