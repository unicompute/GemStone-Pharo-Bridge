Class {
	#name : 'GbsSessionBrowserPresenterTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsSessionBrowserPresenterTest >> testPresenterInheritsClassicLauncher [
	self assert: GbsSessionBrowserPresenter superclass equals: GbsClassicLauncher
]
