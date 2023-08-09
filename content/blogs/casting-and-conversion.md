---
title: "Getting Unsafe with Typecasting in Go"
description: Deep dive into Golang's casting and conversion
date: 2022-01-12T20:37:18.048Z
draft: false
tags: ["golang"]
---

It may appear to some that golang supports casting however in reality it does not! Golang only has conversions, in fact type casting is not even part of the [golang specification](https://go.dev/ref/spec).

So what happens when you do something like `a := int64(b)`? Of course, the answer is conversion.

[Checkout source code to dig deeper into how golang compiler handles the type conversions](https://github.com/golang/go/blob/11b28e7e98bce0d92d8b49c6d222fb66858994ff/src/cmd/compile/internal/typecheck/const.go#L78)

# Casting vs Conversion

Let’s see what is the difference between casting and conversion

> ⚠️ Some of C’s casting operators may in reality be doing conversion, but this post is not about C.
>

| Casting | Conversion |
| --- | --- |
| Compiler is instructed to map same set of bytes to a new representation (i.e casted data type). | Compiler will copy the set of bytes into a new location with the requested data type as its representation. |

# But I absolutely need casting!

If you think that you absolutely need casting and type conversion doesn’t cuts it for you, then you should think again. Take your time, think...

Still here? Okay, probably you truly need it. Let’s see how we can do type casting in golang (*I am not suggesting that this should be done*).

Here is a code snippet that tries to demonstrates the idea

```go
package main

import (
	"fmt"
	"math"
	"math/rand"
	"unsafe"
)

func main() {
	a := rand.Intn(100)

	var b float64 = *(*float64)(unsafe.Pointer(&a))
	c := float64(a)

	fmt.Printf("A => Value: %v  Binary: %b  Type: %T\n", a, a, a)
	fmt.Printf("B => Value: %v  Binary: %b  Type: %T\n", b, math.Float64bits(b), b)
	fmt.Printf("C => Value: %v  Binary: %b  Type: %T\n", c, math.Float64bits(c), c)
}
```

Let’s walkthrough the above source code line by line, starting from the `main` function:

- `a := rand.Intn(100)` is attempting to generate a random integer in the range `[0, 100)`.
- `var b float64 = *(*float64)(unsafe.Pointer(&a))` is where the actual casting happens, let’s split the line further to get a better understanding of what’s happening here
    - `unsafe.Pointer(&a)` is converting the “go pointer” into an “unsafe pointer”. Unsafe pointers are raw pointers and are as powerful (and as dangerous) as C pointers. `unsafe` package in golang is quite an interesting package and deserves a blog post of its own.
    - `(*float64)(...)` is actually ***casting*** the “unsafe pointer” into a golang float64 pointer. This is explicitly allowed by the go compiler for `unsafe.Pointer` type.
    - `*(...)` is dereferencing the pointer to obtain the value it points to and assign it to the variable `b`.
- `c := float64(a)` is doing the type ***conversion*** from type `int` to `float64`.
- Last three lines will print the value, binary representation and type of their corresponding variables.

Running the above code generates output like:

```
A => Value: 81  Binary: 1010001  Type: int
B => Value: 4e-322  Binary: 1010001  Type: float64
C => Value: 81  Binary: 100000001010100010000000000000000000000000000000000000000000000  Type: float64
```

A few important observations can be made from the generated output:

- `a != b` . So did the casting failed? Nope, it didn’t. Digging a bit deeper will show that the binary representation of the numbers are exactly same which means that casting in fact was successful. The output value of `b` is not same as that of `a` because floating points number adheres to IEEE 754 standard and are interpreted differently.
- `a == c`. Values do match however binary representation is completely different. Why is that? The answer is quite simple actually, because instead of casting we actually converted the value from `int` to `float64` which ensured that the value remains the same and changed the underlying binary representation instead.

# Conclusion

Last section was quite anti-climatic, wasn’t it? We wanted to perform casting and we did that successfully however the results were not quite what we were expecting. So is casting bad and should be completely avoided? Well, it is not bad but should indeed be avoided. But there are certain cases where you need something like what we did in the previous section, for example:

- Capturing network packets as series of bytes and then parsing it in the most performant (and dangerous) way possible.
- Generating programs which help Golang interface with other languages like C++ ([SWIG](http://www.swig.org/Doc2.0/Go.html))