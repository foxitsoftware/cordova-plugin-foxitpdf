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
#import <Foundation/Foundation.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>

//A utility class specific for string size calculate function for drawing string
//the font, size is fixed when initialize
//aligment is left
//line break mode is word break
//on May 17, 2012, add new methods for getting last index of wrapper text coreText!

//the margin for UITextView input. the real text width should be UITextView's width-2*UITextView_Margin
#define UITextView_Margin 8.0

@interface StringDrawUtil : NSObject
{
    UIFont *_font;
}

// the font and size used for the whole drawing
- (id)initWithFont:(UIFont *)font;

@property (nonatomic, readonly, assign) float singleLineHeight; //cache for single line height

//cache for getReturnRefinedString, in most case if no new line happen, no need to reculcuate
@property (nonatomic, retain) NSString *previousStr;
@property (nonatomic, retain) NSString *previousRetStr;
@property (nonatomic, assign) float previousHeight;

//is this string seperatable? not seperate for example, English word, symbol
//if English word, return 1
//if symbol, return 2
//if number, return 3
//other return 0
+ (int)isSeparatable:(NSString *)str;
//from the end, reduce one word
+ (NSString *)reductOneWord:(NSString *)str;
//from the begin, get one word
+ (NSString *)startOneWord:(NSString *)str;

//get height within a fixed width
- (float)heightOfContent:(NSString *)content withinWidth:(float)width;
//get width within a fixed height
- (float)widthOfContent:(NSString *)content withinHeight:(float)height;

//get the end string index inside rectangle. if not enough to contain the string, it's the last index; else it's the last index shown in rect.
- (int)stringIndex:(NSString *)content insideSize:(CGSize)size needSufix:(BOOL)isSufix;

//check the string (one character) is a sentence break symbol.  for example: .?!;。？！；
+ (BOOL)isSentenceBreakSymbol:(NSString *)str;

//separate string by the separator.
//it's not same as [NSString componentSeparate] as it will not have empty, and it contains the separator itself.
+ (NSArray *)seperateString:(NSString *)content bySeparator:(NSString *)separator;

//remove the blank character between keyword which will make it can be found.
+ (NSString *)removeBlankBetweenKeyword:(NSString *)content keyword:(NSString *)keyword;

//used for free text annotation. the string is typed in UITextView and need to get a same wrapped string with "\n" inserted at exactly place. 
//use core text to calculate
- (NSString *)getReturnRefinedString:(NSString *)str forUITextViewWidth:(float)width;

//get word range of string, including space, the best part is it supports all language including Chinese
+ (NSArray*)getUnitWordBoundary:(NSString*)str;

@end
