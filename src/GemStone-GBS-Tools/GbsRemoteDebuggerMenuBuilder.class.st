Class {
	#name : 'GbsRemoteDebuggerMenuBuilder',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerMenuBuilder class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> buildMenuBar [
	^ debugger newMenuBar
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Stack'; subMenu: self stackMenu ].
			group addItem: [ :item | item name: 'Method'; subMenu: self methodMenu ].
			group addItem: [ :item | item name: 'Edit'; subMenu: self editMenu ].
			group addItem: [ :item | item name: 'Execute'; subMenu: self executeMenu ].
			group addItem: [ :item | item name: 'Correct'; subMenu: self correctMenu ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> correctMenu [
	^ debugger newMenu
		addItem: [ :item |
			item
				name: 'Define Method';
				action: [ debugger acceptSourceEdits ] ];
		addItem: [ :item |
			item
				name: 'Correct Selector';
				action: [ debugger correctSelector ] ];
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebuggerMenuBuilder >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerMenuBuilder >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> editMenu [
	^ debugger newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Accepting'; action: [ debugger acceptSourceEdits ] ].
			group addItem: [ :item | item name: 'Format'; action: [ debugger formatSource ] ].
			group addItem: [ :item | item name: 'Insert Breakpoint'; action: [ debugger setBreakPoint ] ].
			group addItem: [ :item | item name: 'Remove This Probe'; action: [ debugger removeBreakPoint ] ].
			group addItem: [ :item | item name: 'GS-Insert Breakpoint'; action: [ debugger setBreakPoint ] ].
			group addItem: [ :item | item name: 'GS-Remove Breakpoint'; action: [ debugger removeBreakPoint ] ].
			group addItem: [ :item | item name: 'GS-Remove All Breakpoints'; action: [ debugger removeAllBreakPoints ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Do it'; action: [ debugger localDoIt ] ].
			group addItem: [ :item | item name: 'Print it'; action: [ debugger localPrintIt ] ].
			group addItem: [ :item | item name: 'Inspect it'; action: [ debugger localInspectIt ] ].
			group addItem: [ :item | item name: 'Debug it'; action: [ debugger localDebugIt ] ].
			group addItem: [ :item | item name: 'GS-Do it'; action: [ debugger gsDoIt ] ].
			group addItem: [ :item | item name: 'GS-Print it'; action: [ debugger gsPrintIt ] ].
			group addItem: [ :item | item name: 'GS-Inspect it'; action: [ debugger gsInspectIt ] ].
			group addItem: [ :item | item name: 'GS-Debug it'; action: [ debugger gsDebugIt ] ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> executeMenu [
	^ debugger newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Step Into'; action: [ debugger stepInto ] ].
			group addItem: [ :item | item name: 'Step'; action: [ debugger step ] ].
			group addItem: [ :item | item name: 'Step Over'; action: [ debugger stepOver ] ].
			group addItem: [ :item | item name: 'Restart'; action: [ debugger restart ] ].
			group addItem: [ :item | item name: 'Run'; action: [ debugger resume ] ].
			group addItem: [ :item | item name: 'Run until Return'; action: [ debugger stepReturn ] ].
			group addItem: [ :item | item name: 'Run with Break Again'; action: [ debugger runWithBreakAgain ] ].
			group addItem: [ :item | item name: 'Run to Caret'; action: [ debugger runToCaret ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Jump to Caret'; action: [ debugger jumpToCaret ] ].
			group addItem: [ :item | item name: 'Return...'; action: [ debugger returnFromFrame ] ].
			group addItem: [ :item | item name: 'Pause'; action: [ debugger pauseProcess ] ].
			group addItem: [ :item | item name: 'Abort GemStone Transaction'; action: [ debugger abortGemStoneTransaction ] ].
			group addItem: [ :item | item name: 'Terminate'; action: [ debugger terminate ] ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> methodMenu [
	^ debugger newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ debugger browseSelectedMethod ] ].
			group addItem: [ :item | item name: 'GS-Senders'; subMenu: debugger gsSendersQuerySubMenu ].
			group addItem: [ :item | item name: 'GS-Implementors'; subMenu: debugger gsImplementorsQuerySubMenu ].
			group addItem: [ :item | item name: 'GS-Hierarchy Senders'; subMenu: debugger gsHierarchySendersQuerySubMenu ].
			group addItem: [ :item | item name: 'GS-Hierarchy Implementors'; subMenu: debugger gsHierarchyImplementorsQuerySubMenu ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Senders'; subMenu: debugger localSendersQuerySubMenu ].
			group addItem: [ :item | item name: 'Implementors'; subMenu: debugger localImplementorsQuerySubMenu ].
			group addItem: [ :item | item name: 'Hierarchy Senders'; subMenu: debugger localHierarchySendersQuerySubMenu ].
			group addItem: [ :item | item name: 'Hierarchy Implementors'; subMenu: debugger localHierarchyImplementorsQuerySubMenu ].
			group addItem: [ :item | item name: 'Show Containing Package...'; action: [ debugger showContainingPackage ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Recompile with Full Blocks'; action: [ debugger acceptSourceEdits ] ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> sourceMenu [
	| menu |
	menu := debugger newMenu.
	menu addGroup: [ :group |
		debugger configureMenuItem: group named: 'GS-Do it' action: [ debugger gsDoIt ] enabled: true.
		debugger configureMenuItem: group named: 'GS-Print it' action: [ debugger gsPrintIt ] enabled: true.
		debugger configureMenuItem: group named: 'GS-Inspect it' action: [ debugger gsInspectIt ] enabled: true.
		debugger configureMenuItem: group named: 'Accept/Recompile' action: [ debugger acceptSourceEdits ] enabled: debugger canAcceptRecompile ].
	menu addGroup: [ :group |
		debugger configureMenuItem: group named: 'Toggle Breakpoint' action: [ debugger toggleBreakPoint ] enabled: debugger canToggleBreakpoint.
		debugger configureMenuItem: group named: 'Set Breakpoint' action: [ debugger setBreakPoint ] enabled: debugger canSetBreakpoint.
		debugger configureMenuItem: group named: 'Remove Breakpoint' action: [ debugger removeBreakPoint ] enabled: debugger canRemoveBreakpoint.
		debugger configureMenuItem: group named: 'Remove All Breakpoints' action: [ debugger removeAllBreakPoints ] enabled: debugger canRemoveAllBreakpoints ].
	menu addGroup: [ :group |
		debugger configureMenuItem: group named: 'Inspect Receiver' action: [ debugger inspectReceiver ] enabled: debugger canInspectReceiver.
		debugger configureMenuItem: group named: 'Inspect Process' action: [ debugger inspectProcess ] enabled: debugger canInspectProcess.
		debugger configureMenuItem: group named: 'Inspect Frame' action: [ debugger inspectFrame ] enabled: debugger canInspectFrame.
		debugger configureMenuItem: group named: 'Inspect Variable' action: [ debugger inspectVariable ] enabled: debugger canInspectVariable ].
	^ menu
]

{ #category : 'menus' }
GbsRemoteDebuggerMenuBuilder >> stackMenu [
	^ debugger newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Copy Stack Report'; action: [ debugger copyStackReport ] ].
			group addItem: [ :item | item name: 'Show More'; action: [ debugger showMoreContexts ] ].
			group addItem: [ :item | item name: 'Filter Stack'; action: [ debugger toggleFilterStack ] ].
			group addItem: [ :item | item name: 'Select Home Context'; action: [ debugger selectHomeContext ] ].
			group addItem: [ :item | item name: 'Inspect Context'; action: [ debugger inspectFrame ] ].
			group addItem: [ :item | item name: 'Inspect Stack'; action: [ debugger inspectStack ] ].
			group addItem: [ :item | item name: 'Bookmark Context'; action: [ debugger bookmarkContext ] ].
			group addItem: [ :item | item name: 'Clear Bookmark'; action: [ debugger clearBookmarkContext ] ].
			group addItem: [ :item | item name: 'Inspect Process'; action: [ debugger inspectProcess ] ].
			group addItem: [ :item | item name: 'Show Glue'; action: [ debugger toggleGlueHiding ] ] ];
		yourself
]
