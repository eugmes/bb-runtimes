------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--          Copyright (C) 2012-2016, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;

with Interfaces;            use Interfaces;
with Interfaces.STM32;      use Interfaces.STM32;
with Interfaces.STM32.RCC;  use Interfaces.STM32.RCC;

package body System.STM32 is

   MSI_Table : constant array (MSI_Range_Enum) of UInt32 :=
     (65_536_000,
      131_072_000,
      262_144_000,
      524_288_000,
      1_048_000_000,
      2_097_000_000,
      4_194_000_000);

   HPRE_Presc_Table : constant array (AHB_Prescaler_Enum) of UInt32 :=
     (2, 4, 8, 16, 64, 128, 256, 512);

   PPRE_Presc_Table : constant array (APB_Prescaler_Enum) of UInt32 :=
     (2, 4, 8, 16);

   -------------------
   -- System_Clocks --
   -------------------

   function System_Clocks return RCC_System_Clocks
   is
      Source       : constant SYSCLK_Source :=
                      SYSCLK_Source'Val (RCC_Periph.CFGR.SWS);
      Result       : RCC_System_Clocks;

   begin
      case Source is

         --  MSI as source

         when SYSCLK_SRC_MSI =>
            declare
               function To_MSI is new Ada.Unchecked_Conversion
                 (ICSCR_MSIRANGE_Field, MSI_Range_Enum);
            begin
               Result.SYSCLK := MSI_Table (To_MSI (RCC_Periph.ICSCR.MSIRANGE));
            end;

         --  HSI as source

         when SYSCLK_SRC_HSI16 =>
            Result.SYSCLK := HSI16CLK;

         --  HSE as source

         when SYSCLK_SRC_HSE =>
            Result.SYSCLK := 0; --  TODO: Support HSE

         --  PLL as source

         when SYSCLK_SRC_PLL =>
            declare
               function To_PLLMUL is new Ada.Unchecked_Conversion
                 (CFGR_PLLMUL_Field, PLL_Mul);

               Plldiv : constant UInt32 := UInt32 (RCC_Periph.CFGR.PLLDIV) + 1;
               Pllmul_Raw : constant PLL_Mul :=
                 To_PLLMUL (RCC_Periph.CFGR.PLLMUL);
               Pllmul : constant UInt32 :=
                 UInt32 (Pllmul_Raw.Main_Value) *
                 (if Pllmul_Raw.Mul4_Flag then 4 else 3);
               Pllvco : UInt32;

            begin
               case PLL_Source'Val (RCC_Periph.CFGR.PLLSRC) is
                  when PLL_SRC_HSE =>
                     Pllvco := 0; --  TODO: Support HSE
                  when PLL_SRC_HSI16 =>
                     Pllvco := HSI16CLK * Pllmul;
               end case;

               Result.SYSCLK := Pllvco / Plldiv;
            end;
      end case;

      declare
         function To_AHBP is new Ada.Unchecked_Conversion
           (CFGR_HPRE_Field, AHB_Prescaler);
         function To_APBP is new Ada.Unchecked_Conversion
           (CFGR_PPRE_Element, APB_Prescaler);

         HPRE      : constant AHB_Prescaler := To_AHBP (RCC_Periph.CFGR.HPRE);
         HPRE_Div  : constant UInt32 := (if HPRE.Enabled
                                         then HPRE_Presc_Table (HPRE.Value)
                                         else 1);
         PPRE1     : constant APB_Prescaler :=
                      To_APBP (RCC_Periph.CFGR.PPRE.Arr (1));
         PPRE1_Div : constant UInt32 := (if PPRE1.Enabled
                                         then PPRE_Presc_Table (PPRE1.Value)
                                         else 1);
         PPRE2     : constant APB_Prescaler :=
                      To_APBP (RCC_Periph.CFGR.PPRE.Arr (2));
         PPRE2_Div : constant UInt32 := (if PPRE2.Enabled
                                         then PPRE_Presc_Table (PPRE2.Value)
                                         else 1);

      begin
         Result.HCLK  := Result.SYSCLK / HPRE_Div;
         Result.PCLK1 := Result.HCLK / PPRE1_Div;
         Result.PCLK2 := Result.HCLK / PPRE2_Div;
      end;

      return Result;
   end System_Clocks;

end System.STM32;
