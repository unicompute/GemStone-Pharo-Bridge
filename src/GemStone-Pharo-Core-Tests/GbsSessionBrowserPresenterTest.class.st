Class {
	#name : 'GbsSessionBrowserPresenterTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsSessionBrowserPresenterTest >> testPresenterInheritsClassicLauncher [
	self assert: GbsSessionBrowserPresenter superclass equals: GbsClassicLauncher
]
