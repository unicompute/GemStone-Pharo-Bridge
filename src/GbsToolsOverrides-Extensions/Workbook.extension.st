Extension { #name : 'Workbook' }

{ #category : '*GbsToolsOverrides-Extensions' }
Workbook class >> windowSpec
[
	"Tools.UIPainter new openOnClass: self andSelector: #windowSpec"

	<resource: #canvas>
	^#(#{UI.FullSpec} 
		#window: 
		#(#{UI.WindowSpec} 
			#label: 
			#(#{Kernel.UserMessage} 
				#key: #Workspace 
				#defaultString: 'Workspace' 
				#catalogID: #labels ) 
			#min: #(#{Core.Point} 250 100 ) 
			#max: #(#{Core.Point} 0 0 ) 
			#bounds: #(#{Graphics.Rectangle} 1005 520 1555 920 ) 
			#flags: 4 
			#menu: #menuBarHolder 
			#toolBar: #toolbarHolder ) 
		#component: 
		#(#{UI.SpecCollection} 
			#collection: #(
				#(#{UI.TabControlSpec} 
					#layout: #(#{Graphics.LayoutFrame} 0 0 0 0 0 1 -25 1 ) 
					#name: #pages 
					#flags: 0 
					#model: #pageHolder 
					#tabable: true 
					#labels: #() 
					#tabs: #() ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} 0 0 -24 1 -41 1 0 1 ) 
					#name: #pageExplanation 
					#model: #pageExplanationHolder 
					#tabable: false 
					#helpText: 
					#(#{Kernel.UserMessage} 
						#key: #ExplainCurrentPage 
						#defaultString: 'Explanation of the current page' 
						#catalogID: #labels ) 
					#isReadOnly: true ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} -40 1 -24 1 0 1 0 1 ) 
					#name: #importSummary 
					#model: #importSummaryHolder 
					#tabable: false 
					#helpText: 
					#(#{Kernel.UserMessage} 
						#key: #NamespacesImportedHere 
						#defaultString: 'Namespaces imported by this workspace' 
						#catalogID: #labels ) 
					#isReadOnly: true ) ) ) )
]

