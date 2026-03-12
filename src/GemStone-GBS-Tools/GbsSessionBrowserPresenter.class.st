Class {
	#name : 'GbsSessionBrowserPresenter',
	#superclass : 'GbsClassicLauncher',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'initialization' }
GbsSessionBrowserPresenter >> initializeWindow: aWindow [
	super initializeWindow: aWindow.
	aWindow
		title: 'GemStone Session Browser';
		initialExtent: 560@430
]
