Extension { #name : 'Workspace' }

{ #category : '*GbsToolsOverrides-Extensions' }
Workspace class >> windowSpec
[
	"Tools.UIPainter new openOnClass: self andSelector: #windowSpec"

	<resource: #canvas> 
	^#(#{UI.FullSpec} 
		#window: 
		#(#{UI.WindowSpec} 
			#properties: #(#{UI.PropertyListDictionary} #labelFromApplication true ) 
			#label: #label 
			#min: #(#{Core.Point} 250 100 ) 
			#max: #(#{Core.Point} 0 0 ) 
			#bounds: #(#{Graphics.Rectangle} 474 368 1024 768 ) 
			#flags: 4 
			#menu: #menuBarHolder 
			#toolBar: #toolbarHolder ) 
		#component: 
		#(#{UI.SpecCollection} 
			#collection: #(
				#(#{UI.SubCanvasSpec} 
					#layout: #(#{Graphics.LayoutFrame} 0 0 0 0 0 1 -24 1 ) 
					#name: #page 
					#flags: 0 ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} 0 0 -24 1 -41 1 0 1 ) 
					#name: #pageExplanation 
					#model: #pageExplanationHolder 
					#tabable: false 
					#isReadOnly: true ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} -40 1 -24 1 0 1 0 1 ) 
					#name: #importSummary 
					#model: #importSummaryHolder 
					#tabable: false 
					#isReadOnly: true ) ) ) )
]

