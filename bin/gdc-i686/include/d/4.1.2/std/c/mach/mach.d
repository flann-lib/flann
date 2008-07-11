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

module std.c.mach.mach;

private import gcc.builtins;

private alias uint natural_t; // uint on both 32- and 64-bit

private import std.c.mach.mach_extern;

extern(C):

enum {
    SYNC_POLICY_FIFO =		0x0,
    SYNC_POLICY_FIXED_PRIORITY =	0x1,
    SYNC_POLICY_REVERSED =		0x2,
    SYNC_POLICY_ORDER_MASK =		0x3,
    SYNC_POLICY_LIFO =		(SYNC_POLICY_FIFO|SYNC_POLICY_REVERSED)
}

enum {
    KERN_SUCCESS =			0
}

alias natural_t semaphore_t; // TODO: natural_t
alias natural_t task_t; // TODO: natural_t
alias natural_t mach_port_t; // TODO: natural_t
alias int kern_return_t;
kern_return_t semaphore_create
(
	task_t task,
	semaphore_t *semaphore,
	int policy,
	int value
);
kern_return_t semaphore_destroy
(
	task_t task,
	semaphore_t semaphore
);
kern_return_t	semaphore_signal     	(semaphore_t semaphore);
kern_return_t	semaphore_wait       	(semaphore_t semaphore);

// just in case this actually gets defined..
extern(D) mach_port_t current_task() { return mach_task_self_; }
