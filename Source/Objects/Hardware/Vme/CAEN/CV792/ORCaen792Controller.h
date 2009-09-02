//--------------------------------------------------------------------------------
/*!\class	ORCaen792Controller
 * \brief	Handles high level commands to CAEN 792.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Mark A. Howe
 * \history	2004-04-21 (mah) - Original
 */
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
#pragma mark ���Imported Files

#import "ORCaenCardController.h"

// Definition of class.
@interface ORCaen792Controller : ORCaenCardController {
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark ���Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void) updateWindow;


// The outlets
	

@end
