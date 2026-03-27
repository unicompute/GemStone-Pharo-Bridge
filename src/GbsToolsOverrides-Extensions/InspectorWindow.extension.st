Extension { #name : 'InspectorWindow' }

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorWindow >> doItReceiver
[
	"Answer the object in which context the text selection is evaluated."
	"the doItReceiver should be the object except for GbxInspectionWrappers which then return the localObject.
	 The inspector can choose to have a different doItReceiver if need be.
	 See Inspector>>doItReceiver which returns the object"

	^super doItReceiver
]

{ #category : '*GbsToolsOverrides-Extensions' }
InspectorWindow class >> toolbar
[
	"Tools.MenuEditor new openOnClass: self andSelector: #toolbar"

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

