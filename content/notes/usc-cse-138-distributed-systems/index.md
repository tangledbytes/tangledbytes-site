---
title: "USC CSE 138 Distributed Systems"
description: "USC CSE 138 Distributed Systems Notes"
date: 2023-08-31T16:46:37+05:30
katex: true
tags: ["distributed systems"]
---

# Notes

- A distributed system is running on several nodes connected by network and characterized by partial failure.
    - Partial failure means that some parts of the systems are working while some are not.
    - Cloud Computing Philosophy: Treat partial failures as expected and work around them.
    - HPC Philosophy: Treat partial failure as total failure. Use checkpointing to save results.
    - If a node sends a request and doesn't receives a response (when expected), there is no way for the node
    to reliably know what went wrong.
        - **Timeout** is an imperfect solution to this problem.
            - No "correct" value of timeout.
            - Will require idempotent APIs.
- Why have them?
    - Increase reliablity.
    - Potentially increase performance.
    - Potentially increase throughput.
    - More data that can fit on one machine.
    - Some more problems are distributed in nature and it is impossible to escape them.

## Time and Clocks
- Use clocks for
    - Marking points in time
    - Measure durations / intervals
- Types of clocks
    - Time of day clock
        - Will tell what time of day it is.
        - Needs to be synchronized between machines using NTP (Network Time Protocol).
        - Not good for measuring durations due to forward/backward.
        - Can be used across machines but are not ideal.
    - Monotonic clocks
        - Only goes forward.
        - Not good for marking points in time as they are not comparable across machines (obviously).
    - Logical Clocks
        - Only measure the order of events.
        - \\(A \rightarrow B\\) - \\(A\\) happened before \\(B\\).
            - \\(A\\) could have cause \\(B\\).
            - \\(B\\) could not have caused \\(A\\).

## Lamport Diagrams
- Also known as Space-Time Diagrams
- A process is represented by a line.
- Events are represented by dots on the line.
- Given any events \\(A\\) and \\(B\\), we say \\(A \rightarrow B\\), if
    1. \\(A\\) and \\(B\\) occur on the same process with \\(A\\) before \\(B\\).
    2. \\(A\\) and \\(B\\) occur on different processes where \\(A\\) is the send event and \\(B\\) is the corresponding
    receive message.
    3. If there is another event \\(C\\) such that, \\(A \rightarrow C\\) and \\(C \rightarrow B\\) [**Transitive**]
- When no happens-before relationships between two events can be established then they are said to be **concurrent**.
- Example: Here Carol receives a message out of order and is left confused.

   {{< svgx src="alice-bob-carol-lamport.svg" class="component-svgx" >}}

## Network Models
- Synchronous Network: A synchronous network is a network where there exists a \\(n\\) such that no message takes takes longer 
than \\(n\\) units of time to be delivered.
- Asynchronous Network: An asynchronous network is a network where there exists no \\(n\\) such that no message takes
longer than \\(n\\) units of time to be delivered.
- Partially synchronous network: There is some \\(n\\) for which no message takes longer than \\(n\\) units of time to be delivered
but that \\(n\\) is unknown.

## Partially Ordered Set (POSET)
- Defined for a set
- Is a binary relation, written as \\(\le\\).
- Let's us compare the elements of the set.
- Properties:
    1. Reflexity: for all \\(a \in S\\), \\(a \le a\\)
    2. Antisymmetry: for all \\(a, b \in S\\), if \\(a \le b\\) and \\(b \le a\\) then \\(a = b\\).
    3. Transitivity: for all \\(a, b, c \in S\\), if \\(a \le b\\) and \\(b \le c\\) then \\(a \le c\\).
- Happens before relation is NOT partial order because it is not reflexive and hence is called **irreflexive partial order** 
or **strict partial order**. This also means that the first property is supposed to **irreflexive** for strict POSET.

## Totally Ordered Set
- Similar to [POSET](#partially-ordered-set-poset) but adds one more property to it:
    - \\(a \le b\\) or \\(b \le a\\) (strongly connected) - Simply this forces that unlike POSET any 2 distinct elements in the set
    must be related.
- **Strict Totally Ordered Set** are strict POSET in which any 2 distinct elements are comparable.

## Logical Clocks
- Tells about ordering of events only.
- Two types are discussed here:
    1. Lamport Clocks
    2. Vector Clocks

### Lamport Clocks
- Lamport Clock is a type of a logical clock. Lamport clock of event \\(A\\) is given by \\(LC(A)\\).
- **Clock Condition**: If \\(A \rightarrow B\\) then \\(LC(A) \lt LC(B)\\).
- Lamport clocks are <mark>consistent with potential causality</mark>. It means that if there is a causal relationship between \\(A\\) and \\(B\\) that 
is \\(A \rightarrow B\\) then we know that \\(LC(A) \lt LC(B)\\). <mark>The reverse of it is however not true, that is 
\\(LC(A) \lt LC(B)\\) does not imply that \\(A \rightarrow B\\)</mark>.
- Lamport Clock Algorithm
    1. Every process keeps a counter initialized to 0.
    2. On every event on a process, the process will increment its counter by 1.
    3. When sending a message, it has to include the counter along with the message.
    4. When receiving a message, it has to set its counter to \\(\max  \left\\{ local, recv \right\\} + 1\\).
        
        > In some formulations, message received is not counted as an event which means that instead of moving counter to 
        \\(\max  \left\\{ local, recv \right\\} + 1\\) it is moved to \\(\max  \left\\{ local, recv \right\\}\\).
- <mark>Lamport clocks do not characterizes causality.</mark> That means that \\(LogicalClock(A) \lt LogicalClock(B)\\) does not imply \\(A \rightarrow B\\).
- Example
   
   {{< svgx src="lamport-clock-ex-1.svg" class="component-svgx" style="max-width: 600px" >}}

> What can be done with an implication? That is, how can \\(A \Rightarrow B\\) be helpful?
> If not directly, taking contrapositive of the implication can be helpful, i.e. \\(\neg B \Rightarrow \neg A\\).
>
> For Lamport clocks, if taken contrapositive, they can indicate when 2 events do not hold "happens before" relationship.

> Refer: [Time Clocks and the Ordering of Events in a Distributed System](https://lamport.azurewebsites.net/pubs/time-clocks.pdf).

### Vector Clocks
- Vector Clock is a type of a logical clock. Vector clock of event \\(A\\) is given by \\(VC(A)\\).
- \\(A \rightarrow B\\ \Leftrightarrow VC(A) \lt VC(B)\\).
    - This implies that vector clocks are <mark>consistent with potential causality</mark>.
    - This also implies that vector clocks <mark>characterizes causality<mark>. That means that \\(VC(A) \lt VC(B)\\) implies \\(A \rightarrow B\\).
- Vector Clock Algorithm
    1. Every process keeps a vector of integers initialized to 0. The vector is of the same size as the processes.
    2. On every event, the process increments its own position in its vector clock. This includes the internal events as well.
    3. When sending a message, the process includes its current vector clock (after incrementing from previous step - send is an event as well).
    4. When receiving a message, the process merges the its local vector with the received vector such that receiving process will set each index to
    `local[i] = max(recv[i], local[i]) + (i == localID)`.

