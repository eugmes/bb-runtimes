------------------------------------------------------------------------------
--                                                                          --
--                               GNAT EXAMPLE                               --
--                                                                          --
--                        Copyright (C) 2017, AdaCore                       --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the  Free Software Foundation,  51  Franklin  Street,  Fifth  Floor, --
-- Boston, MA 02110-1301, USA.                                              --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with IOEmu; use IOEmu;
with Interfaces; use Interfaces;
with Uart; use Uart;

package Emu_PL011 is
   type PL011_Uart_Dev is new IOEmu_Dev32 with private;

   function Read32 (Dev : in out PL011_Uart_Dev; Off : Off_T)
                   return Unsigned_32;
   procedure Write32_Mask
     (Dev : in out PL011_Uart_Dev;
      Off : Off_T;
      Val : Unsigned_32;
      Mask : Unsigned_32);

   procedure Init (Dev : access PL011_Uart_Dev);
private
   type PL011_Uart_Dev_Acc is access all PL011_Uart_Dev;

   type PL011_Uart_Emu is new Char_Emu_Type with record
      Parent : PL011_Uart_Dev_Acc;
   end record;

   procedure Put (Dev : in out PL011_Uart_Emu; C : Character);
   --  Called by emu when a character is received

   type PL011_Uart_Dev is new IOEmu_Dev32 with record
      Emu : aliased PL011_Uart_Emu;

      RIS : Unsigned_32;

      DR_Rx : Unsigned_32;
      FR : Unsigned_32;
      CR : Unsigned_32;
      LCR : Unsigned_32;
      IFLS : Unsigned_32;
      IMSC : Unsigned_32;
      IBRD : Unsigned_32;
      FBRD : Unsigned_32;
   end record;
end Emu_PL011;
