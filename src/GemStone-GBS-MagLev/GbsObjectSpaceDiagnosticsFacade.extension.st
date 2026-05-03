Extension { #name : 'GbsObjectSpaceDiagnosticsFacade' }

{ #category : '*GemStone-GBS-MagLev' }
GbsObjectSpaceDiagnosticsFacade class >> defaultWellKnownSessionStateSlotSpecifications [
	^ {
		{ 1.
			'Ruby Compiler State'.
			#(
				'rubycompilerstate'
				'compilerstate'
				'rubystate').
			GbsCompilerStateSessionStateSlot.
			#(#maglev #compiler #threadState) }.
		{ 2.
			'Ruby Child Process Status'.
			#(
				'rubychildprocessstatus'
				'childprocessstatus'
				'childprocstatus').
			GbsThreadStateSessionStateSlot.
			#(#maglev #process #threadState) }.
		{ 3.
			'Ruby Method Definition Target Stack'.
			#(
				'rubymethoddeftargetstack'
				'methoddeftargetstack'
				'deftargetstack').
			GbsStackSessionStateSlot.
			#(#maglev #stack #methodDefinition) }.
		{ 5.
			'Ruby Runtime Module Stack'.
			#(
				'rubyruntimemodulestack'
				'rtmodulestack'
				'modulenesting').
			GbsStackSessionStateSlot.
			#(#maglev #stack #moduleNesting) }.
		{ 6.
			'Ruby Eval Arguments Stack'.
			#(
				'rubyevalargumentsstack'
				'evalargsstack'
				'rubyevalstack').
			GbsStackSessionStateSlot.
			#(#maglev #stack #eval) }.
		{ 7.
			'Ruby Current Method Definition Target'.
			#(
				'rubycurrentmethoddeftarget'
				'currentmethoddeftarget'
				'methoddeftarget').
			GbsThreadStateSessionStateSlot.
			#(#maglev #threadState #methodDefinition) }.
		{ 19.
			'MagLev Finalizer Registry'.
			#(
				'maglevfinalizerregistry'
				'maglevfinalizers'
				'rubyfinalizerregistry'
				'rubymainthreadfinalizerregistry'
				'rubymainthreadfinalizers'
				'rubyfinalizers'
				'objectspacefinalizers'
				'finalizers').
			GbsFinalizerRegistrySessionStateSlot.
			#(#maglev #finalizerRegistry #objectspace) } }
]

{ #category : '*GemStone-GBS-MagLev' }
GbsObjectSpaceDiagnosticsFacade >> maglevFinalizerRegistry [
	^ session maglevFinalizerRegistry
]

{ #category : '*GemStone-GBS-MagLev' }
GbsObjectSpaceDiagnosticsFacade >> finalizerRegistryReport [
	| slot referencers |
	slot := self finalizerRegistrySlot.
	referencers := slot hasInspectableOop
		ifTrue: [ [ session referencesToOop: slot oop ] on: Error do: [ #() ] ]
		ifFalse: [ #() ].
	^ GbsObjectReferencerReport
		diagnostics: self
		targetLabel: slot label
		targetOop: slot oop
		referencers: referencers
]

{ #category : '*GemStone-GBS-MagLev' }
GbsObjectSpaceDiagnosticsFacade >> finalizerRegistrySlot [
	^ self
		slotAtKey: 19
		label: 'MagLev Finalizer Registry'
]
