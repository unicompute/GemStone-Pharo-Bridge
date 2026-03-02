Extension { #name : 'DateAndTime' }

{ #category : '*GemStone-GBS-Converted' }
DateAndTime >> asGemStonePrimitiveArray [
    "Decomposes this DateAndTime into an array of primitive integers 
     that GemStone can easily reconstruct into a DateTime."
    
    ^ Array new: 7 streamContents: [ :stream |
        stream 
            nextPut: self year;
            nextPut: self month;
            nextPut: self dayOfMonth;
            nextPut: self hour;
            nextPut: self minute;
            nextPut: self second;
            nextPut: self offset asSeconds ]
]

{ #category : '*GemStone-GBS-Converted' }
DateAndTime class >> fromGemStonePrimitiveArray: anArray [
    "Reconstructs a DateAndTime from a 7-element primitive array coming from GemStone.
     Array format: #(year month day hour minute second offsetInSeconds)"
    
    ^ self 
        year: (anArray at: 1)
        month: (anArray at: 2)
        day: (anArray at: 3)
        hour: (anArray at: 4)
        minute: (anArray at: 5)
        second: (anArray at: 6)
        offset: (anArray at: 7) seconds
]
