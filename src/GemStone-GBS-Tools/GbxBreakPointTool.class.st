Class {
	#name : 'GbxBreakPointTool',
	#superclass : 'Object',
	#instVars : [
		'breakNumber',
		'compiledMethod',
		'remoteClass',
		'className',
		'selector',
		'displayString',
		'stepPoint',
		'disabled',
		'breakpointLevel'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'comparing' }
GbxBreakPointTool >> = anotherBP
[
	" Answer true if the receiver is functionally equivalent to anotherBP.
	  NOTE:  The value of <displayString> and <stepPoint> changes when the
		breakpoint is switched between enabled and disabled state. "

	self == anotherBP ifTrue: [ ^true ].
	(anotherBP isMemberOf: self class) ifFalse: [ ^false ].
	^ breakNumber = anotherBP breakNumber
		and: [remoteClass = anotherBP remoteClass
		and: [ selector = anotherBP selector ]]
]

{ #category : 'comparing' }
GbxBreakPointTool >> hash
[

	^self identityHash + breakNumber hash + remoteClass hash + selector hash
]

{ #category : 'accessing' }
GbxBreakPointTool >> methodBreakEnablementArray
[
	"Answer a collection of all method breakpoint numbers that are enabled."

	^self compiledMethod session
		evaluateBlock: '
			[:spanSize |
			| all answer |
			all := self _allBreakpoints.
			answer := Array new.
			1 to: all size by: spanSize do: [:i |
				(all at: i + 2) >= 0
					ifTrue: [answer add: (all at: i)]].
			].
			ans'
		with: self allBreakpointsSubArraySpanSize
		context: self compiledMethod
]

{ #category : 'accessing' }
GbxBreakPointTool >> sourceOffsets
[

	^self compiledMethod _sourceOffsets
]

{ #category : 'accessing' }
GbxBreakPointTool >> remoteClass
[

	^remoteClass
]

{ #category : 'accessing' }
GbxBreakPointTool >> methodSourceCode
[

	^self compiledMethod sourceString
]

{ #category : 'accessing' }
GbxBreakPointTool >> displayString
[

	^displayString
]

{ #category : 'accessing' }
GbxBreakPointTool >> compiledMethod
[
	"Answer the actual GsNMethod in which the breakpoint is set."

	^compiledMethod
]

{ #category : 'accessing' }
GbxBreakPointTool >> disabled
[
	"Answer whether the breakpoint was disabled at the time this instance was populated."

	^disabled
]

{ #category : 'accessing' }
GbxBreakPointTool >> stepPoint
[

	^stepPoint
]

{ #category : 'accessing' }
GbxBreakPointTool >> allBreakpointsSubArraySpanSize
[
	"The result from #_allBreakpoints flattens the results for each breakpoint into a single array.
	 Different server versions have different spans for the sub-arrays."

	^GbxServerVersion current atLeast64v37 ifTrue: [4] ifFalse: [3]
]

{ #category : 'accessing' }
GbxBreakPointTool >> breakNumber
[

	^breakNumber
]

{ #category : 'accessing' }
GbxBreakPointTool >> selector
[

	^selector
]

{ #category : 'accessing' }
GbxBreakPointTool >> className
[
	"Answer the name of the class the breakpointed method is in.
	 Metaclasses include ' class' suffix.
	 Executed code reports 'nil'."

	^className
]

{ #category : 'accessing' }
GbxBreakPointTool >> breakpointLevel
[
	"Breakpoint level was added in 3.7 server. It will be nil for earlier versions.
	 Level 0 returns to the GCI.
	 Levels >0 are handled in Smalltalk."

	^breakpointLevel
]

{ #category : 'initialization' }
GbxBreakPointTool >> breakNumber: aSeqNum method: aMethodForwarder classProxy: classProxy className: aClassName selector: aSelector displayString: aString stepPoint: aStepPoint disabled: aBoolean breakpointLevel: anIntegerOrNil
[

	breakNumber := aSeqNum.
	compiledMethod := aMethodForwarder.
	remoteClass := classProxy.
	className := aClassName.
	selector := aSelector.
	stepPoint := aStepPoint.
	displayString := aString.
	disabled := aBoolean.
	breakpointLevel := anIntegerOrNil.
]

{ #category : 'testing' }
GbxBreakPointTool >> isDisabled
[

	^self isEnabled not
]

{ #category : 'testing' }
GbxBreakPointTool >> isEnabled
[


	^self methodBreakEnablementArray includes: self breakNumber
]

{ #category : 'actions' }
GbxBreakPointTool >> clear
[

	self compiledMethod clearBreakAtStepPoint: self stepPoint
]

{ #category : 'list accessing' }
GbxBreakPointTool class >> breakPointListFor: aSession
[
	" Answer a list of instances of the receiver, which describe the current breakpoints from GemStone."

	| list reports |
	aSession isLoggedIn ifFalse: [^#()].
	reports := self fullBreakReportFor: aSession.
	list := OrderedCollection new.
	reports do: 
			[:bpReport |
			list add: (self
						breakNumber: (bpReport at: #breakNumber)
						method: (bpReport at: #method)
						classProxy: (GbxDelegate oopValue: (bpReport at: #classOop) session: aSession)
						className: (bpReport at: #className)
						selector: (bpReport at: #selector)
						displayString: (bpReport at: #displayString)
						stepPoint: (bpReport at: #stepPoint)
						disabled: (bpReport at: #disabled)
						breakpointLevel: (bpReport at: #breakpointLevel))].
	^list
]

{ #category : 'list accessing' }
GbxBreakPointTool class >> fullBreakReportFor: aSession
[
	"Return what we need out of the report without creating stubs for classes"

	| array details displayStrings |
	array := aSession
				evaluate: '
		| everything result  reports |
		"Handle older server versions which do not tolerate breaks in unbound methods. See bug #49650."
		everything := [GsNMethod _breakReport: true]
						on: MessageNotUnderstood
						do: [:mnu |
							"Resume to make class name report as nil. We cannot do anything about
							 reporting the nil selector, as the error occurs inside an #addAll:. Just resume
							 it; the arg will be ignored."
							(mnu receiver isNil and: [mnu selector = #name or: [mnu selector = #do:]])
								ifTrue: [mnu resume: ''nil''].
							mnu pass].
"In 3.7, the Array is 
   { <break report string as displayed in topaz, one line per breakpoint> .
      { { <breakNumber>. <class> . <selector>. <stepPoint>. <GsNMethod> . <disabledBoolean> . <breakpointLevel>}.
        ...
        {<breakNumber>. <class> . <selector>. <stepPoint>. <GsNMethod> . <disabledBoolean> . <breakpointLevel>}
      }
   }
breakpointLevel is new in 3.7.0."
		reports := everything at: 2.
		result := Array new.
		1 to: reports size do:[:idx |
			| rep bpDetails |
			rep := reports at: idx.
			bpDetails := Dictionary new.
			bpDetails at: #breakNumber put: (rep at: 1).
			bpDetails at: #classOop put: (rep at: 2) asOop.
			bpDetails at: #className put: (rep at: 2) printString.
			bpDetails at: #selector put: (rep at: 3).
			bpDetails at: #stepPoint put: (rep at: 4).
			bpDetails at: #method put: (rep at: 5).
			bpDetails at: #disabled put: (rep at: 6).
			bpDetails at: #breakpointLevel put: (rep at: 7 ifAbsent: [nil]).	"Added in 3.7 server version"
			result add: bpDetails].
		Array with: (everything at: 1) with: result'.
	details := array at: 2.
	displayStrings := (array at: 1) gbxAsArrayOfLines.
	"There can be more 'display strings' than details when there are no breakpoints set."
	details doWithIndex: [:eachDetail :index | eachDetail at: #displayString put: (displayStrings at: index) trimSeparators].
	^details
]

{ #category : 'instance creation' }
GbxBreakPointTool class >> breakNumber: aSeqNum method: aMethodForwarder classProxy: classProxy className: aClassName selector: aSelector displayString: aString stepPoint: aStepPoint disabled: aBoolean breakpointLevel: anIntegerOrNil
[
	"Answer an instance of the receiver with the specified values."

	^self new
		breakNumber: aSeqNum
		method: aMethodForwarder
		classProxy: classProxy
		className: aClassName
		selector: aSelector
		displayString: aString
		stepPoint: aStepPoint
		disabled: aBoolean
		breakpointLevel: anIntegerOrNil
]

