Class {
	#name : 'AbstractWorkspace',
	#superclass : 'ApplicationModel',
	#instVars : [
		'locals',
		'importAll',
		'specificImports',
		'importSummaryHolder',
		'pageExplanationHolder',
		'statusBarVisible',
		'encodingChannel',
		'menuBarHolder',
		'toolbarHolder'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'initialize-release' }
AbstractWorkspace >> postBuildWith: aBuilder
[
	builder window
		application: self;
		sendWindowEvents: #(#reopen).

	GBSM
		whenAny: #(#gbxSessionRemoved #gbxSessionAdded)
		send: #refreshToolbar
		to: self
]

