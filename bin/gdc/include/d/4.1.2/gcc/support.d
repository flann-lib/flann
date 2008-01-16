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

module gcc.support;

/* Binary compatibility for an earlier bug.  This will be removed
   in a later version. */
extern (C) {
    void _D9invariant12_d_invariantFC6ObjectZv(Object o);
    void _d_invariant(Object o) {
	_D9invariant12_d_invariantFC6ObjectZv(o);
    }
}

extern(C) double strtod(char *,char **);

real strtold(char* a, char** b) { return strtod(a, b); }
