---
title: "MIT 6.172 Performance Engineering"
description: "Notes from MIT 6.172 Performance Engineering Course"
date: 2023-08-25T15:13:11+05:30
draft: false
katex: true
tags: ["performance"]
---

# Notes
- Rule of Thumb: Parallelize outer loops instead of inner loops.
- Floating points aren't associative this restricts the compilers from changing the order of evaluation which might potentially improve the speed. `-ffast-math` flag allows the compilers to reorder which will result in improved performance but might result in unexpected results.

```go
// This is performance engineering

for {
    think();
    code();
    test();
}
```

## Bentley's Rules for Optimizing Work
- Given by Jon Bentley (mostly). The rules have been modernised though.
- **Work:** The work of a program (on a given input) is the sum of all the operations executed by the program.
- Must be noted that reducing work might not always reduce the running time owing to the underlying hardware complexity.
- There are 4 major categories for Bentley's rules
  - Data Structures
    1. Packing and Encoding: Idea is to store as much data as possible in one machine word which can be achieved by *achieved* 
        by encoding the data in a certain way such that it uses lesser bits (imagine JSON vs protobufs).

        For example:
        ```c
        // This struct encodes a date in just 22 bits 
        // but would have significantly more space had
        // this been stored as a string.
        //
        // Interestingly, because of padding at the end,
        // the actual size would still be 32 bits
        // (10 bits of padding)
        typedef struct {
            int year: 13;
            int month: 4;
            int day: 5;
        } date_t;
        ```

        While packing/encoding is an important optimization, it needs to be ensured that decoding doesn't becomes very difficult.

        <mark>Should be ideally be used when data needs to be moved around more frequently then it is to be decoded.</mark>  
    2. Augmentation: Augment the data structures such that we preserve informations which might help us later in reducing some work.

        For example: In a linked list if we offer a peek last then it is worth storing a tail pointer in the list which helps us avoiding iterating 
        to the end of list everytime a peek is requested.
    3. Precomputation: Precompute as much as possible, increases compile time but can significantly improve runtime performance.
 
        For example: `nCr` calculations would require a pascal's triangle. A partial pascal's triangle can be precomputed and stored during compile time.

        <mark>CAUTION: Too much precomputed data can and will affect instruction cache.</mark>
    4. Caching: Store results which were accessed recently.

        > 🤔: What if fetching cache is costlier than computing again?
    5. Sparsity: Don't store zeroes, don't compute them if not needed. For example, we know `A * 0 = 0` and `A + 0 = 0`.

        More concrete example, use **Compressed Sparse Row (CSR)** instead of a `n x n` matrix when it is a sparse matrix.
  - Logic
    1. Constant folding & propagation

        Example:
        ```go
        const RADIUS = 12
        const PI = 3.14
        // Go will "fold" this, that is, AREA value will already be there
        // in the assembly - Yeah, I verified
        const AREA = PI * RADIUS * RADIUS 
        ```
    2. Common Subexpression Elimination: Identify repeated computations and eliminate them by doing them once and reusing the result. 
        Kinda like caching except that in caching we store the result somewhere else (in a cache dedicated variable) while CSE eliminates the common 
        re-evaluation only which means that the result is already being used somewhere else in the expression (no dedicated cache variable).

        For example:
        ```go
        // ...
        a = b + c
        b = a - d
        c = b + c
        d = a - d
        // ...

        // The above can be rewritten as
        a = b + c
        b = a - d
        c = b + c // can't be `c = a`
        d = b
        ```
    3. Algebraic Identities: Simple idea, modify the identities such that they rely on cheaper (from hardware perspective) mathematical operations. For example,
        `sqrt` is a very expensive operations and if can be avoided, it should be avoided.
    4. Short Circuiting: Use conditionals for early exists.

        > 🤔: I wonder if it would be worth risking branch misprediction if the function bodies aren't expensive.
    5. Ordering tests (conditionals): The idea is that the tests which is most likely to be successful (or fail) should be done first.
        
        For example:
        ```go
        func is_whitespace(c: byte) bool {
            return c == '\r' || c == '\t' || c == ' ' || c == '\n'
        }

        // the above can be replaced with, in a document, it is far more
        // likely to hit a <space> than it is to hit a carriage return, so
        // test for that first, saves us 3 additional checks
        func is_whitespace(c: byte) bool {
            return c == ' ' || c == '\n' || c == '\t' || c == '\r'
        }
        ```
    6. Create a fast path: The idea is that if tests (conditionals) are expensive to compute then use a cheaper approximate test and only if that test fails,
        jump to the more expensive computation.
    7. Combine tests: The idea is that instead of using nested `if`, use bit magic (or any other technique) which can make the tests more plane.

        > Confused? Check [the video](https://www.youtube.com/watch?v=H-1-X9bkop8&t=3458s).
  - Loops
    1. Hoisting: Avoid recomputation of loop in-variant code each time through the body of a loop.
    2. Sentinels: Use sentinels to simplify boundary checks and use them for early exits wherever possible.
    3. Loop Unrolling: There are 2 types: (i) Full loop unrolling (ii) Parial loop unrolling. (ii) is more commoon due to
        being more compiler optimization friendly.

        <mark>If the unrolled loop is huge then just like precomputation, it will affect instruction cache.</mark>
    4. Loop Fusion/Jamming: Basically merge multiple loops together. There are 2 primary advantages:
       1. Lesser loop control overhead
       2. The data being fetched in one loop might be fetched again in another, if the loops are merged then fetching can be done just once.
    5. Eliminating wasted iterations: Do not iterate if it is not required. If a cheaper test can give us early exit, use it, it will save us the loop control
        overhead.
  - Functions
    1. Inlining: Obviously, just inline the damn function. Never too much though, again instruction cache issue will popup.
    2. Tail recursion elimination: If and whenever possible, eliminate tail recursion. Function calls have their own overhead.
    3. Coarsening recursion: The idea here is to have a more coarse base case.

        For example:
        ```go
        func quicksort(arr []int, len int) {
            if len > 0 {
                // do stuff recursively
            }
        }

        // Instead of having the above, we can
        func quicksort(arr []int, len int) {
            if len < THRESHOLD {
                insertion_sort(arr, len)
                return
            }

            // do stuff recursively
        }
        ```

## Bit Hacks

- Unsigned Integer representation: \\(x = \sum_{k = 0}^{w - 1} x_k 2^k\\) where `x` is a `w` bit word.
- Signed Integer representation (2's complement): \\(x = \left(\sum_{k = 0}^{w - 2} x_k 2^k \right) - x_{w - 1} 2^{w - 1}\\) where `x` is a `w` bit word.
  - Left most bit is the sign bit.
  - `0b000...000` is `0` while `0b111...111` is `-1`.
  - `x + ~x = -1` (if you woud think hard about it, you would realize that adding each individual bit will always look like `1 + 0`, hence it will
    always be `0b111...111` which is `-1`). This also yields that `-x = ~x + 1`.
- Some of the bit hacks can be extended to vectors as well.
- Set `kth` bit to `1`: `y = x | (1 << k)`
- Set `kth` bit to `0`: `y = x & ~(1 << k)`
- Toggle `kth` bit: `y = x ^ (1 << k)`
- Extract a bitfield from a word `x`: `(x & mask) >> shift`.
  
  > 🤔: How do I effienciently create the mask though? FWIW in C, it will generate assembly for me if I use bitfields in structs.
- Set a bitfield in a word `x` to value `y`: `x = (x & ~mask) | ((y << shift) & mask)`. Here, the `& mask` is done to ensure that any garbage value
  in `y` does not pollute `x`.
- Swap integers `x` and `y`: `x = x ^ y; y = x ^ y; x = x ^ y;` (Remember, `x ^ x = 0`, `x ^ 0 = x` and XOR is associative).
  
  > This will perform poorly than a simple temp variable swap because this won't have any **_instruction-level parallelism (ILP)_**.
- Branchless unsigned integer minimum `r`: `r = y ^ ((x ^ y) & -(x < y))` 🤯.
  
  > Might not work as it is in golang, will require either a conversion or unsafe casting.
- `__restrict` or in C99 `restrict` keyword tells the compiler that there are no aliases to a pointer which allows the compiler to do more optimizations.
- <mark>A branch is predictable if it returns the same value **most** of the time.</mark> See a nice branchless 2way merge [here](https://www.youtube.com/watch?v=ZusiKXcz_ac&t=1910s).
  
  It is noted that on modern machines a branchless 2 way merge sort would be **slower** than the branched version because compiler is smarter and figures out better optimization (like
  using `CMOV` instruction, etc.
- To compute `(x + y) % n` such that `0 <= x < n` and `0 <= y < n`, we can use `z = x + y; r = z - (n & -(z >= n));`.
- Round up to a power of 2. The solution is pretty intuitive.
   ```c
   uint64_t n;
   // ...
   --n;
   n |= n >> 1;
   n |= n >> 2;
   n |= n >> 4;
   n |= n >> 8;
   n |= n >> 16;
   n |= n >> 32;
   ++n;
   ```
- Compute the mask of least significant bit of a word `x`. `mask = x & ~(x - 1) = x & (-x)`.
- To compute `lg(x)` where `lg(x)` is `ln(x)/ln(2)` and `x` is a power of 2, we need to know **de Bruijn sequence**.

### de Bruijn Sequence
A de Bruijn sequence \\(s\\) of length \\(2^k\\) is a cycling 0-1 sequence such that each of the \\(2^k\\) 0-1 strings of length \\(k\\) occurs exactly once as a substring of \\(s\\).

For example, deBruijn sequence for `k = 3` will be `00011101`.

It has [many use cases](https://en.wikipedia.org/wiki/De_Bruijn_sequence) including calculating the power of 2.

The basic idea behind it is that we have, a de bruijn sequence for `k` and a table which maps the substrings to their location in the sequence then we can simply:
```c
// because x is power of 2, it is eq to shifting
uint64_t shifted_sequence = sequence * x;

// lookup in the table
int pow = table[shifted_sequence >> seq_len];
```

<mark>Now a days there are hardware instructions that will do this automatically</mark>

### N Queens Problem

The solution is good old backtracking but board representation should we use?
1. `n * n` bytes (2d array of bytes)?
2. `n * n` bits (2d array of bits)?
3. `n` bytes (we any way just need to store the position of queen in the row at a time)?

A more compact representation is using 3 bitvectors of size `n`, `2n - 1` and `2n - 1`.

### Population Count Problem
Count the number of 1 bits in a word `x`.

```c
for (r = 0; x != 0; r++)
    // this is eliminating least significant 1
    x &= x - 1;
```

The issue with above solution is that it is really efficient if there are less number of bits set to 1 however the performance degrades as the number of 1s increases.

Another solution is to store all the 1s count for each 8 bit word (256 total) in a lookup table and iterate over words in a batch size of 8.
```c
static const int count[256] = {...};
int r;

for (r = 0; x != 0; x >>= 8)
    r += count[x & 0xFF];
```

The performance of above operation is primarly constrained by the memory access speed.

There is another even more efficient (and crazy and obfsucated) solution to this problem
```c
// Create masks
M5 = ~((-1) << 32); // 0^32 1^32
M4 = M5 ^ (M5 << 16); // (0^16 1^16)^2
M3 = M4 ^ (M4 << 8); // (0^8 1^8)^4
M2 = M3 ^ (M3 << 4); // (0^4 1^4)^8
M1 = M2 ^ (M2 << 2); // (0^2 1^2)^16
M0 = M1 ^ (M1 << 0); // (01)^32

// Compute popcount
x = ((x >> 1) & M0) + (x & M0);
x = ((x >> 2) & M1) + (x & M1);
x = ((x >> 4) + x) & M2;
x = ((x >> 8) + x) & M3;
x = ((x >> 16) + x) & M4;
x = ((x >> 32) + x) & M5;
```

The above is a brainfuck but is extremely performant. No need to do this though, most modern hardware have popcount instructions now.

## Assembly Language and Computer Architecture

Four stages of compilation
1. Preprocess (can be invoked manually by `clang -E`) -> Produces preprocessed source
2. Compile (can be invoked manually by `clang -S`) -> Produces assembly
3. Assemble (can be invoked manually by `clang -c`) -> Produces object file
4. Link (can be invoked manually by `ld`) -> Produces final binary

- `objdump` can be used to disassemble if the program was compiled with `-g` (preserve debug info).

Why look at assembly?
- Compiler is a software might have bug.
- Edit assembly by hand if something isn't possible in the higher level language.
- Reveals what the compiler did and did not do.
- Reverse engineering.

> "If you really wanna understand something, you wanna understand it to the level what's necessary and one level below that." - Charles Leiserson

### Instruction Set Architecture
Specifies the syntax and semantics of assembly. There are 4 important concepts in ISA:
1. Registers
2. Instructions
3. Data Types
4. Memory addressing modes

#### Registers
Some important x86 registers
1. General Purpose Registers (16)
2. Flags register - store the status of ops, etc
3. Instruction Pointer Register - Mostly assembly execution is linear so this keeps track of the current line
4. AVX, SSE registers for SIMD operations

x86-64 did not start as x86-64 rather the word size was 16 bits initially, this is evident from the register names today.

Layout
```
-------------------------------------------------------
                        %rax                           
-------------------------------------------------------
                          |            %eax            
-------------------------------------------------------
                          |              |     %ax      
-------------------------------------------------------
                          |              |  %ah |  %al
-------------------------------------------------------
  B7  |  B6  |  B5  |  B4  |  B3  |  B2  |  B1  |  B0  
-------------------------------------------------------
```

Only `%rax`, `%rbx`, `%rcx` and `%rdx` have a seperate register name to access B1.

> `rax` was the accumulator register on which you principally did arithmetic  
> `rbx` was the base register from which you did memory address calculations  
> `rcx` was the count register which held a loop counter  
> `rdx` was the data register which you could use for I/O port access  
> `rdi` was the destination index register which pointed to the "destination" of a string operation  
> `rsi` was the source index register which pointed to the "source" of a string operation  
> `rbp` was the base pointer which pointed to the base of the current stack frame.  
> `rsp` was the stack pointer.  
>
> Source - [StackOverflow](https://stackoverflow.com/a/24147040)

Other than `rsp` (used for stack pointer) and `rbp` (used for base pointer), other registers are used as general purpose now and not actually used
for what they were original purposes. There are 8 more generate purpose registers from `r8 - r15`.

#### x86-64 Instruction Format
`<opcode> <operand-list>`.

Here,
- `<opcode>` is a short mnemonic indetifying the type of instruction
- `<operand-list>` is a 0, 1, 2 or (rarely) 3 operands seperated by commas.
- Typically all the operands are sources while one can be the destination as well.

Example: `addl %edi, %ecx ; Here %ecx is both the source and destination, like %edx = %edx + %edi`

There are 2 types of syntax.
- AT&T Syntax
  - Generated by clang, objecdump, perf
  - **Last** operand is the destination
  - `<op> A, B` means `B <- B <op> A`
- Intel Syntax
  - Used in Intel manuals
  - **First** operand is the destination
  - `<op> A, B` means `A <- A <op> B`

#### Opcode Suffixes
- Suffixes can be added to the opcodes to describe the data type of the operation or a condition code.
- A single character suffix is used.
- If none provided, inferred from the sizes of the operand registers.

Example: `movq -16(%rbp), %rax ; Moves a 64 bit integer as quad means 4 16-bit words`

#### x86-64 Data Types
{{< imgh src="x86-data-types.png" alt="table of x86-64 data types" imgClass="component-img display-block" quality="100">}}

- Sign-extension or zero-extension opcodes use two data-type suffixes.
  1. `movzbl %bl, %edx` - Move value from 8bit `%bl` register to 32bit `%edx` register with zero being filled in higher bits.
  2. `movslq %eax, %rdx` - Move value from 32bit `%eax` to 64bit `%rdx` with sign bit being filled in higher bits (eg. `1011 => 11111011` and `0011 => 00000011`).
- Results of 32 bit ops are **implicitly zero-extended** to 64 bits values. This does **not** happen for 8 or 16 bit ops (hence garbage in higher bits if not specified).

#### Conditional Operations
Conditional jumps and conditional moves use a one or two character suffix to indicate teh condition code.

Example:
```GAS
cmpq $4096, %r14 ; Set a flag in a RFLAG register
jne .LBB1_1 ; Jump if value in reg 14 != 4096
```

RFLAGS Registers
1. Bits(0), Abbr(CF), Desc(Carry) - Last ALU op generated a carry
2. Bits(1), Reserved
3. Bits(2), Abbr(PF), Desc(Parity) - 0 if result of last op had odd 1 bits, 1 otherwise
4. Bits(3), Reserved
5. Bits(4), Abbr(AF), Desc(Adjust) - NA
6. Bits(5), Reserved
7. Bits(6), Abbr(ZF), Desc(Zero) - Result of last ALU op was 0
8. Bits(7), Abbr(SF), Desc(Sign) - Last ALU op produced a value whose sign bit was set
9. Bits(8), Abbr(TF), Desc(Trap) - If set to 1, processor will execute instructions one-by-one (imagine debugger)
10. Bits(9), Abbr(IF), Desc(Interrupt enable) - Refer [wiki](https://en.wikipedia.org/wiki/Interrupt_flag)
11. Bits(10), Abbr(DF), Desc(Direction) - Refer [wiki](https://en.wikipedia.org/wiki/Direction_flag)
12. Bits(11), Abbr(OF), Desc(Overflow) - Last ALU caused overflow
13. Bits(12..=63), System Flags or Reserved

Condition Codes
1. Code(a), RFLAGS(CF = 0, ZF = 0), Desc(if above)
2. Code(ae), RFLAGS(CF = 0), Desc(if above or equal)
3. Code(c), RFLAGS(CF = 1), Desc(on carry)
4. Code(e), RFLAGS(ZF = 1), Desc(if equal)
5. Code(ge), RFLAGS(SF = OF), Desc(if greater or equal)
6. Code(ne), RFLAGS(ZF = 0), Desc(if not equal)
7. Code(o), RFLAGS(OF = 0), Desc(on overflow)
8. Code(z), RFLAGS(ZF = 1), Desc(if zero)

NOTE: Processor uses substraction for comparisons.

#### x86-64 Direct Addressing Modes
- The operands of an instruction specify values using a variety of addressing modes.
- **At most** one operand may specify a memory address.
   > I think, this means that we cannot do something like `movq 0x172 0x180`.

Direct Addressing Modes
1. Immediate: Use the specified value. Eg. `movq $172, %rdi`.
2. Register: Use the value in the specified register. Eg. `movq %rcx, %rdi`
3. Direct memory: Use teh value at the specified addres. Eg. `movq 0x172, %rdi`

#### x86-64 Indirect Addressing Modes
- Indirect === Allow specifying memory address by some computation.

Indirect Addressing Modes
1. Register indirect: The address is stored in the specified register. Eg. `movq (%rax), %rdi`
2. Register indexed: The address is a constant offset of the value in the specified register. Eg. `movq 172(%rax), %rdi`
3. Instruction-pointer relative: The address is indexed relative to `%rip`. Eg. `movq 172(%rip), %rdi`
    > How is this different from Register indexed?
4. Base Indexed Scale Displacement: This mode refers to the address `Base + Index*Scale + Displacement`.
    - Eg. `movq 172(%rdi, %rdx, 8), %rax` where `%rdi` is base, `8` is scale, `%rdx` is index and `172` is the displacement.
    - Displacement can be any 8, 16 or 32 bit value.
    - Scale can be either 1, 2, 4, or 8.
    - Base and Index need to be a GPR.
    - If unspecified, Index and Displacement default to 0.
    - If unspecified, Scale default to 1.
    - Use very frequently to access stack data, we have access to the frame base and it can be used to access data in the frame.

#### Jump Instructions
- `jmp` and `j<condition>` take a label as their operand which identifies a location in the code.
- Labels can be symbols, exact addresses or relative addresses.
- An indirect jump takes an indirect address as its operand. Example `jmp *%eax`.

Example 1:
```GAS
jge LBB0_1
...
LBB0_1:
  leaq -1(%rbx), %rdi
```

Example 2:
```GAS
jge 5  <_fib+0x15> ; I have no idea what the fuck this does.
...
15:
  leaq -1(%rbx), %rdi
```

### Interesting Assembly Idioms
1. `xor %rax %rax` - Zeroes the register. Maybe quicker than `mov $0 %rax`?
2. `test A, B` computes teh bitwise AND of `A` and `B` and discard the result, preserving the RFLAGS.
3. There are several no-op instructions like `nop`, `nop A` and `data16`.
    - They will do nothing.
    - However, they will set RFLAGS.
    - A compiler may generate these to improve memory alignment such that the instruction is aligned with the cache line (there is C directive for this as well).

### Floating-Point and Vector Hardware
- Previously FP ops were done on the software side.
- SSE and AVX do single and double precision scalar FP arithmatic.
- x87 (from 8087) support single (`float`), double (`double`) and extended precission (`double float`) scalar FP arithmatic.
- SSE and AVX instruction sets also include vector instructions.
- Compilers prefer to use SSE instructions over x87 instructions as they are simpler to compile for and to optimize.
    - SSE opcodes are similar to x86 opcodes
      
      ```GAS
      movsd (%rcx, %rsi, 8), %xmm1
      mulsd %xmm0, %xmm1
      addsd (%rax, %rsi, 8), %xmm1
      movsd %xmm1, (%rax, %rsi, 8)
      ```
- SSE instructions use 2 letter suffixes to encode the data type
    - `ss` - `float`
    - `sd` - `double`
    - `ps` - vector of single precision
    - `pd` - vector of double precision
    - Here
        - First `s` stands for single
        - First `p` stands for packed
        - Second `s` stands for single-precision
        - Second `d` stands for double-precision

#### Vector Hardware
{{< imgh src="vector-hardware.png" alt="diagram showing the vector hardware" imgClass="component-img display-block">}}

- Performs same action on a large register (that is broken down into smaller words). They all operate in a lock step.
- Depending on the architecture, memory might need to be aligned. Usually there is a performance difference, always align.
- Some machines might support per lane operations as well.
- There is support for multiple vector-instruction sets
    1. SSE instruction set - Support integer, floats and doubles.
    2. AVX instruction set - Support floats and double.
    3. AVX2 instruction set - Support interger, floats and doubles.
    4. AVX-512 (AVX3) instruction set - Register length increased to 512 bits and added new vector operations (including popcount).

#### SSE vs AVX and AVX2
- Mostly AVX and AVX2 extend the SSE instruction set.
- SSE instruction use 128bit XMM vector registers and operate on at most 2 operands at a time.
- AVX instructions can alternatively use 256bit YMM vecotr registers and can operator on 3 operands at a time: 2 source and 1 destination
operand.
   Example:
   ```GAS
   ; This will add values in register ymm0 and ymm1 and will store it in ymm2
   vaddpd %ymm0, %ymm1, %ymm2 ; %ymm2 is the destination operand
   ```
- YMM registers alias XMM registers so mutating `%xmm0` will change the value for `%ymm0`.

### Computer Architecture
{{< imgh src="5-stage-processor.png" alt="diagram showing the 5 stages in which processor does the processing" imgClass="component-img display-block">}}

Each instruction is executed through 5 stages (Vastly simplified):
1. Instruction Fetch (IF) - Read from memory.
2. Instruction Decode (ID) - Determine units and extract register args.
3. Execute (EX) - Perform ALU operations.
4. Memory (MA) - R/W data memory.
5. Write back (WB) - Store result into registers.

The 5 stage over-simplified processor does not talk about:
1. Vectors - Already discussed above.
2. Super scalar processing
3. Out of order execution
4. Branch prediction

#### Pipelined Instruction Execution
- Processor hardware exploits instruction-level parallelism by finding opportunities to execute multiple instructions simultaneously in different pipeline stages.
- Pipelining will not improve latency but will improve throughput as we can have many instructions in the pipeline.
- In practice it isn't always feasible due to pipeline stalling. Pipeline stalling can happen due to **hazards**. There are 3 types of hazards:
    1. Structural hazard: Two instructions attempt to use the same functional unit at the same time.
    2. Data hazard: An instruction depends on the result of a prior instruction in the pipeline.
        - True Dependence: Read After Write
        - Anti Dependence: Write After Read
        - Output Dependence: Write After Write
    3. Control hazard: Fetching and decoding the next instruction to execute is delayed by a decision about control flow (ie. a conditional jump).
- For complex pipelining, the idea is to have different functional units which do different things such that slower functional units do not affect faster ones (for eg. FP ops are slow mostly).
- **Bypassing** - Allows an instruction to read its arguments before they have been stored in a GPR.
- **Out of Order Execution** -  There are a bunch of tricks that the hardware can employ to eliminate dependence among the instructions which allow the processor to execute
the instructions out of order. More details [in the video](https://www.youtube.com/watch?v=L1ung0wil9Y&t=4300s).
- **Branch Prediction** - In case the processor encounters a conditional, it is going to do _speculative execution_ where it basically guesses the outcome and will execute the branch.

<hr style="margin: 4rem 0;"/>
