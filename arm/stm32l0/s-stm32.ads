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

--  This file provides register definitions for the STM32L0x (ARM Cortex M0+)
--  microcontrollers from ST Microelectronics.

with Interfaces.STM32;

package System.STM32 is
   pragma No_Elaboration_Code_All;
   pragma Preelaborate (System.STM32);

   subtype Frequency is Interfaces.STM32.UInt32;

   type RCC_System_Clocks is record
      SYSCLK  : Frequency;
      HCLK    : Frequency;
      PCLK1   : Frequency;
      PCLK2   : Frequency;
   end record;

   function System_Clocks return RCC_System_Clocks;

   --  MODER constants
   subtype GPIO_MODER_Values is Interfaces.STM32.UInt2;
   Mode_IN  : constant GPIO_MODER_Values := 0;
   Mode_OUT : constant GPIO_MODER_Values := 1;
   Mode_AF  : constant GPIO_MODER_Values := 2;
   Mode_AN  : constant GPIO_MODER_Values := 3;

   --  OTYPER constants
   subtype GPIO_OTYPER_Values is Interfaces.STM32.Bit;
   Push_Pull  : constant GPIO_OTYPER_Values := 0;
   Open_Drain : constant GPIO_OTYPER_Values := 1;

   --  OSPEEDR constants
   subtype GPIO_OSPEEDR_Values is Interfaces.STM32.UInt2;
   Speed_2MHz   : constant GPIO_OSPEEDR_Values := 0; -- Low speed
   Speed_25MHz  : constant GPIO_OSPEEDR_Values := 1; -- Medium speed
   Speed_50MHz  : constant GPIO_OSPEEDR_Values := 2; -- Fast speed
   Speed_100MHz : constant GPIO_OSPEEDR_Values := 3; -- High speed

   --  PUPDR constants
   subtype GPIO_PUPDR_Values is Interfaces.STM32.UInt2;
   No_Pull   : constant GPIO_PUPDR_Values := 0;
   Pull_Up   : constant GPIO_PUPDR_Values := 1;
   Pull_Down : constant GPIO_PUPDR_Values := 2;

   --  FIXME: AFL constants
   --  AF_USART1  : constant Interfaces.STM32.UInt4 := 7;
   --  AF_USART6  : constant Interfaces.STM32.UInt4 := 8;

   type MCU_ID_Register is record
      DEV_ID   : Interfaces.STM32.UInt12;
      Reserved : Interfaces.STM32.UInt4;
      REV_ID   : Interfaces.STM32.UInt16;
   end record with Pack, Size => 32;

   --  RCC constants

   type PLL_Source is
     (PLL_SRC_HSI16,
      PLL_SRC_HSE)
     with Size => 1;

   type SYSCLK_Source is
     (SYSCLK_SRC_MSI,
      SYSCLK_SRC_HSI16,
      SYSCLK_SRC_HSE,
      SYSCLK_SRC_PLL)
     with Size => 2;

   type AHB_Prescaler_Enum is
     (DIV2,  DIV4,   DIV8,   DIV16,
      DIV64, DIV128, DIV256, DIV512)
     with Size => 3;

   type AHB_Prescaler is record
      Enabled : Boolean := False;
      Value   : AHB_Prescaler_Enum := AHB_Prescaler_Enum'First;
   end record with Size => 4;

   for AHB_Prescaler use record
      Enabled at 0 range 3 .. 3;
      Value   at 0 range 0 .. 2;
   end record;

   AHBPRE_DIV1 : constant AHB_Prescaler := (Enabled => False, Value => DIV2);

   type APB_Prescaler_Enum is
     (DIV2,  DIV4,  DIV8,  DIV16)
     with Size => 2;

   type APB_Prescaler is record
      Enabled : Boolean;
      Value   : APB_Prescaler_Enum;
   end record with Size => 3;

   for APB_Prescaler use record
      Enabled at 0 range 2 .. 2;
      Value   at 0 range 0 .. 1;
   end record;

   type MCO_Clock_Selection is
     (MCOSEL_NONE,
      MCOSEL_SYSCLK,
      MCOSEL_HSI16,
      MCOSEL_MSI,
      MCOSEL_HSE,
      MCOSEL_PLL,
      MCOSEL_LSI,
      MCOSEL_LSE,
      MCOSEL_HSI48)
     with Size => 4;

   type MCO_Prescaler is
     (MCOPRE_DIV1,
      MCOPRE_DIV2,
      MCOPRE_DIV4,
      MCOPRE_DIV8,
      MCOPRE_DIV16)
     with Size => 3;

   type PLL_Mul is record
      Main_Value : Interfaces.STM32.UInt3;
      Mul4_Flag  : Boolean;
   end record with Size => 4;

   for PLL_Mul use record
      Main_Value at 0 range 1 .. 3;
      Mul4_Flag  at 0 range 0 .. 0;
   end record;

   subtype PLL_Mul_Range is Integer range 3 .. 48
     with Static_Predicate => (case PLL_Mul_Range is
             when 3 | 4 | 6 | 8 | 12 | 16 | 24 | 32 | 48 => True,
             when others => False);
   subtype PLL_Div_Range is Integer range 2 .. 4;

   type MSI_Range_Enum is
     (MSI_RANGE_0,
      MSI_RANGE_1,
      MSI_RANGE_2,
      MSI_RANGE_3,
      MSI_RANGE_4,
      MSI_RANGE_5,
      MSI_RANGE_6)
     with Size => 3;

   --  Constants for RCC CR register

   subtype HSECLK_Range is Integer range 1_000_000 .. 32_000_000;
   subtype PLLIN_Range  is Integer range 2_000_000 .. 24_000_000;
   subtype PLLVCO_Range is Integer range 6_000_000 .. 96_000_000;
   subtype PLLOUT_Range is Integer range 2_000_000 .. 32_000_000;
   subtype SYSCLK_Range is Integer range         1 .. 32_000_000;
   subtype HCLK_Range   is Integer range         1 .. 32_000_000;
   subtype PCLK1_Range  is Integer range         1 .. 32_000_000;
   subtype PCLK2_Range  is Integer range         1 .. 32_000_000;

   --  These internal low and high speed clocks are fixed (do not modify)

   RC48CLK   : constant := 48_000_000;
   HSI16CLK  : constant := 16_000_000;
   LSICLK    : constant :=     37_000;

   MCU_ID : MCU_ID_Register with Volatile,
                                 Address => System'To_Address (16#E004_2000#);
   --  Only 32-bits access supported (read-only)

   --  DEV_ID_STM32F40xxx : constant := 16#413#; --  STM32F40xxx/41xxx
   --  DEV_ID_STM32F42xxx : constant := 16#419#; --  STM32F42xxx/43xxx
   --  DEV_ID_STM32F46xxx : constant := 16#434#; --  STM32F469xx/479xx
   --  DEV_ID_STM32F74xxx : constant := 16#449#; --  STM32F74xxx/75xxx

end System.STM32;
