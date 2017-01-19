/**
 * Copyright (C) 2003-2016, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to 
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement 
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.

 */
#import "StringDrawUtil.h"
#import <CoreText/CoreText.h>

@implementation StringDrawUtil

@synthesize singleLineHeight = _singleLineHeight;
@synthesize previousStr = _previousStr;
@synthesize previousRetStr = _previousRetStr;
@synthesize previousHeight = _previousHeight;

#pragma mark - life cycle

- (id)initWithFont:(UIFont *)font
{
    if(self = [super init])
    {
        _font = font;
        _singleLineHeight = -1;  
        
        _previousStr = @"";
        _previousRetStr = @"";
        _previousHeight = 0;
    }
    return self;
}

- (void)dealloc
{
    [_previousStr release];
    [_previousRetStr release];
    
    [super dealloc];
}

#pragma mark - functions

//cache for single line height
- (float)singleLineHeight
{
    if(_singleLineHeight == -1)
    {
        _singleLineHeight = [self heightOfContent:@"A" withinWidth:100.0/*large enough*/];
    }
    return _singleLineHeight;
}

//is this string seperatable? not seperate for example, English word, symbol
//if English word, return 1
//if symbol, return 2
//if number, return 3
//other return 0
+ (int)isSeparatable:(NSString *)str
{
    if((([str compare:@"a"] == NSOrderedDescending || [str compare:@"a"] == NSOrderedSame) && ([str compare:@"z"] == NSOrderedAscending || [str compare:@"z"] == NSOrderedSame))
       || (([str compare:@"A"] == NSOrderedDescending || ([str compare:@"A"] == NSOrderedSame)) && ([str compare:@"Z"] == NSOrderedAscending || [str compare:@"Z"] == NSOrderedSame)))
    {
        return 1;
    }
    if([str compare:@"."] == NSOrderedSame
       || [str compare:@"。"] == NSOrderedSame
       || [str compare:@","] == NSOrderedSame
       || [str compare:@"，"] == NSOrderedSame
       || [str compare:@"?"] == NSOrderedSame
       || [str compare:@"？"] == NSOrderedSame
       || [str compare:@"!"] == NSOrderedSame
       || [str compare:@"！"] == NSOrderedSame       
       || [str compare:@")"] == NSOrderedSame
       || [str compare:@"）"] == NSOrderedSame
       || [str compare:@"]"] == NSOrderedSame
       || [str compare:@"］"] == NSOrderedSame
       || [str compare:@"}"] == NSOrderedSame
       || [str compare:@"｝"] == NSOrderedSame
       || [str compare:@">"] == NSOrderedSame
       || [str compare:@"》"] == NSOrderedSame
       || [str compare:@"%"] == NSOrderedSame
       || [str compare:@"％"] == NSOrderedSame)
    {
        return 2;
    }
    if(([str compare:@"0"] == NSOrderedDescending || [str compare:@"0"] == NSOrderedSame) && ([str compare:@"9"] == NSOrderedAscending || [str compare:@"9"] == NSOrderedSame))
    {
        return 3;
    }
    return 0;
}

//from the end, reduce one word
+ (NSString *)reductOneWord:(NSString *)str
{
    if(str.length < 2)
    {
        return str;  //length=1 or 0, just return it.
    }
    long firstIndex = str.length-1;
    NSString *firstChar;
    long nextIndex = str.length-2;
    NSString *nextChar;
    //cannot seperate if:
    //first is English, next is English    
    //first is symbol, next is anything
    //first is number, next is number
    while (nextIndex >= 0)
    {
        firstChar = [str substringWithRange:NSMakeRange(firstIndex, 1)];
        nextChar = [str substringWithRange:NSMakeRange(nextIndex, 1)];
        if(([StringDrawUtil isSeparatable:firstChar] == 2)  //next is symbol
           ||([StringDrawUtil isSeparatable:firstChar] == 1 && [StringDrawUtil isSeparatable:nextChar] == 1)  //two is English
           ||([StringDrawUtil isSeparatable:firstChar] == 3 && [StringDrawUtil isSeparatable:nextChar] == 3)) //two is number
        {
            firstIndex--;
            nextIndex--;            
        }
        else 
        {
            break;
        }
    }
    return [str substringToIndex:firstIndex];    
}

+ (NSString *)startOneWord:(NSString *)str
{
    if(str.length < 2)
    {
        return str;  //length=1 or 0, just return it.
    }
    int firstIndex = 0;
    NSString *firstChar;
    int nextIndex = 1;
    NSString *nextChar;
    //cannot seperate if:
    //first is English, next is English
    //first is number, next is number
    //first is anything, next is symbol
    while (nextIndex < str.length)
    {
        firstChar = [str substringWithRange:NSMakeRange(firstIndex, 1)];
        nextChar = [str substringWithRange:NSMakeRange(nextIndex, 1)];
        if(([StringDrawUtil isSeparatable:nextChar] == 2)  //next is symbol
           ||([StringDrawUtil isSeparatable:firstChar] == 1 && [StringDrawUtil isSeparatable:nextChar] == 1) //two is English
           ||([StringDrawUtil isSeparatable:firstChar] == 3 && [StringDrawUtil isSeparatable:nextChar] == 3))//two is number
        {
            firstIndex++;
            nextIndex++;            
        }
        else 
        {
            break;
        }
    }
    return [str substringToIndex:firstIndex+1];
}

//get height within a fixed width
- (float)heightOfContent:(NSString *)content withinWidth:(float)width
{
    CGSize constraintSize = CGSizeMake(width, 10000.0/*large enough*/);
    CGSize realSize = [content sizeWithFont:_font constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
	return realSize.height;   
}

//get width within a fixed height
- (float)widthOfContent:(NSString *)content withinHeight:(float)height;
{
    CGSize constraintSize = CGSizeMake(10000.0/*large enough*/, height);
    CGSize realSize = [content sizeWithFont:_font constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
	return realSize.width;
}

//get the end string index inside rectangle. if not enough to contain the string, it's the last index; else it's the last index shown in rect.
//this one does NOT use core text to calculate, because it needs to append sufix as needed, and core text is good for fixed strings. 
//this method only used for guess search result, and the real draw uses RTLabel which uses coreText, so the result is right. 
- (int)stringIndex:(NSString *)content insideSize:(CGSize)size needSufix:(BOOL)isSufix
{
    float wholeHeight = [self heightOfContent:content withinWidth:size.width];
    //Easies situation. The rectangle can contain all the strings. No need other things to do.
    if (wholeHeight <= size.height)
    {
        return (int)content.length-1;  //return the last character index.
    }
    //drawing string is more than rect can contain. calculate the line number till drawing string is one more line than rect.
    int rectLineNum = size.height / self.singleLineHeight;
    //cannot put even a line, return the empty string, that is end is start
    if(rectLineNum == 0)
    {
        return -1;  //cannot hold even one word
    }
    NSString *drawingStr = content;
    int drawingStrLineNum = wholeHeight / self.singleLineHeight;
    NSUInteger drawingStrLength;
    NSString *tempDrawStr; 
    float tempHeight = [self heightOfContent:drawingStr withinWidth:size.width];  //here must calculate in case the next while not hit
    while(drawingStrLineNum > rectLineNum+1)
    {
        drawingStrLength = drawingStr.length;
        drawingStrLength = (int)(((float)(rectLineNum+1)*drawingStrLength)/drawingStrLineNum);
        tempDrawStr = [drawingStr substringToIndex:drawingStrLength];  //trim by line rate. this is faster than word compare.
        tempHeight = [self heightOfContent:tempDrawStr withinWidth:size.width];
        drawingStrLineNum = tempHeight / self.singleLineHeight;
        while(drawingStrLineNum < rectLineNum)  //in case trim too much, and not enough to fit the rectLineNum+1 line
        {
            drawingStrLength += 1;
            if(drawingStrLength > drawingStr.length)
            {
                drawingStrLength = drawingStr.length;
            }
            tempDrawStr = [drawingStr substringToIndex:drawingStrLength];  //trim by line rate. this is faster than word compare.
            tempHeight = [self heightOfContent:tempDrawStr withinWidth:size.width];
            drawingStrLineNum = tempHeight / self.singleLineHeight;
        }
        drawingStr = tempDrawStr;
    }   
    //so the drawingStr is just one line more than rectLineNum. Reduce it one word by one word till fit.    
    if(isSufix)
    {
        tempDrawStr = [NSString stringWithFormat:@"%@...", drawingStr];
        tempHeight = [self heightOfContent:tempDrawStr withinWidth:size.width];
    }
    while (tempHeight > size.height)
    { 
        drawingStr = [StringDrawUtil reductOneWord:drawingStr];
        if(isSufix)
        {
            tempDrawStr = [NSString stringWithFormat:@"%@...", drawingStr];
        }
        else 
        {
            tempDrawStr = drawingStr;
        }
        tempHeight = [self heightOfContent:tempDrawStr withinWidth:size.width];
    }
    return (int)drawingStr.length-1;
}

//check the string (one character) is a sentence break symbol.  for example: .?!;。？！；
+ (BOOL)isSentenceBreakSymbol:(NSString *)str
{
    if([str isEqualToString:@"."]
       || [str isEqualToString:@"?"]
       || [str isEqualToString:@"!"]
       || [str isEqualToString:@";"]
       || [str isEqualToString:@"。"]
       || [str isEqualToString:@"？"]
       || [str isEqualToString:@"！"]
       || [str isEqualToString:@"；"])
    {
        return YES;
    }
    else 
    {
        return NO;
    }
}

//separate string by the separator.
//it's not same as [NSString componentSeparate] as it will not have empty, and it contains the separator itself.
+ (NSArray *)seperateString:(NSString *)content bySeparator:(NSString *)separator
{
    //separate the string by highlight
    NSMutableArray *array = [NSMutableArray array];
    NSString *temp = content;
    NSRange rangeFound = [temp rangeOfString:separator options:NSCaseInsensitiveSearch];
    while (rangeFound.length > 0)
    {
        if(rangeFound.location > 0)
        {
            NSString *previousStr = [temp substringToIndex:rangeFound.location];
            [array addObject:previousStr];
        }
        [array addObject:[temp substringWithRange:rangeFound]];
        if(rangeFound.location + rangeFound.length < temp.length)
        {
            temp = [temp substringFromIndex:rangeFound.location+rangeFound.length];
            rangeFound = [temp rangeOfString:separator options:NSCaseInsensitiveSearch];
        }
        else 
        {
            temp = @"";  //no left string
            break;
        }
    }
    if(temp.length != 0)
    {
        [array addObject:temp];
    }
    return [[array retain] autorelease];
}

//remove the blank character between keyword which will make it cannot be found.
//For example, in 乔布斯传, if search 乔布斯, the tempStr found is "Steve Jobs by Walter Isaacson | 史 蒂 夫 • 乔 布 斯 传"
//For unknown reason, the keyword is added " " inside it so cause keyword cannot be found. Here need to remove the " " if can make keyword found.
+ (NSString *)removeBlankBetweenKeyword:(NSString *)content keyword:(NSString *)keyword
{
    if(keyword.length > 1)
    {
        NSMutableArray *removeRange = [NSMutableArray array];  //the final remove range
        NSMutableArray *removePiece = [NSMutableArray array];  //the temp remove range during on comparsion
        NSString *tempStr = content;
        int j = 0;
        BOOL duringComparing = NO;
        //scan the tempStr word one by one
        for(int i = 0; i < tempStr.length; i ++)
        {
            NSString *searchTempStr = [tempStr substringWithRange:NSMakeRange(i, 1)];
            NSString *searchKeywordStr = nil;
            if(j < keyword.length)
            {
                searchKeywordStr = [keyword substringWithRange:NSMakeRange(j, 1)];
            }
            if(!searchKeywordStr)
            {
                j++;
                continue;
            }
            //if found the first keyword character inside tempStr, start marking duringComparing=YES
            if(j==0 && [searchTempStr compare:searchKeywordStr options:NSCaseInsensitiveSearch] == NSOrderedSame)
            {
                duringComparing = YES;
                j++;
                continue;
            }
            if(duringComparing)
            {
                if(j < keyword.length)
                {
                    //found match, go one
                    if([searchTempStr compare:searchKeywordStr options:NSCaseInsensitiveSearch] == NSOrderedSame)
                    {
                        j++;
                    }
                    //found a blank char, ignore in tempStr and remember the position
                    else if([searchTempStr isEqualToString:@" "])
                    {
                        [removePiece addObject:[NSValue valueWithRange:NSMakeRange(i, 1)]];
                    }
                    //found not a blank char and not match to keyword, this comparing fail
                    else 
                    {
                        duringComparing = NO;
                        j = 0;  //reset to keyword begin
                        [removePiece removeAllObjects];
                    }
                }
                else //OK, now the keyword search finish and all match. Recored the result to finial array.
                {
                    [removeRange addObjectsFromArray:removePiece];
                    duringComparing = NO;
                    j = 0;  //reset to keyword begin
                    [removePiece removeAllObjects];
                }
            }
            else 
            {
                //nothing to do
            }
        }
        //OK, compare finish. Delete the blank char from end to start
        for(long i = removeRange.count-1; i >= 0; i --)
        {
            NSValue *rangeValue = [removeRange objectAtIndex:i];
            tempStr = [tempStr stringByReplacingCharactersInRange:[rangeValue rangeValue] withString:@""];
        }
        return tempStr;
    }
    return content;
}

- (NSString *)getReturnRefinedString:(NSString *)str forUITextViewWidth:(float)width
{
    //modify by lsj
//    width -= 2*UITextView_Margin;
    //if it's cleared, return nothing
    if (str.length == 0)
    {
        self.previousStr = @"";
        self.previousRetStr = @"";
        self.previousHeight = 0;
        return _previousRetStr;
    }
    //if cache already has the same string, return cached result
    if ([_previousStr compare:str] == NSOrderedSame)
    {
        return _previousRetStr;
    }
    float height = [self heightOfContent:str withinWidth:width];
    //if just one line, return is self
    if (height == self.singleLineHeight)
    {
        self.previousStr = str;
        self.previousRetStr = str;
        self.previousHeight = height;
        return _previousRetStr;
    }
    //if new string is append some character to the cached string, should consider is new line introduced, if not just return cached result with new character appended; if yes should calculate the return position again.
    NSRange rangeAdd = [str rangeOfString:_previousStr];
    if (rangeAdd.location == 0 && rangeAdd.length == _previousStr.length)
    {
        if (height == _previousHeight)
        {
            NSString *appendStr = [str substringFromIndex:rangeAdd.length];
            self.previousRetStr = [_previousRetStr stringByAppendingString:appendStr];
            self.previousStr = str;
            return _previousRetStr;
        }
    }
    NSRange rangeDel = [_previousStr rangeOfString:str];
    if (rangeDel.location == 0 && rangeDel.length == str.length)
    {
        if (height == _previousHeight)
        {
            self.previousRetStr = [_previousRetStr substringToIndex:(_previousRetStr.length-(_previousStr.length-str.length))];
            self.previousStr = str;
            return _previousRetStr;
        }
    }
    //calculate the return value
    CTFontRef font = CTFontCreateWithName((CFStringRef)_font.fontName, _font.pointSize, NULL);
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:str];
    [attributeStr addAttribute:(id)kCTFontAttributeName value:(id)font range:NSMakeRange(0, str.length)];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributeStr);
    CGPathRef oneLinePath = CGPathCreateWithRect(CGRectMake(0, 0, width, self.singleLineHeight+5/*in big font size if exactly the same height one line can put nothing. expand a little.*/), NULL);
    long pos = 0;
    NSMutableArray *insertRets = [NSMutableArray array];
    while (pos < str.length-1)
    {
        CTFrameRef oneLineFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(pos, 0), oneLinePath, NULL);
        CFIndex endPos = CTFrameGetVisibleStringRange(oneLineFrame).length;
        CFRelease(oneLineFrame);
//        if (OS_ISVERSION9 && !DEVICE_iPHONE) {
            for(long i = pos; i < [str length];i++){
                NSString *newString = [str substringWithRange:NSMakeRange(pos,i - pos + 1)];
                NSDictionary *attrs = @{NSFontAttributeName:_font};
                CGSize textSize  = [newString boundingRectWithSize:CGSizeMake(width*2, self.singleLineHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                if (textSize.width+2 >= width) {
                    endPos = i;
                    break;
                    
                }
                else if ([[str substringWithRange:NSMakeRange(i, 1)] compare:@"\n"] == NSOrderedSame)
                {
                    endPos = i + 1;
                    break;
                }
                else
                {
                    endPos = i;
                }
                if (i == [str length] - 1) {
                    endPos++;
                }
            }
            pos = endPos;
//        }
//        else
//        {
//            pos += MAX(1, endPos);
//        }
        if ([[str substringWithRange:NSMakeRange(pos-1, 1)] compare:@"\n"] != NSOrderedSame) //if user type return here, it's already return, so don't need to add
        {
            [insertRets addObject:[NSNumber numberWithLong:pos]];
        }
        NSAssert(insertRets.count < 1000, @"Infinit loop in calculate return position.");
    }
	CGPathRelease(oneLinePath);
	CFRelease(framesetter);
	CFRelease(font);
	[attributeStr release];
    NSMutableString *modifiedStr = [NSMutableString stringWithString:str];
    if (insertRets.count > 0)
    {
        for (int i = 0; i < insertRets.count; i ++)
        {
            int insertPos = [[insertRets objectAtIndex:i] intValue];
            insertPos += i;
            if (insertPos != modifiedStr.length)  //last one should not insert return
            {
                [modifiedStr insertString:@"\r" atIndex:insertPos];
            }
        }
    }
    self.previousRetStr = modifiedStr;
    self.previousStr = str;
    self.previousHeight = height;
    return _previousRetStr;
}

//get word range of string, including space
+ (NSArray*)getUnitWordBoundary:(NSString*)str
{    
    NSMutableArray *array = [NSMutableArray array];
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, 
                                                             (CFStringRef)str, 
                                                             CFRangeMake(0, [str length]), 
                                                             kCFStringTokenizerUnitWordBoundary, 
                                                             NULL);
    CFStringTokenizerTokenType tokenType = kCFStringTokenizerTokenNone;
    while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone) 
    {
        CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        NSRange range = NSMakeRange(tokenRange.location, tokenRange.length);
        [array addObject:[NSValue valueWithRange:range]];
    }
    if (tokenizer) 
    {
        CFRelease(tokenizer);
    }
    return array;
}
@end
