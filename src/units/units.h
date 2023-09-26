/* FILE NAME  : units.h
 * PROGRAMMER : ND4
 * LAST UPDATE: 18.07.2022
 * PURPOSE    : WinAPI preferences
 */

#ifndef __units_h_
#define __units_h_

#include "../anim/anim.h"

#pragma warning(disable: 26451)

namespace nirt
{
  /* Unit namespace */
  namespace units
  {
    class fr : public unit
    {
    private:
      primitive *frame;
    public:
      fr( VOID );

      ~fr( VOID ) override
      {
        delete frame;
      }

      VOID Response( anim *Ani ) override
      {
      }

      VOID Render( anim *Ani ) override;

    };

    class ctrl : public unit
    {
    private:
      vec3 Dir, Right, Up;
    public:
      ctrl(VOID)
      {
      }

      ~ctrl(VOID) override
      {
      }

      VOID Response(anim* Ani) override;

      VOID Render(anim* Ani) override
      {
      }

    };

  } /* End of 'units' namespace */
} /* End of 'nirt' namespace */

#endif /* __units_h_ */

/* END OF 'units.h' FILE */