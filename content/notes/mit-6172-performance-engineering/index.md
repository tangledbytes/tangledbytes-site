---
title: "MIT 6.172 Performance Engineering"
description: "Notes from MIT 6.172 Performance Engineering Course"
date: 2023-08-25T15:13:11+05:30
draft: false
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
