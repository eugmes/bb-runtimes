------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--          Copyright (C) 2012-2017, Free Software Foundation, Inc.         --
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

pragma Ada_2012; -- To work around pre-commit check?
pragma Suppress (All_Checks);

--  This initialization procedure mainly initializes the PLLs and
--  all derived clocks.

with Ada.Unchecked_Conversion;

with Interfaces.STM32;           use Interfaces, Interfaces.STM32;
with Interfaces.STM32.Flash;     use Interfaces.STM32.Flash;
with Interfaces.STM32.RCC;       use Interfaces.STM32.RCC;

with System.BB.Parameters;       use System.BB.Parameters;
with System.BB.MCU_Parameters;
with System.BB.Board_Parameters; use System.BB.Board_Parameters;
with System.STM32;               use System.STM32;

procedure Setup_Pll is
   procedure Initialize_Clocks;
   procedure Reset_Clocks;

   procedure Initialize_Clocks
   is
      function To_AHB is new Ada.Unchecked_Conversion
        (AHB_Prescaler, UInt4);
      function To_APB is new Ada.Unchecked_Conversion
        (APB_Prescaler, UInt3);
      function To_PLLMUL is new Ada.Unchecked_Conversion
        (PLL_Mul, CFGR_PLLMUL_Field);

      Pllmul : constant PLL_Mul := (
        Main_Value => (if PLLMUL_Value mod 4 = 0
                       then PLLMUL_Value / 4 - 1
                       else PLLMUL_Value / 3 - 1),
        Mul4_Flag => PLLMUL_Value mod 4 = 0);
      CFGR : CFGR_Register;

   begin
      --  PWR clock enable

      RCC_Periph.APB1ENR.PWREN := 1;

      --  Reset the power interface
      RCC_Periph.APB1RSTR.PWRRST := 1;
      RCC_Periph.APB1RSTR.PWRRST := 0;

      --  PWR initialization
      --  Select higher supply power for stable operation at max. freq.
      --  See table "General operating conditions" of the STM32 datasheets
      --  to obtain the maximal operating frequency depending on the power
      --  scaling mode and the over-drive mode

      System.BB.MCU_Parameters.PWR_Initialize;

      --  Wait until voltage supply scaling has completed
      loop
         exit when System.BB.MCU_Parameters.Is_PWR_Stabilized;
      end loop;

      --  Setup internal clock and wait for HSI stabilisation.

      RCC_Periph.CR.HSI16ON := 1;

      loop
         exit when RCC_Periph.CR.HSI16RDYF = 1;
      end loop;

      --  Disable the main PLL before configuring it
      RCC_Periph.CR.PLLON := 0;

      --  Configure the PLL clock source, multiplication and division
      --  factors
      CFGR := RCC_Periph.CFGR;
      CFGR.PLLDIV := PLLDIV_Value - 1;
      CFGR.PLLMUL := To_PLLMUL (Pllmul);
      CFGR.PLLSRC := PLL_Source'Enum_Rep (PLL_SRC_HSI16);
      RCC_Periph.CFGR := CFGR;

      RCC_Periph.CR.PLLON := 1;
      loop
         exit when RCC_Periph.CR.PLLRDY = 1;
      end loop;

      --  Configure flash
      --  Must be done before increasing the frequency, otherwise the CPU
      --  won't be able to fetch new instructions.

      Flash_Periph.ACR :=
        (LATENCY   => Flash_Latency,
         PRE_READ  => 1,
         DISAB_BUF => 0,
         PRFTEN    => 1,
         others    => <>);

      --  Configure derived clocks

      RCC_Periph.CFGR :=
        (SW      => SYSCLK_Source'Enum_Rep (SYSCLK_SRC_PLL),
         HPRE    => To_AHB (AHB_PRE),
         PPRE    => (As_Array => True,
                     Arr      => (1 => To_APB (APB1_PRE),
                                  2 => To_APB (APB2_PRE))),
         others  => <>);

      loop
         exit when RCC_Periph.CFGR.SWS =
            SYSCLK_Source'Enum_Rep (SYSCLK_SRC_PLL);
      end loop;

   end Initialize_Clocks;

   ------------------
   -- Reset_Clocks --
   ------------------

   procedure Reset_Clocks is
   begin
      --  Switch on high speed internal clock
      RCC_Periph.CR.HSI16ON := 1;

      --  Reset CFGR regiser
      RCC_Periph.CFGR := (others => <>);

      --  Reset HSEON and PLLON bits
      RCC_Periph.CR.HSEON := 0;
      RCC_Periph.CR.PLLON := 0;

      --  Reset PLL configuration register
      RCC_Periph.CFGR := (others => <>);

      --  Reset HSE bypass bit
      RCC_Periph.CR.HSEBYP := 0;

      --  TODO Disable all interrupts
      --  RCC_Periph.CIER := (others => 0);
   end Reset_Clocks;

begin
   Reset_Clocks;
   Initialize_Clocks;
end Setup_Pll;
