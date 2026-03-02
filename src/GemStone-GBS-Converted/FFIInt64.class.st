"
I'm an signed int type (64bits)
I map to a longlong type. 
"
Class {
	#name : 'FFIInt64',
	#superclass : 'FFIExternalType',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
FFIInt64 class >> externalType [ ^ FFIInt64
]

{ #category : 'accessing' }
FFIInt64 class >> externalTypeName [ ^ 'long long'
]
