Extension { #name : 'DebuggerClient' }

{ #category : '*GbsToolsOverrides-Extensions' }
DebuggerClient >> buttonEnablement
[

	| container edc priority notTerminated canIssueContextCommand |
	builder == nil ifTrue: [^self].
	container := self isToolbarBelowContexts
				ifTrue: [(builder componentAt: #toolbarHolder) widget]
				ifFalse: [builder componentAt: #toolbarMenu].
	edc := self enableDebugCommand.
	notTerminated := self isTerminated not.
	canIssueContextCommand := self canIssueContextCommand.
	(container componentAt: #step)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand].
	(container componentAt: #send)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand & (contextIndex = 1)].
	(container componentAt: #stepIntoBlock)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand & (contextIndex = 1)].
	(container componentAt: #skip)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand].
	(container componentAt: #return)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand].
	(container componentAt: #reenter)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand].
	(container componentAt: #jumpToCaret)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand].
	(container componentAt: #firstLoop)
		ifNotNil: [:c | c isEnabled: canIssueContextCommand].
	(container componentAt: #nextLoop)
		ifNotNil: 
			[:c |
			c isEnabled: (canIssueContextCommand and: [service hasLoopControlContext])].
	(container componentAt: #selectHome)
		ifNotNil: 
			[:c |
			c isEnabled: (canIssueContextCommand
						and: [service isMethodContextSelected not])].
	(container componentAt: #continue)
		ifNotNil: [:c | c isEnabled: notTerminated & busy not].
	(builder componentAt: #stackList) ifNotNil: [:c | c isEnabled: busy not].
	(container componentAt: #inspectContext) ifNotNil: [:c | c isEnabled: edc].
	(container componentAt: #pause) ifNotNil: [:c | c isEnabled: busy].
	self textWidget isEnabled: edc.
	priority := self notBusy
				ifTrue: [Processor userSchedulingPriority]
				ifFalse: [Processor lowIOPriority - 1].
	builder window windowProcess == nil
		ifFalse: [builder window windowProcess priority: priority]	"GBS override, a sufficiently fast closing of a window may have already removed the windowProcess by the time this message is sent"
]

{ #category : '*GbsToolsOverrides-Extensions' }
DebuggerClient class >> menuBarMenu
[
	"Tools.MenuEditor new openOnClass: self andSelector: #menuBarMenu"

	<resource: #menu>
	^#(#{UI.Menu} #(
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Stack 
					#defaultString: '&Stack' 
					#catalogID: #pdp ) 
				#nameKey: #stackMenu ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Method 
					#defaultString: '&Method' 
					#catalogID: #pdp ) 
				#submenu: #(#{UI.Menu} #(
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #_Browse 
								#defaultString: '&Browse' 
								#catalogID: #pdp ) 
							#nameKey: #browseMethod 
							#value: #browseMethod 
							#enablementSelector: #hasValidContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #_Senders 
								#defaultString: '&Senders' 
								#catalogID: #pdp ) 
							#nameKey: #allSenders 
							#value: #browseAllSenders 
							#enablementSelector: #hasValidContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #_Implementors 
								#defaultString: '&Implementors' 
								#catalogID: #pdp ) 
							#nameKey: #allImplementors 
							#value: #browseAllImplementors 
							#enablementSelector: #hasValidContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #HierarchySe_nders 
								#defaultString: 'Hierarchy Se&nders' 
								#catalogID: #pdp ) 
							#nameKey: #localSenders 
							#value: #browseLocalSenders 
							#enablementSelector: #hasValidContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #HierarchyI_mplementors 
								#defaultString: 'Hierarchy I&mplementors' 
								#catalogID: #pdp ) 
							#nameKey: #localImplementors 
							#value: #browseLocalImplementors 
							#enablementSelector: #hasValidContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #Re_vertDots 
								#defaultString: 'Re&vert...' 
								#catalogID: #pdp ) 
							#nameKey: #revert 
							#value: #revert 
							#enablementSelector: #enableClientDebugCommand  ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #Browse_Versions 
								#defaultString: 'Browse &Versions' 
								#catalogID: #pdp ) 
							#nameKey: #browseVersions 
							#value: #browseVersions 
							#enablementSelector: #hasValidClientContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #ShowContaining_PackageDots 
								#defaultString: 'Show Containing &Package...' 
								#catalogID: #pdp ) 
							#nameKey: #containingPackage 
							#value: #containingPackage 
							#enablementSelector: #hasValidClientContext ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #_RecompileWithFullBlocks 
								#defaultString: '&Recompile with Full Blocks' 
								#catalogID: #pdp ) 
							#nameKey: #makeFullMethod 
							#value: #makeFullMethod 
							#enablementSelector: #canRecompileBlocks ) ) #(1 2 2 3 1 ) nil ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Edit 
					#defaultString: '&Edit' 
					#catalogID: #pdp ) 
				#nameKey: #editMenu ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #E_xecute 
					#defaultString: 'E&xecute' 
					#catalogID: #pdp ) 
				#nameKey: #executeMenu ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Correct 
					#defaultString: '&Correct' 
					#catalogID: #pdp ) 
				#submenu: #(#{UI.Menu} #(
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #_DefineMethod 
								#defaultString: '&Define Method' 
								#catalogID: #pdp ) 
							#nameKey: #defineMethod 
							#value: #defineMethod 
							#enablementSelector: #canDefineMethod 
							#shortcutKeyCharacter: #F4 
							#shortcutModifiers: 0 ) 
						#(#{UI.MenuItem} 
							#rawLabel: 
							#(#{Kernel.UserMessage} 
								#key: #_CorrectSelector 
								#defaultString: '&Correct Selector' 
								#catalogID: #pdp ) 
							#nameKey: #correctSpelling 
							#value: #correctSpelling 
							#enablementSelector: #canCorrectSpelling 
							#shortcutKeyCharacter: #F4 
							#shortcutModifiers: 2 ) ) #(2 ) nil ) ) ) #(5 ) nil ) decodeAsLiteralArray
]

{ #category : '*GbsToolsOverrides-Extensions' }
DebuggerClient class >> contextMenu
[
	"Tools.MenuEditor new openOnClass: self andSelector: #contextMenu"

	<resource: #menu>
	^#(#{UI.Menu} #(
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Browse 
					#defaultString: '&Browse' 
					#catalogID: #pdp ) 
				#nameKey: #browseMethod 
				#value: #browseMethod 
				#enablementSelector: #hasValidContext ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Senders 
					#defaultString: '&Senders' 
					#catalogID: #pdp ) 
				#nameKey: #allSenders 
				#value: #browseAllSenders 
				#enablementSelector: #hasValidContext ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #I_mplementors 
					#defaultString: 'I&mplementors' 
					#catalogID: #pdp ) 
				#nameKey: #allImplementors 
				#value: #browseAllImplementors 
				#enablementSelector: #hasValidContext ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #HierarchySe_nders 
					#defaultString: 'Hierarchy Se&nders' 
					#catalogID: #pdp ) 
				#nameKey: #localSenders 
				#value: #browseLocalSenders 
				#enablementSelector: #hasValidContext ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #HierarchyIm_plementors 
					#defaultString: 'Hierarchy Im&plementors' 
					#catalogID: #pdp ) 
				#nameKey: #localImplementors 
				#value: #browseLocalImplementors 
				#enablementSelector: #hasValidContext ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Select_HomeContext 
					#defaultString: 'Select &Home Context' 
					#catalogID: #pdp ) 
				#value: #selectHomeContext 
				#enablementSelector: #canSelectHome 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.DebuggerIcons} #homeContext ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_CorrectSelector 
					#defaultString: '&Correct Selector' 
					#catalogID: #pdp ) 
				#nameKey: #correctSpelling 
				#value: #correctSpelling 
				#enablementSelector: #canCorrectSpelling ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_DefineMethod 
					#defaultString: '&Define Method' 
					#catalogID: #pdp ) 
				#nameKey: #defineMethod 
				#value: #defineMethod 
				#enablementSelector: #canDefineMethod ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Inspect 
					#defaultString: '&Inspect' 
					#catalogID: #pdp ) 
				#nameKey: #inspectContext 
				#value: #inspectContext 
				#enablementSelector: #hasValidContext 
				#labelImage: #(#{UI.ResourceRetriever} #{Tools.DebuggerIcons} #inspector ) ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Browse_Versions 
					#defaultString: 'Browse &Versions' 
					#catalogID: #pdp ) 
				#nameKey: #browseVersions 
				#value: #browseVersions 
				#enablementSelector: #hasValidClientContext ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #Re_vertDots 
					#defaultString: 'Re&vert...' 
					#catalogID: #pdp ) 
				#nameKey: #revert 
				#value: #revert 
				#enablementSelector: #enableClientDebugCommand ) 
			#(#{UI.MenuItem} 
				#rawLabel: 
				#(#{Kernel.UserMessage} 
					#key: #_Bookmark 
					#defaultString: '&Bookmark' 
					#catalogID: #pdp ) 
				#nameKey: #bookmarkMenu ) ) #(1 2 2 4 2 1 ) nil ) decodeAsLiteralArray
]

