//
//  CTGradient.m
//
//  Created by Chad Weider on 12/3/05.
//  Copyright (c) 2005 Cotingent.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "CTGradient.h"

@interface CTGradient (Private)
- (void)_commonInit;
- (void)addElement:(CTGradientElement*)newElement;

- (CTGradientElement *)elementAtIndex:(unsigned)index;

- (CTGradientElement)removeElementAtIndex:(unsigned)index;
- (CTGradientElement)removeElementAtPosition:(float)position;
@end


@implementation CTGradient

/////////////////////////////////////Initialization Type Stuff
void linearEvaluation (void *info, const float *in, float *out);
static const CGFunctionCallbacks _CTLinearGradientFunction = { 0, &linearEvaluation, NULL };	//Version, evaluator function, cleanup function

- (id)init
  {
  self = [super init];
  
  if (self != nil)
	{
	[self _commonInit];
	}
  return self;
  }

- (void)_commonInit
  {
  elementList = nil;
	
  static const float input_value_range   [2] = { 0, 1 };						//range  for the evaluator input
  static const float output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };		//ranges for the evaluator output (4 returned values)
  
  gradientFunction = CGFunctionCreate(&elementList,					//the two transition colors
									  1, input_value_range,			//number of inputs (just fraction of progression)
									  4, output_value_ranges,		//number of outputs RGBa
									  &_CTLinearGradientFunction);	//info for using the evaluator funtion
  }

- (void)dealloc
  {
  CGFunctionRelease(gradientFunction);
  
  CTGradientElement *elementToRemove = elementList;
  while(elementList != nil)
	{
	elementToRemove = elementList;
	elementList = elementList->nextElement;
	free(elementToRemove);
	}
  
  [super dealloc];
  }

- (id)copyWithZone:(NSZone *)zone
  {
  CTGradient *copy = [[[self class] allocWithZone:zone] init];
  
  //now just copy my elementlist
  CTGradientElement *currentElement = elementList;
  while(currentElement != nil)
	{
	[copy addElement:currentElement];
	currentElement = currentElement->nextElement;
	}
  
  return copy;
  }

- (void)encodeWithCoder:(NSCoder *)coder
  {
  if([coder allowsKeyedCoding])
	{
	unsigned count = 0;
	CTGradientElement *currentElement = elementList;
	while(currentElement != nil)
		{
		[coder encodeValueOfObjCType:@encode(float) at:&(currentElement->red)];
		[coder encodeValueOfObjCType:@encode(float) at:&(currentElement->green)];
		[coder encodeValueOfObjCType:@encode(float) at:&(currentElement->blue)];
		[coder encodeValueOfObjCType:@encode(float) at:&(currentElement->alpha)];
		[coder encodeValueOfObjCType:@encode(float) at:&(currentElement->position)];
		
		count++;
		currentElement = currentElement->nextElement;
		}
	[coder encodeInt:count forKey:@"CTGradientElementCount"];
	}
  else
	[NSException raise:NSInvalidArchiveOperationException format:@"Only supports NSKeyedArchiver coders"];
  }

- (id)initWithCoder:(NSCoder *)coder
  {
  [self _commonInit];
  
  unsigned count = [coder decodeIntForKey:@"CTGradientElementCount"];
  
  while(count != 0)
	{
    CTGradientElement newElement;
	
	[coder decodeValueOfObjCType:@encode(float) at:&(newElement.red)];
	[coder decodeValueOfObjCType:@encode(float) at:&(newElement.green)];
	[coder decodeValueOfObjCType:@encode(float) at:&(newElement.blue)];
	[coder decodeValueOfObjCType:@encode(float) at:&(newElement.alpha)];
	[coder decodeValueOfObjCType:@encode(float) at:&(newElement.position)];
	
	count--;
	[self addElement:&newElement];
	}
  return self;
  }


#pragma mark -



#pragma mark Creation
+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  CTGradientElement color2;
  
  [[begin colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"] getRed:&color1.red
																  green:&color1.green
           														   blue:&color1.blue
		  														  alpha:&color1.alpha];
  
  [[end   colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"] getRed:&color2.red
																  green:&color2.green
           														   blue:&color2.blue
		  														  alpha:&color2.alpha];
  color1.position = 0;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)aquaSelectedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red   = 0.58;
  color1.green = 0.86;
  color1.blue  = 0.98;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red   = 0.42;
  color2.green = 0.68;
  color2.blue  = 0.90;
  color2.alpha = 1.00;
  color2.position = 11.5/23;
  
  CTGradientElement color3;
  color3.red   = 0.64;
  color3.green = 0.80;
  color3.blue  = 0.94;
  color3.alpha = 1.00;
  color3.position = 11.5/23;
  
  CTGradientElement color4;
  color4.red   = 0.56;
  color4.green = 0.70;
  color4.blue  = 0.90;
  color4.alpha = 1.00;
  color4.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  [newInstance addElement:&color3];
  [newInstance addElement:&color4];
  
  return [newInstance autorelease];
  }

+ (id)aquaNormalGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.95;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.83;
  color2.alpha = 1.00;
  color2.position = 11.5/23;
  
  CTGradientElement color3;
  color3.red = color3.green = color3.blue  = 0.95;
  color3.alpha = 1.00;
  color3.position = 11.5/23;
  
  CTGradientElement color4;
  color4.red = color4.green = color4.blue  = 0.92;
  color4.alpha = 1.00;
  color4.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  [newInstance addElement:&color3];
  [newInstance addElement:&color4];
  
  return [newInstance autorelease];
  }

+ (id)aquaPressedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.80;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.64;
  color2.alpha = 1.00;
  color2.position = 11.5/23;
  
  CTGradientElement color3;
  color3.red = color3.green = color3.blue  = 0.80;
  color3.alpha = 1.00;
  color3.position = 11.5/23;
  
  CTGradientElement color4;
  color4.red = color4.green = color4.blue  = 0.77;
  color4.alpha = 1.00;
  color4.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  [newInstance addElement:&color3];
  [newInstance addElement:&color4];
  
  return [newInstance autorelease];
  }

+ (id)unifiedSelectedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.85;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.95;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)unifiedNormalGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.75;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.90;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)unifiedPressedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.60;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.75;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)unifiedDarkGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.68;
  color1.alpha = 1.00;
  color1.position = 0;
  
  CTGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.83;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }
#pragma mark -



#pragma mark Modification
- (CTGradient *)gradientWithAlphaComponent:(float)alpha
  {
  id newInstance = [[[self class] alloc] init];
  
  CTGradientElement *curElement = elementList;
  CTGradientElement tempElement;

  while(curElement != nil)
	{
	tempElement = *curElement;
	tempElement.alpha = alpha;
	[newInstance addElement:&tempElement];
	
	curElement = curElement->nextElement;
	}
  
  return [newInstance autorelease];
}

#pragma mark Information
//Returns color at <position> in gradient
- (NSColor *)colorStopAtIndex:(unsigned)index
  {
  CTGradientElement *element = [self elementAtIndex:index];
  
  if(element != nil)
	return [NSColor colorWithCalibratedRed:element->red 
									 green:element->green
									  blue:element->blue
									 alpha:element->alpha];
  
  [NSException raise:NSRangeException format:@"-[%@ removeColorStopAtIndex:]: index (%i) beyond bounds", [self class], index];
  
  return nil;
  }

- (NSColor *)colorAtPosition:(float)position
  {
  float components[4];
  
  linearEvaluation(&elementList, &position, components);
  
  return [NSColor colorWithCalibratedRed:components[0]
								   green:components[1]
								    blue:components[2]
								   alpha:components[3]];
  }
#pragma mark -



#pragma mark Drawing
- (void)drawSwatchInRect:(NSRect)rect
  {
  [self fillRect:rect angle:45];
  }

- (void)fillRect:(NSRect)rect angle:(float)angle
  {
  //First Calculate where the beginning and ending points should be
  CGPoint startPoint;
  CGPoint endPoint;
  
  if(angle == 0 && NO)		//screw the calculations - we know the answer
  	{
  	startPoint = CGPointMake(NSMinX(rect), NSMinY(rect));	//right of rect
  	endPoint   = CGPointMake(NSMaxX(rect), NSMinY(rect));	//left  of rect
  	}
  else if(angle == 90 && NO)	//same as above
  	{
  	startPoint = CGPointMake(NSMinX(rect), NSMinY(rect));	//bottom of rect
  	endPoint   = CGPointMake(NSMinX(rect), NSMaxY(rect));	//top    of rect
  	}
  else						//ok, we'll do the calculations now 
  	{
  	float x,y;
  	float sina, cosa, tana;
  	
  	float length;
  	float deltax,
  		  deltay;
	
  	float rangle = angle * pi/180;	//convert the angle to radians
	
  	if(fabsf(tan(rangle))<=1)	//for range [-45,45], [135,225]
		{
		x = NSWidth(rect);
		y = NSHeight(rect);
		
		sina = sin(rangle);
		cosa = cos(rangle);
		tana = tan(rangle);
		
		length = x/fabsf(cosa)+(y-x*fabsf(tana))*fabsf(sina);
		
		deltax = length*cosa/2;
		deltay = length*sina/2;
		}
	else						//for range [45,135], [225,315]
		{
		x = NSHeight(rect);
		y = NSWidth(rect);
		
		sina = sin(rangle - 90*pi/180);
		cosa = cos(rangle - 90*pi/180);
		tana = tan(rangle - 90*pi/180);
		
		length = x/fabsf(cosa)+(y-x*fabsf(tana))*fabsf(sina);
		
		deltax =-length*sina/2;
		deltay = length*cosa/2;
		}
  
	startPoint = CGPointMake(NSMidX(rect)-deltax, NSMidY(rect)-deltay);
	endPoint   = CGPointMake(NSMidX(rect)+deltax, NSMidY(rect)+deltay);
	}
  
  //Calls to CoreGraphics
  CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(currentContext);
	  //CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	  CGColorSpaceRef colorspace  = CGColorSpaceCreateWithName(CFSTR("kCGColorSpaceUserRGB"));
	  CGShadingRef    myCGShading = CGShadingCreateAxial(colorspace, startPoint, endPoint, gradientFunction, false, false);
	  
	  CGContextClipToRect(currentContext , *(CGRect *)&rect);	//This is where the action happens
	  CGContextDrawShading(currentContext, myCGShading);
	  
	  CGShadingRelease   (myCGShading);
	  CGColorSpaceRelease(colorspace );
  CGContextRestoreGState(currentContext);
  }

- (void)radialFillRect:(NSRect)rect
  {
  CGPoint startPoint , endPoint;
  float startRadius, endRadius;
  
  startPoint = endPoint = CGPointMake(NSMidX(rect), NSMidY(rect));
  
  startRadius = 0;
  
  if(NSHeight(rect)>NSWidth(rect))
	endRadius = NSHeight(rect)/2;
  else
	endRadius = NSWidth(rect)/2;

  //Calls to CoreGraphics
  CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(currentContext);
	  CGColorSpaceRef colorspace  = CGColorSpaceCreateWithName(CFSTR("kCGColorSpaceUserRGB"));
	  CGShadingRef    myCGShading = CGShadingCreateRadial(colorspace, startPoint, startRadius, endPoint, endRadius, gradientFunction, true, true);
	  
	  CGContextClipToRect (currentContext , *(CGRect *)&rect);
	  CGContextDrawShading(currentContext , myCGShading);		//This is where the action happens
	  
	  CGShadingRelease    (myCGShading);
	  CGColorSpaceRelease (colorspace);
  CGContextRestoreGState(currentContext);
  }

#pragma mark -



#pragma mark Element List
- (void)addElement:(CTGradientElement *)newElement
  {
  if(elementList == nil)
	{
	elementList = malloc(sizeof(CTGradientElement));
	*elementList = *newElement;
	
	elementList->nextElement = nil;
	}
  else
	{
	CTGradientElement *curElement = elementList;
	while(curElement->nextElement != nil && !((curElement->position <= newElement->position) && (newElement->position < curElement->nextElement->position)))
		{
		curElement = curElement->nextElement;
		}
	
	CTGradientElement *tmpNext = curElement->nextElement;
	curElement->nextElement = malloc(sizeof(CTGradientElement));
	*(curElement->nextElement) = *newElement;
	curElement->nextElement->nextElement = tmpNext;
	}
  }


#pragma mark Core Graphics
- (CGFunctionRef)buildCGFunction
  {
  static const float input_value_range   [2] = { 0, 1 };						//range  for the evaluator input
  static const float output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };		//ranges for the evaluator output (4 returned values)
  
  return CGFunctionCreate(&elementList,					//the two transition colors
						  1, input_value_range  ,		//number of inputs (just fraction of progression)
						  4, output_value_ranges,		//number of outputs RGBa
						  &_CTLinearGradientFunction);	//info for using the evaluator funtion
  }
  
  
  



//////////////////////////////////////LinearEvaluation Function/////////////////////////////////////

void linearEvaluation (void *info, const float *in, float *out)
  {
  float position = *in;
  
  if(*(CTGradientElement **)info == nil)	//if elementList is empty return clear color
	{
	out[0] = out[1] = out[2] = out[3] = 0;
	return;
	}
  
  //This grabs the first two colors in the sequence
  CTGradientElement *color1 = *(CTGradientElement **)info;
  CTGradientElement *color2 = color1->nextElement;
  
  //make sure first color and second color are on other sides of position
  while(color2 != nil && color2->position < position)
  	{
  	color1 = color2;
  	color2 = color1->nextElement;
  	}
  //if we don't have another color then make next color the same color
  if(color2 == nil)
    {
	color2 = color1;
    }
  
  //----------FailSafe settings----------
  //color1->red   = 1; color2->red   = 0;
  //color1->green = 1; color2->green = 0;
  //color1->blue  = 1; color2->blue  = 0;
  //color1->alpha = 1; color2->alpha = 1;
  //color1->position = .5;
  //color2->position = .5;
  //-------------------------------------
  
  if(position <= color1->position)			//Make all below color color1's position equal to color1
  	{
  	out[0] = color1->red; 
  	out[1] = color1->green;
  	out[2] = color1->blue;
  	out[3] = color1->alpha;
  	}
  else if (position >= color2->position)	//Make all above color color2's position equal to color2
  	{
  	out[0] = color2->red; 
  	out[1] = color2->green;
  	out[2] = color2->blue;
  	out[3] = color2->alpha;
  	}
  else										//Interpolate color at postions between color1 and color1
  	{
  	//adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
  	position = (position-color1->position)/(color2->position - color1->position);
  	
  	out[0] = (color2->red   - color1->red  )*position + color1->red; 
  	out[1] = (color2->green - color1->green)*position + color1->green;
  	out[2] = (color2->blue  - color1->blue )*position + color1->blue;
  	out[3] = (color2->alpha - color1->alpha)*position + color1->alpha;
  	}
  }

@end
