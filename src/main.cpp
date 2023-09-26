/* FILE NAME  : win.cpp
 * PROGRAMMER : ND4
 * LAST UPDATE: 17.07.2022
 * PURPOSE    : Main program file.
 *              WinAPI routine.
 */

//#include "anim/anim.h"

#include "units/units.h"

#pragma warning(disable : 28251) // WinMain warning

/* The main program function.
 * ARGUMENTS:
 *   - handle of application instance:
 *       HINSTANCE hInstance;
 *   - dummy handle of previous application instance (not used):
 *       HINSTANCE hPrevInstance;
 *   - command line string:
 *       CHAR *CmdLine;
 *   - show window command parameter (see SW_***):
 *       int CmdShow;
 * RETURNS:
 *   (int) Error level for operation system (0 for success).
 */
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, CHAR* CmdLine, int CmdShow)
{
  nirt::anim *myW = nirt::anim::GetPtr();

  *myW << new nirt::units::fr;
  *myW << new nirt::units::ctrl;

  myW->Run();
  return 30;
} /* End of 'WinMain' function */

 /* END OF 'win.cpp' FILE */