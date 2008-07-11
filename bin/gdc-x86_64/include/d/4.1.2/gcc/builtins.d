/* GDC -- D front-end for GCC
   Copyright (C) 2004 David Friedman
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


/**
  Declarations are automatically created by the compiler.  All
  declarations start with "__builtin_". Refer to _builtins.def in the
  GCC source for a list of functions.  Not all of the functions are
  supported.
 
  In addition to built-in functions, the following types are defined.
 
  $(TABLE 
  $(TR $(TD ___builtin_va_list)      $(TD The target's va_list type ))
  $(TR $(TD ___builtin_Clong  )      $(TD The D equivalent of the target's
                                           C "long" type ))
  $(TR $(TD ___builtin_Culong )      $(TD The D equivalent of the target's
                                           C "unsigned long" type ))
  $(TR $(TD ___builtin_machine_int ) $(TD Signed word-sized integer ))
  $(TR $(TD ___builtin_machine_uint) $(TD Unsigned word-sized integer ))
  $(TR $(TD ___builtin_pointer_int ) $(TD Signed pointer-sized integer ))
  $(TR $(TD ___builtin_pointer_uint) $(TD Unsigned pointer-sized integer ))
  )
 */

module gcc.builtins;
