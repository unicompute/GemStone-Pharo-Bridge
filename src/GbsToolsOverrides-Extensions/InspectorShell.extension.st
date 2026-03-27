Extension { #name : 'InspectorShell' }

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorShell >> inspect: anObject
[
	| navigator |
	origin := Visit object: anObject.
	self receiveEventsFrom: origin object.
	navigator := NullNavigator visit: origin shell: self.
	trail := OrderedCollection with: navigator.
	current := 1.
	self refresh
]

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorShell >> diveIntoClass
[
	"Dive into the class of the current object."
	"if we are a GemStone inspector, we extract the class differently than if we are a non-GemStone inspector"

	self gbxHasGemStoneTabs
		ifTrue: 
			[self diveInto: (DerivedAttribute label: 'class'
						value: installedNavigator object localObject class)]
		ifFalse: 
			[self diveInto: (DerivedAttribute label: 'class' value: self object class)]
]

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorShell >> diveInto: aPart
[
	"Sent by the current inspector to dive into the part of the
	currently selected object. Because this affects the navigation environment,
	it is the shell's responsibility."

	| visit navigator |
	visit := self visit 
		visitOfPart: aPart
		ifNone: [PartVisit part: aPart owner: self visit inspector: self inspector].
	visit object gbxIsWrapped
		ifTrue: 
			[visit object: visit object inspectedObject owner: self visit	"Rewrap as we may not have all the data for the part yet"].
	navigator := NullNavigator visit: visit shell: self.
	self resetTrailForNew: visit.
	self addToTrail: navigator.
	self refresh
]

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorShell >> refreshToolbar
[

	| toolbar |
	(toolbar := builder componentAt: #toolbar) == nil ifTrue: [^self].
	(toolbar componentAt: #back) ifNotNil: [:widget | widget isEnabled: self canGoBack].
	(toolbar componentAt: #forward) ifNotNil: [:widget | widget isEnabled: self canGoForward].
	(toolbar componentAt: #focus) ifNotNil: [:widget | widget isEnabled: self canFocus].
	(toolbar componentAt: #exploreParts) ifNotNil: [:widget | widget isEnabled: self canExploreParts].	
	(toolbar componentAt: #exploreSiblings) ifNotNil: [:widget | widget isEnabled: self canExploreSiblings].
	(toolbar componentAt: #exploreVisited) ifNotNil: [:widget | widget isEnabled: self notExploringVisited].
	(toolbar componentAt: #refreshGS) ifNotNil: [:widget | widget isVisible: self isGemStoneInspector]
]

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorShell >> diveIntoCollaborator: aCollaborator
[
	"Overridden to allow a collaborator dive to be canceled."

	| collab |
	collab := aCollaborator asPartOf: self object.
	collab value == self gbxCancelToken ifFalse: [self diveInto: collab]
]

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorShell class >> toolbar
[
	"Tools.MenuEditor new openOnClass: self andSelector: #toolbar"
	"GBS override adds both #Eval << #menus >> 'Eval' menu item and the Refresh GS one.
	 The latter is the GBS change. The former copies Eval from the subclass's menu. Not sure why."

	<resource: #menu>
	^#(#{UI.Menu} #(
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Back 
					#defaultString: 'Back' 
					#catalogID: #menus ) 
				#nameKey: #back 
				#value: #back 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #navigatePrevious ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #Back 
					#defaultString: 'Back' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Forward 
					#defaultString: 'Forward' 
					#catalogID: #menus ) 
				#nameKey: #forward 
				#value: #forward 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #navigateNext ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #Forward 
					#defaultString: 'Forward' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Browse 
					#defaultString: '&Browse' 
					#catalogID: #menus ) 
				#nameKey: #objectBrowse 
				#value: #browseClass 
				#labelImage: #(#{UI.ResourceRetriever} #{Refactory.Browser.BrowserIcons} #browseSystem ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Focus 
					#defaultString: 'Focus' 
					#catalogID: #menus ) 
				#nameKey: #focus 
				#value: #exploreFocus 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #modeFocus ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #Focus 
					#defaultString: 'Focus' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #ExploreSiblings 
					#defaultString: 'Explore Siblings' 
					#catalogID: #menus ) 
				#nameKey: #exploreSiblings 
				#value: #exploreSiblings 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #modeSiblings ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #ExploreSiblings 
					#defaultString: 'Explore Siblings' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #ExploreParts 
					#defaultString: 'Explore Parts' 
					#catalogID: #menus ) 
				#nameKey: #exploreParts 
				#value: #exploreParts 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #modeParts ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #ExploreParts 
					#defaultString: 'Explore Parts' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #ExploreVisited 
					#defaultString: 'Explore Visited' 
					#catalogID: #menus ) 
				#nameKey: #exploreVisited 
				#value: #exploreVisited 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #modeHistory ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #ExploreVisited 
					#defaultString: 'Explore Visited' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #All 
					#defaultString: 'All' 
					#catalogID: #menus ) 
				#value: #selectAllFields 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #selectFields ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #SelectAllFields 
					#defaultString: 'Select All Fields' 
					#catalogID: #menus ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Eval 
					#defaultString: 'Eval' 
					#catalogID: #menus ) 
				#value: #toggleEvaluationPane 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.Trippy.InspectorIcons} #toggleEvaluationPane ) 
				#helpText: 
				#(#{Kernel.UserMessage} 
					#key: #ToggleEvaluationPane 
					#defaultString: 'Toggle Evaluation Pane' 
					#catalogID: #menus ) ) 

			#(#{UI.MenuItem} 
				#rawLabel: 'Refresh GS' 
				#nameKey: #refreshGS 
				#value: #inspectedObjectChanged 
				#labelImage: #(#{UI.ResourceRetriever} #{GemStone.Gbs.GbxVisualLauncher} #gemIconInspectorLabel ) 
				#helpText: 'Refresh From GS Server' ) ) #(2 1 4 2 1 ) nil ) decodeAsLiteralArray
]

