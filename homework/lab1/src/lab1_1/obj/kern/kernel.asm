
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 1a 10 f0 	movl   $0xf0101ac0,(%esp)
f0100055:	e8 8d 09 00 00       	call   f01009e7 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 1b 07 00 00       	call   f01007a2 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 1a 10 f0 	movl   $0xf0101adc,(%esp)
f0100092:	e8 50 09 00 00       	call   f01009e7 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 2a 15 00 00       	call   f01015ef <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 1a 10 f0 	movl   $0xf0101af7,(%esp)
f01000d9:	e8 09 09 00 00       	call   f01009e7 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 69 07 00 00       	call   f010085f <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 12 1b 10 f0 	movl   $0xf0101b12,(%esp)
f010012c:	e8 b6 08 00 00       	call   f01009e7 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 77 08 00 00       	call   f01009b4 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 4e 1b 10 f0 	movl   $0xf0101b4e,(%esp)
f0100144:	e8 9e 08 00 00       	call   f01009e7 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 0a 07 00 00       	call   f010085f <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 2a 1b 10 f0 	movl   $0xf0101b2a,(%esp)
f0100176:	e8 6c 08 00 00       	call   f01009e7 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 2a 08 00 00       	call   f01009b4 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 4e 1b 10 f0 	movl   $0xf0101b4e,(%esp)
f0100191:	e8 51 08 00 00       	call   f01009e7 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 a0 1c 10 f0 	movzbl -0xfefe360(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 a0 1c 10 f0 	movzbl -0xfefe360(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a a0 1b 10 f0 	movzbl -0xfefe460(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 80 1b 10 f0 	mov    -0xfefe480(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 44 1b 10 f0 	movl   $0xf0101b44,(%esp)
f01002e9:	e8 f9 06 00 00       	call   f01009e7 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 21                	jne    f010033f <cons_putc+0x36>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 f2                	mov    %esi,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	a8 20                	test   $0x20,%al
f0100338:	75 05                	jne    f010033f <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	83 eb 01             	sub    $0x1,%ebx
f010033d:	75 ee                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010033f:	89 f8                	mov    %edi,%eax
f0100341:	0f b6 c0             	movzbl %al,%eax
f0100344:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034d:	b2 79                	mov    $0x79,%dl
f010034f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100350:	84 c0                	test   %al,%al
f0100352:	78 21                	js     f0100375 <cons_putc+0x6c>
f0100354:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100359:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035e:	be 79 03 00 00       	mov    $0x379,%esi
f0100363:	89 ca                	mov    %ecx,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	89 f2                	mov    %esi,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	84 c0                	test   %al,%al
f010036e:	78 05                	js     f0100375 <cons_putc+0x6c>
f0100370:	83 eb 01             	sub    $0x1,%ebx
f0100373:	75 ee                	jne    f0100363 <cons_putc+0x5a>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100375:	ba 78 03 00 00       	mov    $0x378,%edx
f010037a:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037e:	ee                   	out    %al,(%dx)
f010037f:	b2 7a                	mov    $0x7a,%dl
f0100381:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 08 00 00 00       	mov    $0x8,%eax
f010038c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100395:	89 f8                	mov    %edi,%eax
f0100397:	80 cc 07             	or     $0x7,%ah
f010039a:	85 d2                	test   %edx,%edx
f010039c:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	0f b6 c0             	movzbl %al,%eax
f01003a4:	83 f8 09             	cmp    $0x9,%eax
f01003a7:	74 79                	je     f0100422 <cons_putc+0x119>
f01003a9:	83 f8 09             	cmp    $0x9,%eax
f01003ac:	7f 0a                	jg     f01003b8 <cons_putc+0xaf>
f01003ae:	83 f8 08             	cmp    $0x8,%eax
f01003b1:	74 19                	je     f01003cc <cons_putc+0xc3>
f01003b3:	e9 9e 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
f01003b8:	83 f8 0a             	cmp    $0xa,%eax
f01003bb:	90                   	nop
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xf3>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xfb>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1b8>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x16b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x16b>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 dd fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 d3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 c9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 bf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 b5 fe ff ff       	call   f0100309 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x16b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1b8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 9e 11 00 00       	call   f010163c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x1a0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010053a:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010054b:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	0f b6 c9             	movzbl %cl,%ecx
f0100640:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f0100646:	89 f2                	mov    %esi,%edx
f0100648:	ec                   	in     (%dx),%al
f0100649:	89 da                	mov    %ebx,%edx
f010064b:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010064c:	85 c9                	test   %ecx,%ecx
f010064e:	75 0c                	jne    f010065c <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100650:	c7 04 24 50 1b 10 f0 	movl   $0xf0101b50,(%esp)
f0100657:	e8 8b 03 00 00       	call   f01009e7 <cprintf>
}
f010065c:	83 c4 1c             	add    $0x1c,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5e                   	pop    %esi
f0100661:	5f                   	pop    %edi
f0100662:	5d                   	pop    %ebp
f0100663:	c3                   	ret    

f0100664 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100664:	55                   	push   %ebp
f0100665:	89 e5                	mov    %esp,%ebp
f0100667:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010066a:	8b 45 08             	mov    0x8(%ebp),%eax
f010066d:	e8 97 fc ff ff       	call   f0100309 <cons_putc>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <getchar>:

int
getchar(void)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010067a:	e8 a6 fe ff ff       	call   f0100525 <cons_getc>
f010067f:	85 c0                	test   %eax,%eax
f0100681:	74 f7                	je     f010067a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100683:	c9                   	leave  
f0100684:	c3                   	ret    

f0100685 <iscons>:

int
iscons(int fdnum)
{
f0100685:	55                   	push   %ebp
f0100686:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100688:	b8 01 00 00 00       	mov    $0x1,%eax
f010068d:	5d                   	pop    %ebp
f010068e:	c3                   	ret    
f010068f:	90                   	nop

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 a0 1d 10 	movl   $0xf0101da0,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 be 1d 10 	movl   $0xf0101dbe,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 c3 1d 10 f0 	movl   $0xf0101dc3,(%esp)
f01006ad:	e8 35 03 00 00       	call   f01009e7 <cprintf>
f01006b2:	c7 44 24 08 78 1e 10 	movl   $0xf0101e78,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 cc 1d 10 	movl   $0xf0101dcc,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 c3 1d 10 f0 	movl   $0xf0101dc3,(%esp)
f01006c9:	e8 19 03 00 00       	call   f01009e7 <cprintf>
f01006ce:	c7 44 24 08 a0 1e 10 	movl   $0xf0101ea0,0x8(%esp)
f01006d5:	f0 
f01006d6:	c7 44 24 04 d5 1d 10 	movl   $0xf0101dd5,0x4(%esp)
f01006dd:	f0 
f01006de:	c7 04 24 c3 1d 10 f0 	movl   $0xf0101dc3,(%esp)
f01006e5:	e8 fd 02 00 00       	call   f01009e7 <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	c7 04 24 df 1d 10 f0 	movl   $0xf0101ddf,(%esp)
f01006fe:	e8 e4 02 00 00       	call   f01009e7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100703:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070a:	00 
f010070b:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100712:	f0 
f0100713:	c7 04 24 cc 1e 10 f0 	movl   $0xf0101ecc,(%esp)
f010071a:	e8 c8 02 00 00       	call   f01009e7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010071f:	c7 44 24 08 b7 1a 10 	movl   $0x101ab7,0x8(%esp)
f0100726:	00 
f0100727:	c7 44 24 04 b7 1a 10 	movl   $0xf0101ab7,0x4(%esp)
f010072e:	f0 
f010072f:	c7 04 24 f0 1e 10 f0 	movl   $0xf0101ef0,(%esp)
f0100736:	e8 ac 02 00 00       	call   f01009e7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073b:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100742:	00 
f0100743:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074a:	f0 
f010074b:	c7 04 24 14 1f 10 f0 	movl   $0xf0101f14,(%esp)
f0100752:	e8 90 02 00 00       	call   f01009e7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100757:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010075e:	00 
f010075f:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100766:	f0 
f0100767:	c7 04 24 38 1f 10 f0 	movl   $0xf0101f38,(%esp)
f010076e:	e8 74 02 00 00       	call   f01009e7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100773:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100778:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010077d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100783:	85 c0                	test   %eax,%eax
f0100785:	0f 48 c2             	cmovs  %edx,%eax
f0100788:	c1 f8 0a             	sar    $0xa,%eax
f010078b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078f:	c7 04 24 5c 1f 10 f0 	movl   $0xf0101f5c,(%esp)
f0100796:	e8 4c 02 00 00       	call   f01009e7 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010079b:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a0:	c9                   	leave  
f01007a1:	c3                   	ret    

f01007a2 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	57                   	push   %edi
f01007a6:	56                   	push   %esi
f01007a7:	53                   	push   %ebx
f01007a8:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01007ab:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f01007b2:	e8 30 02 00 00       	call   f01009e7 <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007b7:	89 e8                	mov    %ebp,%eax
f01007b9:	89 c6                	mov    %eax,%esi
	uint32_t ebp=read_ebp();
	for(;ebp;ebp=*((uint32_t *)ebp))
f01007bb:	85 c0                	test   %eax,%eax
f01007bd:	0f 84 8f 00 00 00    	je     f0100852 <mon_backtrace+0xb0>
	{	
		uint32_t eip=*((uint32_t *)(ebp+4));
f01007c3:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  ebp %08x eip %08x args",ebp,eip);
f01007c6:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007ce:	c7 04 24 0a 1e 10 f0 	movl   $0xf0101e0a,(%esp)
f01007d5:	e8 0d 02 00 00       	call   f01009e7 <cprintf>
		int i=8;
f01007da:	bb 08 00 00 00       	mov    $0x8,%ebx
		for(;i<28;i+=4)
			cprintf(" %08x",*((uint32_t *)(ebp+i)));
f01007df:	8b 04 33             	mov    (%ebx,%esi,1),%eax
f01007e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e6:	c7 04 24 23 1e 10 f0 	movl   $0xf0101e23,(%esp)
f01007ed:	e8 f5 01 00 00       	call   f01009e7 <cprintf>
	for(;ebp;ebp=*((uint32_t *)ebp))
	{	
		uint32_t eip=*((uint32_t *)(ebp+4));
		cprintf("  ebp %08x eip %08x args",ebp,eip);
		int i=8;
		for(;i<28;i+=4)
f01007f2:	83 c3 04             	add    $0x4,%ebx
f01007f5:	83 fb 1c             	cmp    $0x1c,%ebx
f01007f8:	75 e5                	jne    f01007df <mon_backtrace+0x3d>
			cprintf(" %08x",*((uint32_t *)(ebp+i)));
		cprintf("\n");
f01007fa:	c7 04 24 4e 1b 10 f0 	movl   $0xf0101b4e,(%esp)
f0100801:	e8 e1 01 00 00       	call   f01009e7 <cprintf>
		if(!debuginfo_eip(eip,&info))
f0100806:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100809:	89 44 24 04          	mov    %eax,0x4(%esp)
f010080d:	89 3c 24             	mov    %edi,(%esp)
f0100810:	e8 d8 02 00 00       	call   f0100aed <debuginfo_eip>
f0100815:	85 c0                	test   %eax,%eax
f0100817:	75 2f                	jne    f0100848 <mon_backtrace+0xa6>
			cprintf("	  %s:%d:%.*s+%d\n",
f0100819:	2b 7d e0             	sub    -0x20(%ebp),%edi
f010081c:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0100820:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100823:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100827:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010082a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010082e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100831:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100835:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100838:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083c:	c7 04 24 29 1e 10 f0 	movl   $0xf0101e29,(%esp)
f0100843:	e8 9f 01 00 00       	call   f01009e7 <cprintf>
{
	// Your code here.
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	uint32_t ebp=read_ebp();
	for(;ebp;ebp=*((uint32_t *)ebp))
f0100848:	8b 36                	mov    (%esi),%esi
f010084a:	85 f6                	test   %esi,%esi
f010084c:	0f 85 71 ff ff ff    	jne    f01007c3 <mon_backtrace+0x21>
			info.eip_fn_namelen,
			info.eip_fn_name,
			eip-info.eip_fn_addr);
	}
	return 0;
}
f0100852:	b8 00 00 00 00       	mov    $0x0,%eax
f0100857:	83 c4 4c             	add    $0x4c,%esp
f010085a:	5b                   	pop    %ebx
f010085b:	5e                   	pop    %esi
f010085c:	5f                   	pop    %edi
f010085d:	5d                   	pop    %ebp
f010085e:	c3                   	ret    

f010085f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010085f:	55                   	push   %ebp
f0100860:	89 e5                	mov    %esp,%ebp
f0100862:	57                   	push   %edi
f0100863:	56                   	push   %esi
f0100864:	53                   	push   %ebx
f0100865:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100868:	c7 04 24 88 1f 10 f0 	movl   $0xf0101f88,(%esp)
f010086f:	e8 73 01 00 00       	call   f01009e7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100874:	c7 04 24 ac 1f 10 f0 	movl   $0xf0101fac,(%esp)
f010087b:	e8 67 01 00 00       	call   f01009e7 <cprintf>

	while (1) {
		buf = readline("K> ");
f0100880:	c7 04 24 3b 1e 10 f0 	movl   $0xf0101e3b,(%esp)
f0100887:	e8 b4 0a 00 00       	call   f0101340 <readline>
f010088c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010088e:	85 c0                	test   %eax,%eax
f0100890:	74 ee                	je     f0100880 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100892:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100899:	be 00 00 00 00       	mov    $0x0,%esi
f010089e:	eb 0a                	jmp    f01008aa <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008a0:	c6 03 00             	movb   $0x0,(%ebx)
f01008a3:	89 f7                	mov    %esi,%edi
f01008a5:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008a8:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008aa:	0f b6 03             	movzbl (%ebx),%eax
f01008ad:	84 c0                	test   %al,%al
f01008af:	74 6a                	je     f010091b <monitor+0xbc>
f01008b1:	0f be c0             	movsbl %al,%eax
f01008b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b8:	c7 04 24 3f 1e 10 f0 	movl   $0xf0101e3f,(%esp)
f01008bf:	e8 ca 0c 00 00       	call   f010158e <strchr>
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	75 d8                	jne    f01008a0 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008c8:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008cb:	74 4e                	je     f010091b <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008cd:	83 fe 0f             	cmp    $0xf,%esi
f01008d0:	75 16                	jne    f01008e8 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008d2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008d9:	00 
f01008da:	c7 04 24 44 1e 10 f0 	movl   $0xf0101e44,(%esp)
f01008e1:	e8 01 01 00 00       	call   f01009e7 <cprintf>
f01008e6:	eb 98                	jmp    f0100880 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008e8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008eb:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ef:	0f b6 03             	movzbl (%ebx),%eax
f01008f2:	84 c0                	test   %al,%al
f01008f4:	75 0c                	jne    f0100902 <monitor+0xa3>
f01008f6:	eb b0                	jmp    f01008a8 <monitor+0x49>
			buf++;
f01008f8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008fb:	0f b6 03             	movzbl (%ebx),%eax
f01008fe:	84 c0                	test   %al,%al
f0100900:	74 a6                	je     f01008a8 <monitor+0x49>
f0100902:	0f be c0             	movsbl %al,%eax
f0100905:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100909:	c7 04 24 3f 1e 10 f0 	movl   $0xf0101e3f,(%esp)
f0100910:	e8 79 0c 00 00       	call   f010158e <strchr>
f0100915:	85 c0                	test   %eax,%eax
f0100917:	74 df                	je     f01008f8 <monitor+0x99>
f0100919:	eb 8d                	jmp    f01008a8 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010091b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100922:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100923:	85 f6                	test   %esi,%esi
f0100925:	0f 84 55 ff ff ff    	je     f0100880 <monitor+0x21>
f010092b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100930:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100933:	8b 04 85 e0 1f 10 f0 	mov    -0xfefe020(,%eax,4),%eax
f010093a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 c1 0b 00 00       	call   f010150a <strcmp>
f0100949:	85 c0                	test   %eax,%eax
f010094b:	75 24                	jne    f0100971 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f010094d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100950:	8b 55 08             	mov    0x8(%ebp),%edx
f0100953:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100957:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010095a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010095e:	89 34 24             	mov    %esi,(%esp)
f0100961:	ff 14 85 e8 1f 10 f0 	call   *-0xfefe018(,%eax,4)
	cprintf("Type 'help' for a list of commands.\n");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100968:	85 c0                	test   %eax,%eax
f010096a:	78 25                	js     f0100991 <monitor+0x132>
f010096c:	e9 0f ff ff ff       	jmp    f0100880 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100971:	83 c3 01             	add    $0x1,%ebx
f0100974:	83 fb 03             	cmp    $0x3,%ebx
f0100977:	75 b7                	jne    f0100930 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100979:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100980:	c7 04 24 61 1e 10 f0 	movl   $0xf0101e61,(%esp)
f0100987:	e8 5b 00 00 00       	call   f01009e7 <cprintf>
f010098c:	e9 ef fe ff ff       	jmp    f0100880 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100991:	83 c4 5c             	add    $0x5c,%esp
f0100994:	5b                   	pop    %ebx
f0100995:	5e                   	pop    %esi
f0100996:	5f                   	pop    %edi
f0100997:	5d                   	pop    %ebp
f0100998:	c3                   	ret    

f0100999 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100999:	55                   	push   %ebp
f010099a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010099c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010099f:	5d                   	pop    %ebp
f01009a0:	c3                   	ret    

f01009a1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009a1:	55                   	push   %ebp
f01009a2:	89 e5                	mov    %esp,%ebp
f01009a4:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01009aa:	89 04 24             	mov    %eax,(%esp)
f01009ad:	e8 b2 fc ff ff       	call   f0100664 <cputchar>
	*cnt++;
}
f01009b2:	c9                   	leave  
f01009b3:	c3                   	ret    

f01009b4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009b4:	55                   	push   %ebp
f01009b5:	89 e5                	mov    %esp,%ebp
f01009b7:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01009cb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009cf:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d6:	c7 04 24 a1 09 10 f0 	movl   $0xf01009a1,(%esp)
f01009dd:	e8 f2 04 00 00       	call   f0100ed4 <vprintfmt>
	return cnt;
}
f01009e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009e5:	c9                   	leave  
f01009e6:	c3                   	ret    

f01009e7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009e7:	55                   	push   %ebp
f01009e8:	89 e5                	mov    %esp,%ebp
f01009ea:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009ed:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01009f7:	89 04 24             	mov    %eax,(%esp)
f01009fa:	e8 b5 ff ff ff       	call   f01009b4 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009ff:	c9                   	leave  
f0100a00:	c3                   	ret    
f0100a01:	66 90                	xchg   %ax,%ax
f0100a03:	66 90                	xchg   %ax,%ax
f0100a05:	66 90                	xchg   %ax,%ax
f0100a07:	66 90                	xchg   %ax,%ax
f0100a09:	66 90                	xchg   %ax,%ax
f0100a0b:	66 90                	xchg   %ax,%ax
f0100a0d:	66 90                	xchg   %ax,%ax
f0100a0f:	90                   	nop

f0100a10 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	57                   	push   %edi
f0100a14:	56                   	push   %esi
f0100a15:	53                   	push   %ebx
f0100a16:	83 ec 10             	sub    $0x10,%esp
f0100a19:	89 c6                	mov    %eax,%esi
f0100a1b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a1e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a21:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a24:	8b 1a                	mov    (%edx),%ebx
f0100a26:	8b 01                	mov    (%ecx),%eax
f0100a28:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a2b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a32:	eb 77                	jmp    f0100aab <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a34:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a37:	01 d8                	add    %ebx,%eax
f0100a39:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a3e:	99                   	cltd   
f0100a3f:	f7 f9                	idiv   %ecx
f0100a41:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a43:	eb 01                	jmp    f0100a46 <stab_binsearch+0x36>
			m--;
f0100a45:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a46:	39 d9                	cmp    %ebx,%ecx
f0100a48:	7c 1d                	jl     f0100a67 <stab_binsearch+0x57>
f0100a4a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a4d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a52:	39 fa                	cmp    %edi,%edx
f0100a54:	75 ef                	jne    f0100a45 <stab_binsearch+0x35>
f0100a56:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a59:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a5c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a60:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a63:	73 18                	jae    f0100a7d <stab_binsearch+0x6d>
f0100a65:	eb 05                	jmp    f0100a6c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a67:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a6a:	eb 3f                	jmp    f0100aab <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a6c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a6f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a71:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a74:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a7b:	eb 2e                	jmp    f0100aab <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a7d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a80:	73 15                	jae    f0100a97 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a82:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a85:	48                   	dec    %eax
f0100a86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a89:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a8c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a95:	eb 14                	jmp    f0100aab <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a97:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a9a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a9d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a9f:	ff 45 0c             	incl   0xc(%ebp)
f0100aa2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100aab:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100aae:	7e 84                	jle    f0100a34 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ab0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ab4:	75 0d                	jne    f0100ac3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ab6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ab9:	8b 00                	mov    (%eax),%eax
f0100abb:	48                   	dec    %eax
f0100abc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100abf:	89 07                	mov    %eax,(%edi)
f0100ac1:	eb 22                	jmp    f0100ae5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ac3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ac8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100acb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100acd:	eb 01                	jmp    f0100ad0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100acf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad0:	39 c1                	cmp    %eax,%ecx
f0100ad2:	7d 0c                	jge    f0100ae0 <stab_binsearch+0xd0>
f0100ad4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100ad7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100adc:	39 fa                	cmp    %edi,%edx
f0100ade:	75 ef                	jne    f0100acf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ae0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ae3:	89 07                	mov    %eax,(%edi)
	}
}
f0100ae5:	83 c4 10             	add    $0x10,%esp
f0100ae8:	5b                   	pop    %ebx
f0100ae9:	5e                   	pop    %esi
f0100aea:	5f                   	pop    %edi
f0100aeb:	5d                   	pop    %ebp
f0100aec:	c3                   	ret    

f0100aed <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aed:	55                   	push   %ebp
f0100aee:	89 e5                	mov    %esp,%ebp
f0100af0:	57                   	push   %edi
f0100af1:	56                   	push   %esi
f0100af2:	53                   	push   %ebx
f0100af3:	83 ec 3c             	sub    $0x3c,%esp
f0100af6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100af9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100afc:	c7 03 04 20 10 f0    	movl   $0xf0102004,(%ebx)
	info->eip_line = 0;
f0100b02:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b09:	c7 43 08 04 20 10 f0 	movl   $0xf0102004,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b10:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b17:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b1a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b21:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b27:	76 12                	jbe    f0100b3b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b29:	b8 b0 75 10 f0       	mov    $0xf01075b0,%eax
f0100b2e:	3d 21 5c 10 f0       	cmp    $0xf0105c21,%eax
f0100b33:	0f 86 eb 01 00 00    	jbe    f0100d24 <debuginfo_eip+0x237>
f0100b39:	eb 1c                	jmp    f0100b57 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b3b:	c7 44 24 08 0e 20 10 	movl   $0xf010200e,0x8(%esp)
f0100b42:	f0 
f0100b43:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b4a:	00 
f0100b4b:	c7 04 24 1b 20 10 f0 	movl   $0xf010201b,(%esp)
f0100b52:	e8 a1 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b57:	80 3d af 75 10 f0 00 	cmpb   $0x0,0xf01075af
f0100b5e:	0f 85 c7 01 00 00    	jne    f0100d2b <debuginfo_eip+0x23e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b6b:	b8 20 5c 10 f0       	mov    $0xf0105c20,%eax
f0100b70:	2d 3c 22 10 f0       	sub    $0xf010223c,%eax
f0100b75:	c1 f8 02             	sar    $0x2,%eax
f0100b78:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b7e:	83 e8 01             	sub    $0x1,%eax
f0100b81:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b84:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b88:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b8f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b92:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b95:	b8 3c 22 10 f0       	mov    $0xf010223c,%eax
f0100b9a:	e8 71 fe ff ff       	call   f0100a10 <stab_binsearch>
	if (lfile == 0)
f0100b9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba2:	85 c0                	test   %eax,%eax
f0100ba4:	0f 84 88 01 00 00    	je     f0100d32 <debuginfo_eip+0x245>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100baa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bb3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bb7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bbe:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bc4:	b8 3c 22 10 f0       	mov    $0xf010223c,%eax
f0100bc9:	e8 42 fe ff ff       	call   f0100a10 <stab_binsearch>

	if (lfun <= rfun) {
f0100bce:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bd1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bd4:	39 d0                	cmp    %edx,%eax
f0100bd6:	7f 3d                	jg     f0100c15 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bd8:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bdb:	8d b9 3c 22 10 f0    	lea    -0xfefddc4(%ecx),%edi
f0100be1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100be4:	8b 89 3c 22 10 f0    	mov    -0xfefddc4(%ecx),%ecx
f0100bea:	bf b0 75 10 f0       	mov    $0xf01075b0,%edi
f0100bef:	81 ef 21 5c 10 f0    	sub    $0xf0105c21,%edi
f0100bf5:	39 f9                	cmp    %edi,%ecx
f0100bf7:	73 09                	jae    f0100c02 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bf9:	81 c1 21 5c 10 f0    	add    $0xf0105c21,%ecx
f0100bff:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c02:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c05:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c08:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c0b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c0d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c10:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c13:	eb 0f                	jmp    f0100c24 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c15:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c1b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c21:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c24:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c2b:	00 
f0100c2c:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c2f:	89 04 24             	mov    %eax,(%esp)
f0100c32:	e8 8d 09 00 00       	call   f01015c4 <strfind>
f0100c37:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c3a:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	
	stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0100c3d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c41:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c48:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c4b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c4e:	b8 3c 22 10 f0       	mov    $0xf010223c,%eax
f0100c53:	e8 b8 fd ff ff       	call   f0100a10 <stab_binsearch>
	if(lline<=rline)
f0100c58:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100c5b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0100c5e:	7f 0f                	jg     f0100c6f <debuginfo_eip+0x182>
		info->eip_line=stabs[rline].n_desc;
f0100c60:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c63:	0f b7 80 42 22 10 f0 	movzwl -0xfefddbe(%eax),%eax
f0100c6a:	89 43 04             	mov    %eax,0x4(%ebx)
f0100c6d:	eb 07                	jmp    f0100c76 <debuginfo_eip+0x189>
	else
		info->eip_line=-1;
f0100c6f:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c76:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c79:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c7c:	39 f2                	cmp    %esi,%edx
f0100c7e:	7c 5c                	jl     f0100cdc <debuginfo_eip+0x1ef>
	       && stabs[lline].n_type != N_SOL
f0100c80:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100c83:	8d b8 3c 22 10 f0    	lea    -0xfefddc4(%eax),%edi
f0100c89:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100c8d:	80 f9 84             	cmp    $0x84,%cl
f0100c90:	74 2b                	je     f0100cbd <debuginfo_eip+0x1d0>
f0100c92:	05 30 22 10 f0       	add    $0xf0102230,%eax
f0100c97:	eb 15                	jmp    f0100cae <debuginfo_eip+0x1c1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c99:	83 ea 01             	sub    $0x1,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c9c:	39 f2                	cmp    %esi,%edx
f0100c9e:	7c 3c                	jl     f0100cdc <debuginfo_eip+0x1ef>
	       && stabs[lline].n_type != N_SOL
f0100ca0:	89 c7                	mov    %eax,%edi
f0100ca2:	83 e8 0c             	sub    $0xc,%eax
f0100ca5:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
f0100ca9:	80 f9 84             	cmp    $0x84,%cl
f0100cac:	74 0f                	je     f0100cbd <debuginfo_eip+0x1d0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cae:	80 f9 64             	cmp    $0x64,%cl
f0100cb1:	75 e6                	jne    f0100c99 <debuginfo_eip+0x1ac>
f0100cb3:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100cb7:	74 e0                	je     f0100c99 <debuginfo_eip+0x1ac>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cb9:	39 d6                	cmp    %edx,%esi
f0100cbb:	7f 1f                	jg     f0100cdc <debuginfo_eip+0x1ef>
f0100cbd:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100cc0:	8b 82 3c 22 10 f0    	mov    -0xfefddc4(%edx),%eax
f0100cc6:	ba b0 75 10 f0       	mov    $0xf01075b0,%edx
f0100ccb:	81 ea 21 5c 10 f0    	sub    $0xf0105c21,%edx
f0100cd1:	39 d0                	cmp    %edx,%eax
f0100cd3:	73 07                	jae    f0100cdc <debuginfo_eip+0x1ef>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cd5:	05 21 5c 10 f0       	add    $0xf0105c21,%eax
f0100cda:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cdc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cdf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100ce2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ce7:	39 ca                	cmp    %ecx,%edx
f0100ce9:	7d 68                	jge    f0100d53 <debuginfo_eip+0x266>
		for (lline = lfun + 1;
f0100ceb:	8d 42 01             	lea    0x1(%edx),%eax
f0100cee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cf1:	39 c1                	cmp    %eax,%ecx
f0100cf3:	7e 44                	jle    f0100d39 <debuginfo_eip+0x24c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cf5:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cf8:	80 b8 40 22 10 f0 a0 	cmpb   $0xa0,-0xfefddc0(%eax)
f0100cff:	75 3f                	jne    f0100d40 <debuginfo_eip+0x253>
f0100d01:	83 c2 02             	add    $0x2,%edx
f0100d04:	05 30 22 10 f0       	add    $0xf0102230,%eax
f0100d09:	89 ce                	mov    %ecx,%esi
		     lline++)
			info->eip_fn_narg++;
f0100d0b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d0f:	39 f2                	cmp    %esi,%edx
f0100d11:	74 34                	je     f0100d47 <debuginfo_eip+0x25a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d13:	0f b6 48 1c          	movzbl 0x1c(%eax),%ecx
f0100d17:	83 c2 01             	add    $0x1,%edx
f0100d1a:	83 c0 0c             	add    $0xc,%eax
f0100d1d:	80 f9 a0             	cmp    $0xa0,%cl
f0100d20:	74 e9                	je     f0100d0b <debuginfo_eip+0x21e>
f0100d22:	eb 2a                	jmp    f0100d4e <debuginfo_eip+0x261>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d29:	eb 28                	jmp    f0100d53 <debuginfo_eip+0x266>
f0100d2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d30:	eb 21                	jmp    f0100d53 <debuginfo_eip+0x266>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d37:	eb 1a                	jmp    f0100d53 <debuginfo_eip+0x266>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d39:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d3e:	eb 13                	jmp    f0100d53 <debuginfo_eip+0x266>
f0100d40:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d45:	eb 0c                	jmp    f0100d53 <debuginfo_eip+0x266>
f0100d47:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d4c:	eb 05                	jmp    f0100d53 <debuginfo_eip+0x266>
f0100d4e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d53:	83 c4 3c             	add    $0x3c,%esp
f0100d56:	5b                   	pop    %ebx
f0100d57:	5e                   	pop    %esi
f0100d58:	5f                   	pop    %edi
f0100d59:	5d                   	pop    %ebp
f0100d5a:	c3                   	ret    
f0100d5b:	66 90                	xchg   %ax,%ax
f0100d5d:	66 90                	xchg   %ax,%ax
f0100d5f:	90                   	nop

f0100d60 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d60:	55                   	push   %ebp
f0100d61:	89 e5                	mov    %esp,%ebp
f0100d63:	57                   	push   %edi
f0100d64:	56                   	push   %esi
f0100d65:	53                   	push   %ebx
f0100d66:	83 ec 3c             	sub    $0x3c,%esp
f0100d69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d6c:	89 d7                	mov    %edx,%edi
f0100d6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d74:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100d77:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d7a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d7d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d82:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d85:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d88:	39 f1                	cmp    %esi,%ecx
f0100d8a:	72 14                	jb     f0100da0 <printnum+0x40>
f0100d8c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d8f:	76 0f                	jbe    f0100da0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d91:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d94:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100d97:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d9a:	85 f6                	test   %esi,%esi
f0100d9c:	7f 60                	jg     f0100dfe <printnum+0x9e>
f0100d9e:	eb 72                	jmp    f0100e12 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100da0:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100da3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100da7:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100daa:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100dad:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100db1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100db5:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100db9:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100dbd:	89 c3                	mov    %eax,%ebx
f0100dbf:	89 d6                	mov    %edx,%esi
f0100dc1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100dc4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100dc7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dcb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100dcf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd2:	89 04 24             	mov    %eax,(%esp)
f0100dd5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dd8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ddc:	e8 4f 0a 00 00       	call   f0101830 <__udivdi3>
f0100de1:	89 d9                	mov    %ebx,%ecx
f0100de3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100de7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100deb:	89 04 24             	mov    %eax,(%esp)
f0100dee:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100df2:	89 fa                	mov    %edi,%edx
f0100df4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100df7:	e8 64 ff ff ff       	call   f0100d60 <printnum>
f0100dfc:	eb 14                	jmp    f0100e12 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dfe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e02:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e05:	89 04 24             	mov    %eax,(%esp)
f0100e08:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e0a:	83 ee 01             	sub    $0x1,%esi
f0100e0d:	75 ef                	jne    f0100dfe <printnum+0x9e>
f0100e0f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e12:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e16:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e1a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e1d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e20:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e24:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e28:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e2b:	89 04 24             	mov    %eax,(%esp)
f0100e2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e31:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e35:	e8 26 0b 00 00       	call   f0101960 <__umoddi3>
f0100e3a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e3e:	0f be 80 29 20 10 f0 	movsbl -0xfefdfd7(%eax),%eax
f0100e45:	89 04 24             	mov    %eax,(%esp)
f0100e48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e4b:	ff d0                	call   *%eax
}
f0100e4d:	83 c4 3c             	add    $0x3c,%esp
f0100e50:	5b                   	pop    %ebx
f0100e51:	5e                   	pop    %esi
f0100e52:	5f                   	pop    %edi
f0100e53:	5d                   	pop    %ebp
f0100e54:	c3                   	ret    

f0100e55 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e55:	55                   	push   %ebp
f0100e56:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e58:	83 fa 01             	cmp    $0x1,%edx
f0100e5b:	7e 0e                	jle    f0100e6b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e5d:	8b 10                	mov    (%eax),%edx
f0100e5f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e62:	89 08                	mov    %ecx,(%eax)
f0100e64:	8b 02                	mov    (%edx),%eax
f0100e66:	8b 52 04             	mov    0x4(%edx),%edx
f0100e69:	eb 22                	jmp    f0100e8d <getuint+0x38>
	else if (lflag)
f0100e6b:	85 d2                	test   %edx,%edx
f0100e6d:	74 10                	je     f0100e7f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e6f:	8b 10                	mov    (%eax),%edx
f0100e71:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e74:	89 08                	mov    %ecx,(%eax)
f0100e76:	8b 02                	mov    (%edx),%eax
f0100e78:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e7d:	eb 0e                	jmp    f0100e8d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e7f:	8b 10                	mov    (%eax),%edx
f0100e81:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e84:	89 08                	mov    %ecx,(%eax)
f0100e86:	8b 02                	mov    (%edx),%eax
f0100e88:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e8d:	5d                   	pop    %ebp
f0100e8e:	c3                   	ret    

f0100e8f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e8f:	55                   	push   %ebp
f0100e90:	89 e5                	mov    %esp,%ebp
f0100e92:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e95:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e99:	8b 10                	mov    (%eax),%edx
f0100e9b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e9e:	73 0a                	jae    f0100eaa <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ea0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ea3:	89 08                	mov    %ecx,(%eax)
f0100ea5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ea8:	88 02                	mov    %al,(%edx)
}
f0100eaa:	5d                   	pop    %ebp
f0100eab:	c3                   	ret    

f0100eac <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eac:	55                   	push   %ebp
f0100ead:	89 e5                	mov    %esp,%ebp
f0100eaf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100eb2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100eb5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb9:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ebc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ec0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ec3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ec7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eca:	89 04 24             	mov    %eax,(%esp)
f0100ecd:	e8 02 00 00 00       	call   f0100ed4 <vprintfmt>
	va_end(ap);
}
f0100ed2:	c9                   	leave  
f0100ed3:	c3                   	ret    

f0100ed4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ed4:	55                   	push   %ebp
f0100ed5:	89 e5                	mov    %esp,%ebp
f0100ed7:	57                   	push   %edi
f0100ed8:	56                   	push   %esi
f0100ed9:	53                   	push   %ebx
f0100eda:	83 ec 3c             	sub    $0x3c,%esp
f0100edd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100ee0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ee3:	eb 18                	jmp    f0100efd <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ee5:	85 c0                	test   %eax,%eax
f0100ee7:	0f 84 c3 03 00 00    	je     f01012b0 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f0100eed:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ef1:	89 04 24             	mov    %eax,(%esp)
f0100ef4:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ef7:	89 f3                	mov    %esi,%ebx
f0100ef9:	eb 02                	jmp    f0100efd <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100efb:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100efd:	8d 73 01             	lea    0x1(%ebx),%esi
f0100f00:	0f b6 03             	movzbl (%ebx),%eax
f0100f03:	83 f8 25             	cmp    $0x25,%eax
f0100f06:	75 dd                	jne    f0100ee5 <vprintfmt+0x11>
f0100f08:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100f0c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f13:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f1a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f21:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f26:	eb 1d                	jmp    f0100f45 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f28:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f2a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100f2e:	eb 15                	jmp    f0100f45 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f30:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f32:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100f36:	eb 0d                	jmp    f0100f45 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f3b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f3e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f45:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f48:	0f b6 06             	movzbl (%esi),%eax
f0100f4b:	0f b6 c8             	movzbl %al,%ecx
f0100f4e:	83 e8 23             	sub    $0x23,%eax
f0100f51:	3c 55                	cmp    $0x55,%al
f0100f53:	0f 87 2f 03 00 00    	ja     f0101288 <vprintfmt+0x3b4>
f0100f59:	0f b6 c0             	movzbl %al,%eax
f0100f5c:	ff 24 85 b8 20 10 f0 	jmp    *-0xfefdf48(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f63:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100f66:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100f69:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f6d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f70:	83 f9 09             	cmp    $0x9,%ecx
f0100f73:	77 50                	ja     f0100fc5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f75:	89 de                	mov    %ebx,%esi
f0100f77:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f7a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f7d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f80:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f84:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f87:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f8a:	83 fb 09             	cmp    $0x9,%ebx
f0100f8d:	76 eb                	jbe    f0100f7a <vprintfmt+0xa6>
f0100f8f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f92:	eb 33                	jmp    f0100fc7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f94:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f97:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f9a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f9d:	8b 00                	mov    (%eax),%eax
f0100f9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa2:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fa4:	eb 21                	jmp    f0100fc7 <vprintfmt+0xf3>
f0100fa6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fa9:	85 c9                	test   %ecx,%ecx
f0100fab:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb0:	0f 49 c1             	cmovns %ecx,%eax
f0100fb3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb6:	89 de                	mov    %ebx,%esi
f0100fb8:	eb 8b                	jmp    f0100f45 <vprintfmt+0x71>
f0100fba:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fbc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fc3:	eb 80                	jmp    f0100f45 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100fc7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fcb:	0f 89 74 ff ff ff    	jns    f0100f45 <vprintfmt+0x71>
f0100fd1:	e9 62 ff ff ff       	jmp    f0100f38 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fd6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd9:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fdb:	e9 65 ff ff ff       	jmp    f0100f45 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fe0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe3:	8d 50 04             	lea    0x4(%eax),%edx
f0100fe6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fe9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fed:	8b 00                	mov    (%eax),%eax
f0100fef:	89 04 24             	mov    %eax,(%esp)
f0100ff2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100ff5:	e9 03 ff ff ff       	jmp    f0100efd <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ffa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffd:	8d 50 04             	lea    0x4(%eax),%edx
f0101000:	89 55 14             	mov    %edx,0x14(%ebp)
f0101003:	8b 00                	mov    (%eax),%eax
f0101005:	99                   	cltd   
f0101006:	31 d0                	xor    %edx,%eax
f0101008:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010100a:	83 f8 06             	cmp    $0x6,%eax
f010100d:	7f 0b                	jg     f010101a <vprintfmt+0x146>
f010100f:	8b 14 85 10 22 10 f0 	mov    -0xfefddf0(,%eax,4),%edx
f0101016:	85 d2                	test   %edx,%edx
f0101018:	75 20                	jne    f010103a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f010101a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010101e:	c7 44 24 08 41 20 10 	movl   $0xf0102041,0x8(%esp)
f0101025:	f0 
f0101026:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010102a:	8b 45 08             	mov    0x8(%ebp),%eax
f010102d:	89 04 24             	mov    %eax,(%esp)
f0101030:	e8 77 fe ff ff       	call   f0100eac <printfmt>
f0101035:	e9 c3 fe ff ff       	jmp    f0100efd <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f010103a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010103e:	c7 44 24 08 4a 20 10 	movl   $0xf010204a,0x8(%esp)
f0101045:	f0 
f0101046:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010104a:	8b 45 08             	mov    0x8(%ebp),%eax
f010104d:	89 04 24             	mov    %eax,(%esp)
f0101050:	e8 57 fe ff ff       	call   f0100eac <printfmt>
f0101055:	e9 a3 fe ff ff       	jmp    f0100efd <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010105d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101060:	8b 45 14             	mov    0x14(%ebp),%eax
f0101063:	8d 50 04             	lea    0x4(%eax),%edx
f0101066:	89 55 14             	mov    %edx,0x14(%ebp)
f0101069:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010106b:	85 c0                	test   %eax,%eax
f010106d:	ba 3a 20 10 f0       	mov    $0xf010203a,%edx
f0101072:	0f 45 d0             	cmovne %eax,%edx
f0101075:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0101078:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010107c:	74 04                	je     f0101082 <vprintfmt+0x1ae>
f010107e:	85 f6                	test   %esi,%esi
f0101080:	7f 19                	jg     f010109b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101082:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101085:	8d 70 01             	lea    0x1(%eax),%esi
f0101088:	0f b6 10             	movzbl (%eax),%edx
f010108b:	0f be c2             	movsbl %dl,%eax
f010108e:	85 c0                	test   %eax,%eax
f0101090:	0f 85 95 00 00 00    	jne    f010112b <vprintfmt+0x257>
f0101096:	e9 85 00 00 00       	jmp    f0101120 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010109b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010109f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010a2:	89 04 24             	mov    %eax,(%esp)
f01010a5:	e8 88 03 00 00       	call   f0101432 <strnlen>
f01010aa:	29 c6                	sub    %eax,%esi
f01010ac:	89 f0                	mov    %esi,%eax
f01010ae:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010b1:	85 f6                	test   %esi,%esi
f01010b3:	7e cd                	jle    f0101082 <vprintfmt+0x1ae>
					putch(padc, putdat);
f01010b5:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01010b9:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010bc:	89 c3                	mov    %eax,%ebx
f01010be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010c2:	89 34 24             	mov    %esi,(%esp)
f01010c5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010c8:	83 eb 01             	sub    $0x1,%ebx
f01010cb:	75 f1                	jne    f01010be <vprintfmt+0x1ea>
f01010cd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01010d0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010d3:	eb ad                	jmp    f0101082 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010d5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010d9:	74 1e                	je     f01010f9 <vprintfmt+0x225>
f01010db:	0f be d2             	movsbl %dl,%edx
f01010de:	83 ea 20             	sub    $0x20,%edx
f01010e1:	83 fa 5e             	cmp    $0x5e,%edx
f01010e4:	76 13                	jbe    f01010f9 <vprintfmt+0x225>
					putch('?', putdat);
f01010e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010ed:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010f4:	ff 55 08             	call   *0x8(%ebp)
f01010f7:	eb 0d                	jmp    f0101106 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f01010f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01010fc:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101100:	89 04 24             	mov    %eax,(%esp)
f0101103:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101106:	83 ef 01             	sub    $0x1,%edi
f0101109:	83 c6 01             	add    $0x1,%esi
f010110c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0101110:	0f be c2             	movsbl %dl,%eax
f0101113:	85 c0                	test   %eax,%eax
f0101115:	75 20                	jne    f0101137 <vprintfmt+0x263>
f0101117:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f010111a:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010111d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101120:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101124:	7f 25                	jg     f010114b <vprintfmt+0x277>
f0101126:	e9 d2 fd ff ff       	jmp    f0100efd <vprintfmt+0x29>
f010112b:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010112e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101131:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101134:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101137:	85 db                	test   %ebx,%ebx
f0101139:	78 9a                	js     f01010d5 <vprintfmt+0x201>
f010113b:	83 eb 01             	sub    $0x1,%ebx
f010113e:	79 95                	jns    f01010d5 <vprintfmt+0x201>
f0101140:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101143:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101146:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101149:	eb d5                	jmp    f0101120 <vprintfmt+0x24c>
f010114b:	8b 75 08             	mov    0x8(%ebp),%esi
f010114e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101151:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101154:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101158:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010115f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101161:	83 eb 01             	sub    $0x1,%ebx
f0101164:	75 ee                	jne    f0101154 <vprintfmt+0x280>
f0101166:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101169:	e9 8f fd ff ff       	jmp    f0100efd <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010116e:	83 fa 01             	cmp    $0x1,%edx
f0101171:	7e 16                	jle    f0101189 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f0101173:	8b 45 14             	mov    0x14(%ebp),%eax
f0101176:	8d 50 08             	lea    0x8(%eax),%edx
f0101179:	89 55 14             	mov    %edx,0x14(%ebp)
f010117c:	8b 50 04             	mov    0x4(%eax),%edx
f010117f:	8b 00                	mov    (%eax),%eax
f0101181:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101184:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101187:	eb 32                	jmp    f01011bb <vprintfmt+0x2e7>
	else if (lflag)
f0101189:	85 d2                	test   %edx,%edx
f010118b:	74 18                	je     f01011a5 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f010118d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101190:	8d 50 04             	lea    0x4(%eax),%edx
f0101193:	89 55 14             	mov    %edx,0x14(%ebp)
f0101196:	8b 30                	mov    (%eax),%esi
f0101198:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010119b:	89 f0                	mov    %esi,%eax
f010119d:	c1 f8 1f             	sar    $0x1f,%eax
f01011a0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011a3:	eb 16                	jmp    f01011bb <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f01011a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a8:	8d 50 04             	lea    0x4(%eax),%edx
f01011ab:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ae:	8b 30                	mov    (%eax),%esi
f01011b0:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01011b3:	89 f0                	mov    %esi,%eax
f01011b5:	c1 f8 1f             	sar    $0x1f,%eax
f01011b8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011be:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011c1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011c6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011ca:	0f 89 80 00 00 00    	jns    f0101250 <vprintfmt+0x37c>
				putch('-', putdat);
f01011d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d4:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011db:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011de:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011e1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011e4:	f7 d8                	neg    %eax
f01011e6:	83 d2 00             	adc    $0x0,%edx
f01011e9:	f7 da                	neg    %edx
			}
			base = 10;
f01011eb:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011f0:	eb 5e                	jmp    f0101250 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011f2:	8d 45 14             	lea    0x14(%ebp),%eax
f01011f5:	e8 5b fc ff ff       	call   f0100e55 <getuint>
			base = 10;
f01011fa:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011ff:	eb 4f                	jmp    f0101250 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
		// Replace this with your code.
			num = getuint(&ap,lflag);
f0101201:	8d 45 14             	lea    0x14(%ebp),%eax
f0101204:	e8 4c fc ff ff       	call   f0100e55 <getuint>
			base = 8;
f0101209:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010120e:	eb 40                	jmp    f0101250 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
f0101210:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101214:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010121b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010121e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101222:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101229:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010122c:	8b 45 14             	mov    0x14(%ebp),%eax
f010122f:	8d 50 04             	lea    0x4(%eax),%edx
f0101232:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101235:	8b 00                	mov    (%eax),%eax
f0101237:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010123c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101241:	eb 0d                	jmp    f0101250 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101243:	8d 45 14             	lea    0x14(%ebp),%eax
f0101246:	e8 0a fc ff ff       	call   f0100e55 <getuint>
			base = 16;
f010124b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101250:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101254:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101258:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010125b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010125f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101263:	89 04 24             	mov    %eax,(%esp)
f0101266:	89 54 24 04          	mov    %edx,0x4(%esp)
f010126a:	89 fa                	mov    %edi,%edx
f010126c:	8b 45 08             	mov    0x8(%ebp),%eax
f010126f:	e8 ec fa ff ff       	call   f0100d60 <printnum>
			break;
f0101274:	e9 84 fc ff ff       	jmp    f0100efd <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101279:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010127d:	89 0c 24             	mov    %ecx,(%esp)
f0101280:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101283:	e9 75 fc ff ff       	jmp    f0100efd <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101288:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010128c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101293:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101296:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010129a:	0f 84 5b fc ff ff    	je     f0100efb <vprintfmt+0x27>
f01012a0:	89 f3                	mov    %esi,%ebx
f01012a2:	83 eb 01             	sub    $0x1,%ebx
f01012a5:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01012a9:	75 f7                	jne    f01012a2 <vprintfmt+0x3ce>
f01012ab:	e9 4d fc ff ff       	jmp    f0100efd <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f01012b0:	83 c4 3c             	add    $0x3c,%esp
f01012b3:	5b                   	pop    %ebx
f01012b4:	5e                   	pop    %esi
f01012b5:	5f                   	pop    %edi
f01012b6:	5d                   	pop    %ebp
f01012b7:	c3                   	ret    

f01012b8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012b8:	55                   	push   %ebp
f01012b9:	89 e5                	mov    %esp,%ebp
f01012bb:	83 ec 28             	sub    $0x28,%esp
f01012be:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012c7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012cb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012d5:	85 c0                	test   %eax,%eax
f01012d7:	74 30                	je     f0101309 <vsnprintf+0x51>
f01012d9:	85 d2                	test   %edx,%edx
f01012db:	7e 2c                	jle    f0101309 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012e4:	8b 45 10             	mov    0x10(%ebp),%eax
f01012e7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012eb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f2:	c7 04 24 8f 0e 10 f0 	movl   $0xf0100e8f,(%esp)
f01012f9:	e8 d6 fb ff ff       	call   f0100ed4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101301:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101304:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101307:	eb 05                	jmp    f010130e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101309:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010130e:	c9                   	leave  
f010130f:	c3                   	ret    

f0101310 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101310:	55                   	push   %ebp
f0101311:	89 e5                	mov    %esp,%ebp
f0101313:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101316:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101319:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010131d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101320:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101324:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101327:	89 44 24 04          	mov    %eax,0x4(%esp)
f010132b:	8b 45 08             	mov    0x8(%ebp),%eax
f010132e:	89 04 24             	mov    %eax,(%esp)
f0101331:	e8 82 ff ff ff       	call   f01012b8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101336:	c9                   	leave  
f0101337:	c3                   	ret    
f0101338:	66 90                	xchg   %ax,%ax
f010133a:	66 90                	xchg   %ax,%ax
f010133c:	66 90                	xchg   %ax,%ax
f010133e:	66 90                	xchg   %ax,%ax

f0101340 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101340:	55                   	push   %ebp
f0101341:	89 e5                	mov    %esp,%ebp
f0101343:	57                   	push   %edi
f0101344:	56                   	push   %esi
f0101345:	53                   	push   %ebx
f0101346:	83 ec 1c             	sub    $0x1c,%esp
f0101349:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010134c:	85 c0                	test   %eax,%eax
f010134e:	74 10                	je     f0101360 <readline+0x20>
		cprintf("%s", prompt);
f0101350:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101354:	c7 04 24 4a 20 10 f0 	movl   $0xf010204a,(%esp)
f010135b:	e8 87 f6 ff ff       	call   f01009e7 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101360:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101367:	e8 19 f3 ff ff       	call   f0100685 <iscons>
f010136c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010136e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101373:	e8 fc f2 ff ff       	call   f0100674 <getchar>
f0101378:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010137a:	85 c0                	test   %eax,%eax
f010137c:	79 17                	jns    f0101395 <readline+0x55>
			cprintf("read error: %e\n", c);
f010137e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101382:	c7 04 24 2c 22 10 f0 	movl   $0xf010222c,(%esp)
f0101389:	e8 59 f6 ff ff       	call   f01009e7 <cprintf>
			return NULL;
f010138e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101393:	eb 6d                	jmp    f0101402 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101395:	83 f8 7f             	cmp    $0x7f,%eax
f0101398:	74 05                	je     f010139f <readline+0x5f>
f010139a:	83 f8 08             	cmp    $0x8,%eax
f010139d:	75 19                	jne    f01013b8 <readline+0x78>
f010139f:	85 f6                	test   %esi,%esi
f01013a1:	7e 15                	jle    f01013b8 <readline+0x78>
			if (echoing)
f01013a3:	85 ff                	test   %edi,%edi
f01013a5:	74 0c                	je     f01013b3 <readline+0x73>
				cputchar('\b');
f01013a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013ae:	e8 b1 f2 ff ff       	call   f0100664 <cputchar>
			i--;
f01013b3:	83 ee 01             	sub    $0x1,%esi
f01013b6:	eb bb                	jmp    f0101373 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013be:	7f 1c                	jg     f01013dc <readline+0x9c>
f01013c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013c3:	7e 17                	jle    f01013dc <readline+0x9c>
			if (echoing)
f01013c5:	85 ff                	test   %edi,%edi
f01013c7:	74 08                	je     f01013d1 <readline+0x91>
				cputchar(c);
f01013c9:	89 1c 24             	mov    %ebx,(%esp)
f01013cc:	e8 93 f2 ff ff       	call   f0100664 <cputchar>
			buf[i++] = c;
f01013d1:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f01013d7:	8d 76 01             	lea    0x1(%esi),%esi
f01013da:	eb 97                	jmp    f0101373 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013dc:	83 fb 0d             	cmp    $0xd,%ebx
f01013df:	74 05                	je     f01013e6 <readline+0xa6>
f01013e1:	83 fb 0a             	cmp    $0xa,%ebx
f01013e4:	75 8d                	jne    f0101373 <readline+0x33>
			if (echoing)
f01013e6:	85 ff                	test   %edi,%edi
f01013e8:	74 0c                	je     f01013f6 <readline+0xb6>
				cputchar('\n');
f01013ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013f1:	e8 6e f2 ff ff       	call   f0100664 <cputchar>
			buf[i] = 0;
f01013f6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01013fd:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101402:	83 c4 1c             	add    $0x1c,%esp
f0101405:	5b                   	pop    %ebx
f0101406:	5e                   	pop    %esi
f0101407:	5f                   	pop    %edi
f0101408:	5d                   	pop    %ebp
f0101409:	c3                   	ret    
f010140a:	66 90                	xchg   %ax,%ax
f010140c:	66 90                	xchg   %ax,%ax
f010140e:	66 90                	xchg   %ax,%ax

f0101410 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101410:	55                   	push   %ebp
f0101411:	89 e5                	mov    %esp,%ebp
f0101413:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101416:	80 3a 00             	cmpb   $0x0,(%edx)
f0101419:	74 10                	je     f010142b <strlen+0x1b>
f010141b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101420:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101423:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101427:	75 f7                	jne    f0101420 <strlen+0x10>
f0101429:	eb 05                	jmp    f0101430 <strlen+0x20>
f010142b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101430:	5d                   	pop    %ebp
f0101431:	c3                   	ret    

f0101432 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101432:	55                   	push   %ebp
f0101433:	89 e5                	mov    %esp,%ebp
f0101435:	53                   	push   %ebx
f0101436:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101439:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010143c:	85 c9                	test   %ecx,%ecx
f010143e:	74 1c                	je     f010145c <strnlen+0x2a>
f0101440:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101443:	74 1e                	je     f0101463 <strnlen+0x31>
f0101445:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010144a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010144c:	39 ca                	cmp    %ecx,%edx
f010144e:	74 18                	je     f0101468 <strnlen+0x36>
f0101450:	83 c2 01             	add    $0x1,%edx
f0101453:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101458:	75 f0                	jne    f010144a <strnlen+0x18>
f010145a:	eb 0c                	jmp    f0101468 <strnlen+0x36>
f010145c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101461:	eb 05                	jmp    f0101468 <strnlen+0x36>
f0101463:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101468:	5b                   	pop    %ebx
f0101469:	5d                   	pop    %ebp
f010146a:	c3                   	ret    

f010146b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010146b:	55                   	push   %ebp
f010146c:	89 e5                	mov    %esp,%ebp
f010146e:	53                   	push   %ebx
f010146f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101472:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101475:	89 c2                	mov    %eax,%edx
f0101477:	83 c2 01             	add    $0x1,%edx
f010147a:	83 c1 01             	add    $0x1,%ecx
f010147d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101481:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101484:	84 db                	test   %bl,%bl
f0101486:	75 ef                	jne    f0101477 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101488:	5b                   	pop    %ebx
f0101489:	5d                   	pop    %ebp
f010148a:	c3                   	ret    

f010148b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010148b:	55                   	push   %ebp
f010148c:	89 e5                	mov    %esp,%ebp
f010148e:	56                   	push   %esi
f010148f:	53                   	push   %ebx
f0101490:	8b 75 08             	mov    0x8(%ebp),%esi
f0101493:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101496:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101499:	85 db                	test   %ebx,%ebx
f010149b:	74 17                	je     f01014b4 <strncpy+0x29>
f010149d:	01 f3                	add    %esi,%ebx
f010149f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f01014a1:	83 c1 01             	add    $0x1,%ecx
f01014a4:	0f b6 02             	movzbl (%edx),%eax
f01014a7:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014aa:	80 3a 01             	cmpb   $0x1,(%edx)
f01014ad:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014b0:	39 d9                	cmp    %ebx,%ecx
f01014b2:	75 ed                	jne    f01014a1 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014b4:	89 f0                	mov    %esi,%eax
f01014b6:	5b                   	pop    %ebx
f01014b7:	5e                   	pop    %esi
f01014b8:	5d                   	pop    %ebp
f01014b9:	c3                   	ret    

f01014ba <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014ba:	55                   	push   %ebp
f01014bb:	89 e5                	mov    %esp,%ebp
f01014bd:	57                   	push   %edi
f01014be:	56                   	push   %esi
f01014bf:	53                   	push   %ebx
f01014c0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014c6:	8b 75 10             	mov    0x10(%ebp),%esi
f01014c9:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014cb:	85 f6                	test   %esi,%esi
f01014cd:	74 34                	je     f0101503 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f01014cf:	83 fe 01             	cmp    $0x1,%esi
f01014d2:	74 26                	je     f01014fa <strlcpy+0x40>
f01014d4:	0f b6 0b             	movzbl (%ebx),%ecx
f01014d7:	84 c9                	test   %cl,%cl
f01014d9:	74 23                	je     f01014fe <strlcpy+0x44>
f01014db:	83 ee 02             	sub    $0x2,%esi
f01014de:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f01014e3:	83 c0 01             	add    $0x1,%eax
f01014e6:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014e9:	39 f2                	cmp    %esi,%edx
f01014eb:	74 13                	je     f0101500 <strlcpy+0x46>
f01014ed:	83 c2 01             	add    $0x1,%edx
f01014f0:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014f4:	84 c9                	test   %cl,%cl
f01014f6:	75 eb                	jne    f01014e3 <strlcpy+0x29>
f01014f8:	eb 06                	jmp    f0101500 <strlcpy+0x46>
f01014fa:	89 f8                	mov    %edi,%eax
f01014fc:	eb 02                	jmp    f0101500 <strlcpy+0x46>
f01014fe:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101500:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101503:	29 f8                	sub    %edi,%eax
}
f0101505:	5b                   	pop    %ebx
f0101506:	5e                   	pop    %esi
f0101507:	5f                   	pop    %edi
f0101508:	5d                   	pop    %ebp
f0101509:	c3                   	ret    

f010150a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010150a:	55                   	push   %ebp
f010150b:	89 e5                	mov    %esp,%ebp
f010150d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101510:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101513:	0f b6 01             	movzbl (%ecx),%eax
f0101516:	84 c0                	test   %al,%al
f0101518:	74 15                	je     f010152f <strcmp+0x25>
f010151a:	3a 02                	cmp    (%edx),%al
f010151c:	75 11                	jne    f010152f <strcmp+0x25>
		p++, q++;
f010151e:	83 c1 01             	add    $0x1,%ecx
f0101521:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101524:	0f b6 01             	movzbl (%ecx),%eax
f0101527:	84 c0                	test   %al,%al
f0101529:	74 04                	je     f010152f <strcmp+0x25>
f010152b:	3a 02                	cmp    (%edx),%al
f010152d:	74 ef                	je     f010151e <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010152f:	0f b6 c0             	movzbl %al,%eax
f0101532:	0f b6 12             	movzbl (%edx),%edx
f0101535:	29 d0                	sub    %edx,%eax
}
f0101537:	5d                   	pop    %ebp
f0101538:	c3                   	ret    

f0101539 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101539:	55                   	push   %ebp
f010153a:	89 e5                	mov    %esp,%ebp
f010153c:	56                   	push   %esi
f010153d:	53                   	push   %ebx
f010153e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101541:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101544:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101547:	85 f6                	test   %esi,%esi
f0101549:	74 29                	je     f0101574 <strncmp+0x3b>
f010154b:	0f b6 03             	movzbl (%ebx),%eax
f010154e:	84 c0                	test   %al,%al
f0101550:	74 30                	je     f0101582 <strncmp+0x49>
f0101552:	3a 02                	cmp    (%edx),%al
f0101554:	75 2c                	jne    f0101582 <strncmp+0x49>
f0101556:	8d 43 01             	lea    0x1(%ebx),%eax
f0101559:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010155b:	89 c3                	mov    %eax,%ebx
f010155d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101560:	39 f0                	cmp    %esi,%eax
f0101562:	74 17                	je     f010157b <strncmp+0x42>
f0101564:	0f b6 08             	movzbl (%eax),%ecx
f0101567:	84 c9                	test   %cl,%cl
f0101569:	74 17                	je     f0101582 <strncmp+0x49>
f010156b:	83 c0 01             	add    $0x1,%eax
f010156e:	3a 0a                	cmp    (%edx),%cl
f0101570:	74 e9                	je     f010155b <strncmp+0x22>
f0101572:	eb 0e                	jmp    f0101582 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101574:	b8 00 00 00 00       	mov    $0x0,%eax
f0101579:	eb 0f                	jmp    f010158a <strncmp+0x51>
f010157b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101580:	eb 08                	jmp    f010158a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101582:	0f b6 03             	movzbl (%ebx),%eax
f0101585:	0f b6 12             	movzbl (%edx),%edx
f0101588:	29 d0                	sub    %edx,%eax
}
f010158a:	5b                   	pop    %ebx
f010158b:	5e                   	pop    %esi
f010158c:	5d                   	pop    %ebp
f010158d:	c3                   	ret    

f010158e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010158e:	55                   	push   %ebp
f010158f:	89 e5                	mov    %esp,%ebp
f0101591:	53                   	push   %ebx
f0101592:	8b 45 08             	mov    0x8(%ebp),%eax
f0101595:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101598:	0f b6 18             	movzbl (%eax),%ebx
f010159b:	84 db                	test   %bl,%bl
f010159d:	74 1d                	je     f01015bc <strchr+0x2e>
f010159f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01015a1:	38 d3                	cmp    %dl,%bl
f01015a3:	75 06                	jne    f01015ab <strchr+0x1d>
f01015a5:	eb 1a                	jmp    f01015c1 <strchr+0x33>
f01015a7:	38 ca                	cmp    %cl,%dl
f01015a9:	74 16                	je     f01015c1 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015ab:	83 c0 01             	add    $0x1,%eax
f01015ae:	0f b6 10             	movzbl (%eax),%edx
f01015b1:	84 d2                	test   %dl,%dl
f01015b3:	75 f2                	jne    f01015a7 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01015b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01015ba:	eb 05                	jmp    f01015c1 <strchr+0x33>
f01015bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015c1:	5b                   	pop    %ebx
f01015c2:	5d                   	pop    %ebp
f01015c3:	c3                   	ret    

f01015c4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015c4:	55                   	push   %ebp
f01015c5:	89 e5                	mov    %esp,%ebp
f01015c7:	53                   	push   %ebx
f01015c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01015cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01015ce:	0f b6 18             	movzbl (%eax),%ebx
f01015d1:	84 db                	test   %bl,%bl
f01015d3:	74 17                	je     f01015ec <strfind+0x28>
f01015d5:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01015d7:	38 d3                	cmp    %dl,%bl
f01015d9:	75 07                	jne    f01015e2 <strfind+0x1e>
f01015db:	eb 0f                	jmp    f01015ec <strfind+0x28>
f01015dd:	38 ca                	cmp    %cl,%dl
f01015df:	90                   	nop
f01015e0:	74 0a                	je     f01015ec <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01015e2:	83 c0 01             	add    $0x1,%eax
f01015e5:	0f b6 10             	movzbl (%eax),%edx
f01015e8:	84 d2                	test   %dl,%dl
f01015ea:	75 f1                	jne    f01015dd <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01015ec:	5b                   	pop    %ebx
f01015ed:	5d                   	pop    %ebp
f01015ee:	c3                   	ret    

f01015ef <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015ef:	55                   	push   %ebp
f01015f0:	89 e5                	mov    %esp,%ebp
f01015f2:	57                   	push   %edi
f01015f3:	56                   	push   %esi
f01015f4:	53                   	push   %ebx
f01015f5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015f8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015fb:	85 c9                	test   %ecx,%ecx
f01015fd:	74 36                	je     f0101635 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015ff:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101605:	75 28                	jne    f010162f <memset+0x40>
f0101607:	f6 c1 03             	test   $0x3,%cl
f010160a:	75 23                	jne    f010162f <memset+0x40>
		c &= 0xFF;
f010160c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101610:	89 d3                	mov    %edx,%ebx
f0101612:	c1 e3 08             	shl    $0x8,%ebx
f0101615:	89 d6                	mov    %edx,%esi
f0101617:	c1 e6 18             	shl    $0x18,%esi
f010161a:	89 d0                	mov    %edx,%eax
f010161c:	c1 e0 10             	shl    $0x10,%eax
f010161f:	09 f0                	or     %esi,%eax
f0101621:	09 c2                	or     %eax,%edx
f0101623:	89 d0                	mov    %edx,%eax
f0101625:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101627:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010162a:	fc                   	cld    
f010162b:	f3 ab                	rep stos %eax,%es:(%edi)
f010162d:	eb 06                	jmp    f0101635 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010162f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101632:	fc                   	cld    
f0101633:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101635:	89 f8                	mov    %edi,%eax
f0101637:	5b                   	pop    %ebx
f0101638:	5e                   	pop    %esi
f0101639:	5f                   	pop    %edi
f010163a:	5d                   	pop    %ebp
f010163b:	c3                   	ret    

f010163c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010163c:	55                   	push   %ebp
f010163d:	89 e5                	mov    %esp,%ebp
f010163f:	57                   	push   %edi
f0101640:	56                   	push   %esi
f0101641:	8b 45 08             	mov    0x8(%ebp),%eax
f0101644:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101647:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010164a:	39 c6                	cmp    %eax,%esi
f010164c:	73 35                	jae    f0101683 <memmove+0x47>
f010164e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101651:	39 d0                	cmp    %edx,%eax
f0101653:	73 2e                	jae    f0101683 <memmove+0x47>
		s += n;
		d += n;
f0101655:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101658:	89 d6                	mov    %edx,%esi
f010165a:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010165c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101662:	75 13                	jne    f0101677 <memmove+0x3b>
f0101664:	f6 c1 03             	test   $0x3,%cl
f0101667:	75 0e                	jne    f0101677 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101669:	83 ef 04             	sub    $0x4,%edi
f010166c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010166f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101672:	fd                   	std    
f0101673:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101675:	eb 09                	jmp    f0101680 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101677:	83 ef 01             	sub    $0x1,%edi
f010167a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010167d:	fd                   	std    
f010167e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101680:	fc                   	cld    
f0101681:	eb 1d                	jmp    f01016a0 <memmove+0x64>
f0101683:	89 f2                	mov    %esi,%edx
f0101685:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101687:	f6 c2 03             	test   $0x3,%dl
f010168a:	75 0f                	jne    f010169b <memmove+0x5f>
f010168c:	f6 c1 03             	test   $0x3,%cl
f010168f:	75 0a                	jne    f010169b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101691:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101694:	89 c7                	mov    %eax,%edi
f0101696:	fc                   	cld    
f0101697:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101699:	eb 05                	jmp    f01016a0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010169b:	89 c7                	mov    %eax,%edi
f010169d:	fc                   	cld    
f010169e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016a0:	5e                   	pop    %esi
f01016a1:	5f                   	pop    %edi
f01016a2:	5d                   	pop    %ebp
f01016a3:	c3                   	ret    

f01016a4 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01016a4:	55                   	push   %ebp
f01016a5:	89 e5                	mov    %esp,%ebp
f01016a7:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01016aa:	8b 45 10             	mov    0x10(%ebp),%eax
f01016ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01016bb:	89 04 24             	mov    %eax,(%esp)
f01016be:	e8 79 ff ff ff       	call   f010163c <memmove>
}
f01016c3:	c9                   	leave  
f01016c4:	c3                   	ret    

f01016c5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016c5:	55                   	push   %ebp
f01016c6:	89 e5                	mov    %esp,%ebp
f01016c8:	57                   	push   %edi
f01016c9:	56                   	push   %esi
f01016ca:	53                   	push   %ebx
f01016cb:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016ce:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016d1:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016d4:	8d 78 ff             	lea    -0x1(%eax),%edi
f01016d7:	85 c0                	test   %eax,%eax
f01016d9:	74 36                	je     f0101711 <memcmp+0x4c>
		if (*s1 != *s2)
f01016db:	0f b6 03             	movzbl (%ebx),%eax
f01016de:	0f b6 0e             	movzbl (%esi),%ecx
f01016e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01016e6:	38 c8                	cmp    %cl,%al
f01016e8:	74 1c                	je     f0101706 <memcmp+0x41>
f01016ea:	eb 10                	jmp    f01016fc <memcmp+0x37>
f01016ec:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016f1:	83 c2 01             	add    $0x1,%edx
f01016f4:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016f8:	38 c8                	cmp    %cl,%al
f01016fa:	74 0a                	je     f0101706 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01016fc:	0f b6 c0             	movzbl %al,%eax
f01016ff:	0f b6 c9             	movzbl %cl,%ecx
f0101702:	29 c8                	sub    %ecx,%eax
f0101704:	eb 10                	jmp    f0101716 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101706:	39 fa                	cmp    %edi,%edx
f0101708:	75 e2                	jne    f01016ec <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010170a:	b8 00 00 00 00       	mov    $0x0,%eax
f010170f:	eb 05                	jmp    f0101716 <memcmp+0x51>
f0101711:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101716:	5b                   	pop    %ebx
f0101717:	5e                   	pop    %esi
f0101718:	5f                   	pop    %edi
f0101719:	5d                   	pop    %ebp
f010171a:	c3                   	ret    

f010171b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010171b:	55                   	push   %ebp
f010171c:	89 e5                	mov    %esp,%ebp
f010171e:	53                   	push   %ebx
f010171f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101722:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0101725:	89 c2                	mov    %eax,%edx
f0101727:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010172a:	39 d0                	cmp    %edx,%eax
f010172c:	73 14                	jae    f0101742 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f010172e:	89 d9                	mov    %ebx,%ecx
f0101730:	38 18                	cmp    %bl,(%eax)
f0101732:	75 06                	jne    f010173a <memfind+0x1f>
f0101734:	eb 0c                	jmp    f0101742 <memfind+0x27>
f0101736:	38 08                	cmp    %cl,(%eax)
f0101738:	74 08                	je     f0101742 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010173a:	83 c0 01             	add    $0x1,%eax
f010173d:	39 d0                	cmp    %edx,%eax
f010173f:	90                   	nop
f0101740:	75 f4                	jne    f0101736 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101742:	5b                   	pop    %ebx
f0101743:	5d                   	pop    %ebp
f0101744:	c3                   	ret    

f0101745 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101745:	55                   	push   %ebp
f0101746:	89 e5                	mov    %esp,%ebp
f0101748:	57                   	push   %edi
f0101749:	56                   	push   %esi
f010174a:	53                   	push   %ebx
f010174b:	8b 55 08             	mov    0x8(%ebp),%edx
f010174e:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101751:	0f b6 0a             	movzbl (%edx),%ecx
f0101754:	80 f9 09             	cmp    $0x9,%cl
f0101757:	74 05                	je     f010175e <strtol+0x19>
f0101759:	80 f9 20             	cmp    $0x20,%cl
f010175c:	75 10                	jne    f010176e <strtol+0x29>
		s++;
f010175e:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101761:	0f b6 0a             	movzbl (%edx),%ecx
f0101764:	80 f9 09             	cmp    $0x9,%cl
f0101767:	74 f5                	je     f010175e <strtol+0x19>
f0101769:	80 f9 20             	cmp    $0x20,%cl
f010176c:	74 f0                	je     f010175e <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010176e:	80 f9 2b             	cmp    $0x2b,%cl
f0101771:	75 0a                	jne    f010177d <strtol+0x38>
		s++;
f0101773:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101776:	bf 00 00 00 00       	mov    $0x0,%edi
f010177b:	eb 11                	jmp    f010178e <strtol+0x49>
f010177d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101782:	80 f9 2d             	cmp    $0x2d,%cl
f0101785:	75 07                	jne    f010178e <strtol+0x49>
		s++, neg = 1;
f0101787:	83 c2 01             	add    $0x1,%edx
f010178a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010178e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101793:	75 15                	jne    f01017aa <strtol+0x65>
f0101795:	80 3a 30             	cmpb   $0x30,(%edx)
f0101798:	75 10                	jne    f01017aa <strtol+0x65>
f010179a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010179e:	75 0a                	jne    f01017aa <strtol+0x65>
		s += 2, base = 16;
f01017a0:	83 c2 02             	add    $0x2,%edx
f01017a3:	b8 10 00 00 00       	mov    $0x10,%eax
f01017a8:	eb 10                	jmp    f01017ba <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f01017aa:	85 c0                	test   %eax,%eax
f01017ac:	75 0c                	jne    f01017ba <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01017ae:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017b0:	80 3a 30             	cmpb   $0x30,(%edx)
f01017b3:	75 05                	jne    f01017ba <strtol+0x75>
		s++, base = 8;
f01017b5:	83 c2 01             	add    $0x1,%edx
f01017b8:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01017ba:	bb 00 00 00 00       	mov    $0x0,%ebx
f01017bf:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017c2:	0f b6 0a             	movzbl (%edx),%ecx
f01017c5:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01017c8:	89 f0                	mov    %esi,%eax
f01017ca:	3c 09                	cmp    $0x9,%al
f01017cc:	77 08                	ja     f01017d6 <strtol+0x91>
			dig = *s - '0';
f01017ce:	0f be c9             	movsbl %cl,%ecx
f01017d1:	83 e9 30             	sub    $0x30,%ecx
f01017d4:	eb 20                	jmp    f01017f6 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f01017d6:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01017d9:	89 f0                	mov    %esi,%eax
f01017db:	3c 19                	cmp    $0x19,%al
f01017dd:	77 08                	ja     f01017e7 <strtol+0xa2>
			dig = *s - 'a' + 10;
f01017df:	0f be c9             	movsbl %cl,%ecx
f01017e2:	83 e9 57             	sub    $0x57,%ecx
f01017e5:	eb 0f                	jmp    f01017f6 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01017e7:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01017ea:	89 f0                	mov    %esi,%eax
f01017ec:	3c 19                	cmp    $0x19,%al
f01017ee:	77 16                	ja     f0101806 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01017f0:	0f be c9             	movsbl %cl,%ecx
f01017f3:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017f6:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01017f9:	7d 0f                	jge    f010180a <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017fb:	83 c2 01             	add    $0x1,%edx
f01017fe:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101802:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101804:	eb bc                	jmp    f01017c2 <strtol+0x7d>
f0101806:	89 d8                	mov    %ebx,%eax
f0101808:	eb 02                	jmp    f010180c <strtol+0xc7>
f010180a:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010180c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101810:	74 05                	je     f0101817 <strtol+0xd2>
		*endptr = (char *) s;
f0101812:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101815:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0101817:	f7 d8                	neg    %eax
f0101819:	85 ff                	test   %edi,%edi
f010181b:	0f 44 c3             	cmove  %ebx,%eax
}
f010181e:	5b                   	pop    %ebx
f010181f:	5e                   	pop    %esi
f0101820:	5f                   	pop    %edi
f0101821:	5d                   	pop    %ebp
f0101822:	c3                   	ret    
f0101823:	66 90                	xchg   %ax,%ax
f0101825:	66 90                	xchg   %ax,%ax
f0101827:	66 90                	xchg   %ax,%ax
f0101829:	66 90                	xchg   %ax,%ax
f010182b:	66 90                	xchg   %ax,%ax
f010182d:	66 90                	xchg   %ax,%ax
f010182f:	90                   	nop

f0101830 <__udivdi3>:
f0101830:	55                   	push   %ebp
f0101831:	57                   	push   %edi
f0101832:	56                   	push   %esi
f0101833:	83 ec 0c             	sub    $0xc,%esp
f0101836:	8b 44 24 28          	mov    0x28(%esp),%eax
f010183a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010183e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101842:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101846:	85 c0                	test   %eax,%eax
f0101848:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010184c:	89 ea                	mov    %ebp,%edx
f010184e:	89 0c 24             	mov    %ecx,(%esp)
f0101851:	75 2d                	jne    f0101880 <__udivdi3+0x50>
f0101853:	39 e9                	cmp    %ebp,%ecx
f0101855:	77 61                	ja     f01018b8 <__udivdi3+0x88>
f0101857:	85 c9                	test   %ecx,%ecx
f0101859:	89 ce                	mov    %ecx,%esi
f010185b:	75 0b                	jne    f0101868 <__udivdi3+0x38>
f010185d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101862:	31 d2                	xor    %edx,%edx
f0101864:	f7 f1                	div    %ecx
f0101866:	89 c6                	mov    %eax,%esi
f0101868:	31 d2                	xor    %edx,%edx
f010186a:	89 e8                	mov    %ebp,%eax
f010186c:	f7 f6                	div    %esi
f010186e:	89 c5                	mov    %eax,%ebp
f0101870:	89 f8                	mov    %edi,%eax
f0101872:	f7 f6                	div    %esi
f0101874:	89 ea                	mov    %ebp,%edx
f0101876:	83 c4 0c             	add    $0xc,%esp
f0101879:	5e                   	pop    %esi
f010187a:	5f                   	pop    %edi
f010187b:	5d                   	pop    %ebp
f010187c:	c3                   	ret    
f010187d:	8d 76 00             	lea    0x0(%esi),%esi
f0101880:	39 e8                	cmp    %ebp,%eax
f0101882:	77 24                	ja     f01018a8 <__udivdi3+0x78>
f0101884:	0f bd e8             	bsr    %eax,%ebp
f0101887:	83 f5 1f             	xor    $0x1f,%ebp
f010188a:	75 3c                	jne    f01018c8 <__udivdi3+0x98>
f010188c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101890:	39 34 24             	cmp    %esi,(%esp)
f0101893:	0f 86 9f 00 00 00    	jbe    f0101938 <__udivdi3+0x108>
f0101899:	39 d0                	cmp    %edx,%eax
f010189b:	0f 82 97 00 00 00    	jb     f0101938 <__udivdi3+0x108>
f01018a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018a8:	31 d2                	xor    %edx,%edx
f01018aa:	31 c0                	xor    %eax,%eax
f01018ac:	83 c4 0c             	add    $0xc,%esp
f01018af:	5e                   	pop    %esi
f01018b0:	5f                   	pop    %edi
f01018b1:	5d                   	pop    %ebp
f01018b2:	c3                   	ret    
f01018b3:	90                   	nop
f01018b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018b8:	89 f8                	mov    %edi,%eax
f01018ba:	f7 f1                	div    %ecx
f01018bc:	31 d2                	xor    %edx,%edx
f01018be:	83 c4 0c             	add    $0xc,%esp
f01018c1:	5e                   	pop    %esi
f01018c2:	5f                   	pop    %edi
f01018c3:	5d                   	pop    %ebp
f01018c4:	c3                   	ret    
f01018c5:	8d 76 00             	lea    0x0(%esi),%esi
f01018c8:	89 e9                	mov    %ebp,%ecx
f01018ca:	8b 3c 24             	mov    (%esp),%edi
f01018cd:	d3 e0                	shl    %cl,%eax
f01018cf:	89 c6                	mov    %eax,%esi
f01018d1:	b8 20 00 00 00       	mov    $0x20,%eax
f01018d6:	29 e8                	sub    %ebp,%eax
f01018d8:	89 c1                	mov    %eax,%ecx
f01018da:	d3 ef                	shr    %cl,%edi
f01018dc:	89 e9                	mov    %ebp,%ecx
f01018de:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01018e2:	8b 3c 24             	mov    (%esp),%edi
f01018e5:	09 74 24 08          	or     %esi,0x8(%esp)
f01018e9:	89 d6                	mov    %edx,%esi
f01018eb:	d3 e7                	shl    %cl,%edi
f01018ed:	89 c1                	mov    %eax,%ecx
f01018ef:	89 3c 24             	mov    %edi,(%esp)
f01018f2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018f6:	d3 ee                	shr    %cl,%esi
f01018f8:	89 e9                	mov    %ebp,%ecx
f01018fa:	d3 e2                	shl    %cl,%edx
f01018fc:	89 c1                	mov    %eax,%ecx
f01018fe:	d3 ef                	shr    %cl,%edi
f0101900:	09 d7                	or     %edx,%edi
f0101902:	89 f2                	mov    %esi,%edx
f0101904:	89 f8                	mov    %edi,%eax
f0101906:	f7 74 24 08          	divl   0x8(%esp)
f010190a:	89 d6                	mov    %edx,%esi
f010190c:	89 c7                	mov    %eax,%edi
f010190e:	f7 24 24             	mull   (%esp)
f0101911:	39 d6                	cmp    %edx,%esi
f0101913:	89 14 24             	mov    %edx,(%esp)
f0101916:	72 30                	jb     f0101948 <__udivdi3+0x118>
f0101918:	8b 54 24 04          	mov    0x4(%esp),%edx
f010191c:	89 e9                	mov    %ebp,%ecx
f010191e:	d3 e2                	shl    %cl,%edx
f0101920:	39 c2                	cmp    %eax,%edx
f0101922:	73 05                	jae    f0101929 <__udivdi3+0xf9>
f0101924:	3b 34 24             	cmp    (%esp),%esi
f0101927:	74 1f                	je     f0101948 <__udivdi3+0x118>
f0101929:	89 f8                	mov    %edi,%eax
f010192b:	31 d2                	xor    %edx,%edx
f010192d:	e9 7a ff ff ff       	jmp    f01018ac <__udivdi3+0x7c>
f0101932:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101938:	31 d2                	xor    %edx,%edx
f010193a:	b8 01 00 00 00       	mov    $0x1,%eax
f010193f:	e9 68 ff ff ff       	jmp    f01018ac <__udivdi3+0x7c>
f0101944:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101948:	8d 47 ff             	lea    -0x1(%edi),%eax
f010194b:	31 d2                	xor    %edx,%edx
f010194d:	83 c4 0c             	add    $0xc,%esp
f0101950:	5e                   	pop    %esi
f0101951:	5f                   	pop    %edi
f0101952:	5d                   	pop    %ebp
f0101953:	c3                   	ret    
f0101954:	66 90                	xchg   %ax,%ax
f0101956:	66 90                	xchg   %ax,%ax
f0101958:	66 90                	xchg   %ax,%ax
f010195a:	66 90                	xchg   %ax,%ax
f010195c:	66 90                	xchg   %ax,%ax
f010195e:	66 90                	xchg   %ax,%ax

f0101960 <__umoddi3>:
f0101960:	55                   	push   %ebp
f0101961:	57                   	push   %edi
f0101962:	56                   	push   %esi
f0101963:	83 ec 14             	sub    $0x14,%esp
f0101966:	8b 44 24 28          	mov    0x28(%esp),%eax
f010196a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010196e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101972:	89 c7                	mov    %eax,%edi
f0101974:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101978:	8b 44 24 30          	mov    0x30(%esp),%eax
f010197c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101980:	89 34 24             	mov    %esi,(%esp)
f0101983:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101987:	85 c0                	test   %eax,%eax
f0101989:	89 c2                	mov    %eax,%edx
f010198b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010198f:	75 17                	jne    f01019a8 <__umoddi3+0x48>
f0101991:	39 fe                	cmp    %edi,%esi
f0101993:	76 4b                	jbe    f01019e0 <__umoddi3+0x80>
f0101995:	89 c8                	mov    %ecx,%eax
f0101997:	89 fa                	mov    %edi,%edx
f0101999:	f7 f6                	div    %esi
f010199b:	89 d0                	mov    %edx,%eax
f010199d:	31 d2                	xor    %edx,%edx
f010199f:	83 c4 14             	add    $0x14,%esp
f01019a2:	5e                   	pop    %esi
f01019a3:	5f                   	pop    %edi
f01019a4:	5d                   	pop    %ebp
f01019a5:	c3                   	ret    
f01019a6:	66 90                	xchg   %ax,%ax
f01019a8:	39 f8                	cmp    %edi,%eax
f01019aa:	77 54                	ja     f0101a00 <__umoddi3+0xa0>
f01019ac:	0f bd e8             	bsr    %eax,%ebp
f01019af:	83 f5 1f             	xor    $0x1f,%ebp
f01019b2:	75 5c                	jne    f0101a10 <__umoddi3+0xb0>
f01019b4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01019b8:	39 3c 24             	cmp    %edi,(%esp)
f01019bb:	0f 87 e7 00 00 00    	ja     f0101aa8 <__umoddi3+0x148>
f01019c1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01019c5:	29 f1                	sub    %esi,%ecx
f01019c7:	19 c7                	sbb    %eax,%edi
f01019c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019cd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019d1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019d5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01019d9:	83 c4 14             	add    $0x14,%esp
f01019dc:	5e                   	pop    %esi
f01019dd:	5f                   	pop    %edi
f01019de:	5d                   	pop    %ebp
f01019df:	c3                   	ret    
f01019e0:	85 f6                	test   %esi,%esi
f01019e2:	89 f5                	mov    %esi,%ebp
f01019e4:	75 0b                	jne    f01019f1 <__umoddi3+0x91>
f01019e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019eb:	31 d2                	xor    %edx,%edx
f01019ed:	f7 f6                	div    %esi
f01019ef:	89 c5                	mov    %eax,%ebp
f01019f1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019f5:	31 d2                	xor    %edx,%edx
f01019f7:	f7 f5                	div    %ebp
f01019f9:	89 c8                	mov    %ecx,%eax
f01019fb:	f7 f5                	div    %ebp
f01019fd:	eb 9c                	jmp    f010199b <__umoddi3+0x3b>
f01019ff:	90                   	nop
f0101a00:	89 c8                	mov    %ecx,%eax
f0101a02:	89 fa                	mov    %edi,%edx
f0101a04:	83 c4 14             	add    $0x14,%esp
f0101a07:	5e                   	pop    %esi
f0101a08:	5f                   	pop    %edi
f0101a09:	5d                   	pop    %ebp
f0101a0a:	c3                   	ret    
f0101a0b:	90                   	nop
f0101a0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a10:	8b 04 24             	mov    (%esp),%eax
f0101a13:	be 20 00 00 00       	mov    $0x20,%esi
f0101a18:	89 e9                	mov    %ebp,%ecx
f0101a1a:	29 ee                	sub    %ebp,%esi
f0101a1c:	d3 e2                	shl    %cl,%edx
f0101a1e:	89 f1                	mov    %esi,%ecx
f0101a20:	d3 e8                	shr    %cl,%eax
f0101a22:	89 e9                	mov    %ebp,%ecx
f0101a24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a28:	8b 04 24             	mov    (%esp),%eax
f0101a2b:	09 54 24 04          	or     %edx,0x4(%esp)
f0101a2f:	89 fa                	mov    %edi,%edx
f0101a31:	d3 e0                	shl    %cl,%eax
f0101a33:	89 f1                	mov    %esi,%ecx
f0101a35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a39:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101a3d:	d3 ea                	shr    %cl,%edx
f0101a3f:	89 e9                	mov    %ebp,%ecx
f0101a41:	d3 e7                	shl    %cl,%edi
f0101a43:	89 f1                	mov    %esi,%ecx
f0101a45:	d3 e8                	shr    %cl,%eax
f0101a47:	89 e9                	mov    %ebp,%ecx
f0101a49:	09 f8                	or     %edi,%eax
f0101a4b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101a4f:	f7 74 24 04          	divl   0x4(%esp)
f0101a53:	d3 e7                	shl    %cl,%edi
f0101a55:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a59:	89 d7                	mov    %edx,%edi
f0101a5b:	f7 64 24 08          	mull   0x8(%esp)
f0101a5f:	39 d7                	cmp    %edx,%edi
f0101a61:	89 c1                	mov    %eax,%ecx
f0101a63:	89 14 24             	mov    %edx,(%esp)
f0101a66:	72 2c                	jb     f0101a94 <__umoddi3+0x134>
f0101a68:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a6c:	72 22                	jb     f0101a90 <__umoddi3+0x130>
f0101a6e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a72:	29 c8                	sub    %ecx,%eax
f0101a74:	19 d7                	sbb    %edx,%edi
f0101a76:	89 e9                	mov    %ebp,%ecx
f0101a78:	89 fa                	mov    %edi,%edx
f0101a7a:	d3 e8                	shr    %cl,%eax
f0101a7c:	89 f1                	mov    %esi,%ecx
f0101a7e:	d3 e2                	shl    %cl,%edx
f0101a80:	89 e9                	mov    %ebp,%ecx
f0101a82:	d3 ef                	shr    %cl,%edi
f0101a84:	09 d0                	or     %edx,%eax
f0101a86:	89 fa                	mov    %edi,%edx
f0101a88:	83 c4 14             	add    $0x14,%esp
f0101a8b:	5e                   	pop    %esi
f0101a8c:	5f                   	pop    %edi
f0101a8d:	5d                   	pop    %ebp
f0101a8e:	c3                   	ret    
f0101a8f:	90                   	nop
f0101a90:	39 d7                	cmp    %edx,%edi
f0101a92:	75 da                	jne    f0101a6e <__umoddi3+0x10e>
f0101a94:	8b 14 24             	mov    (%esp),%edx
f0101a97:	89 c1                	mov    %eax,%ecx
f0101a99:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a9d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101aa1:	eb cb                	jmp    f0101a6e <__umoddi3+0x10e>
f0101aa3:	90                   	nop
f0101aa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101aa8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101aac:	0f 82 0f ff ff ff    	jb     f01019c1 <__umoddi3+0x61>
f0101ab2:	e9 1a ff ff ff       	jmp    f01019d1 <__umoddi3+0x71>
