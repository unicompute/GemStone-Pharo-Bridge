Extension { #name : 'StPlaygroundPagePresenter' }

{ #category : '*GemStone-GBS-Tools-playground' }
StPlaygroundPagePresenter >> menuActionsFor: aCodePresenter [

	^ CmCommandGroup forSpec
		beRoot;
		register: ((CmCommandGroup named: 'Extra') asSpecGroup
			beDisplayedAsGroup;
			register: (StEvaluateCommand forSpecContext: self);
			yourself);
		register: (aCodePresenter rootCommandsGroup name: 'Code');
		in: [ :this | self addMenuEditionCommandsTo: this presenter: aCodePresenter ];
		in: [ :this | self addMenuCommandsTo: this ];
		register: ((CmCommandGroup named: 'Playground') asSpecGroup
			register: ((CmCommandGroup named: 'Base options') asSpecGroup
				beDisplayedAsGroup;
				in: [ :this | self addToolbarCommandsTo: this ];
				yourself);
			register: ((CmCommandGroup named: 'Miscelaneous options') asSpecGroup
				beDisplayedAsGroup;
				register: (StShowLineNumbersCommand forSpecContext: self);
				yourself);
			yourself);
		register: ((CmCommandGroup named: 'GemStone') asSpecGroup
			beDisplayedAsGroup;
			register: ((CmBlockCommand forSpecContext: self)
				name: 'GS-Do it';
				block: [ GbsPlaygroundActions gsDoItIn: self ];
				yourself);
			register: ((CmBlockCommand forSpecContext: self)
				name: 'GS-Print it';
				block: [ GbsPlaygroundActions gsPrintItIn: self ];
				yourself);
			register: ((CmBlockCommand forSpecContext: self)
				name: 'GS-Inspect it';
				block: [ GbsPlaygroundActions gsInspectItIn: self ];
				yourself);
			register: ((CmBlockCommand forSpecContext: self)
				name: 'GS-Debug it';
				block: [ GbsPlaygroundActions gsDebugItIn: self ];
				yourself);
			register: ((CmBlockCommand forSpecContext: self)
				name: 'GS-File it in';
				block: [ GbsPlaygroundActions gsFileItInIn: self ];
				yourself);
			yourself);
		yourself
]
