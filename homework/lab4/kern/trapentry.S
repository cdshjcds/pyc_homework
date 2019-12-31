/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */

#define TRAPHANDLER(name,num,erro,priority)\
.text;\
        .global name;\
        .type name, @function;\
        .align 2;\
        name:\
        .if erro==0 ;\
                pushl $0 ;\
        .endif ;\
        pushl $(num);\
        jmp _alltraps;\
.data;\
        .long name,num,priority
.data
        .global m_entry
        m_entry:
.text
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
	TRAPHANDLER(t_divide,0 ,0 ,0 );
        TRAPHANDLER(t_debug,1,0 ,3 );
       	//TRAPHANDLER(t_nmi,2,0 ,0 );
        TRAPHANDLER(t_brkpt,3,0 ,0 );
        TRAPHANDLER(t_oflow,4,0 ,0 );
        TRAPHANDLER(t_bound,5,0 ,0 );
        TRAPHANDLER(t_illop,6,0 ,0 );
        TRAPHANDLER(t_device,7,0 ,0 );
        TRAPHANDLER(t_dblflt,8,1,0 );
	TRAPHANDLER(temp,9,0,0 );
        TRAPHANDLER(t_tss,10,1,0 );
        TRAPHANDLER(t_segnp,11,1,0 );
        TRAPHANDLER(t_stack,12,1,0 );
        TRAPHANDLER(t_gpflt,13,1,0 );
        TRAPHANDLER(t_pgflt,14,1,0 );
        TRAPHANDLER(t_fperr,16,0,0 );
	TRAPHANDLER(trap1,32,0,0 );
	TRAPHANDLER(trap2,33,0,0 );
	TRAPHANDLER(trap3,34,0,0 );
	TRAPHANDLER(trap4,35,0,0 );
	TRAPHANDLER(trap5,36,0,0 );
        TRAPHANDLER(trap6,37,0,0 );
	TRAPHANDLER(trap7,38,0,0 );
	TRAPHANDLER(trap8,39,0,0 );
	TRAPHANDLER(trap9,40,0,0 );
	TRAPHANDLER(trap10,41,0,0 );
	TRAPHANDLER(trap11,42,0,0 );
	TRAPHANDLER(trap12,43,0,0 );
	TRAPHANDLER(trap13,44,0,0 );
	TRAPHANDLER(trap14,45,0,0 );
	TRAPHANDLER(trap15,46,0,0 );
        TRAPHANDLER(trap16,47,0,0 );
        TRAPHANDLER(t_syscall,48,0,3);
.data
        .long 0,0,0
/*
 * Lab 3: Your code here for _alltraps
 */
.text
_alltraps:
        pushl %ds
        pushl %es
        pushal

        pushl $GD_KD
        popl %ds
        pushl $GD_KD
        popl %es

        pushl %esp
        call trap
