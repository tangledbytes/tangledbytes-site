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

   {{< imgh src="alice-bob-carol-lamport.png" imgClass="component-img display-block" quality="100" >}}

## Network Models
- Synchronous Network: A synchronous network is a network where there exists a \\(n\\) such that no message takes takes longer 
than \\(n\\) units of time to be delivered.
- Asynchronous Network: An asynchronous network is a network where there exists no \\(n\\) such that no message takes
longer than \\(n\\) units of time to be delivered.
- Partially synchronous network: There is some \\(n\\) for which no message takes longer than \\(n\\) units of time to be delivered
but that \\(n\\) is unknown.

## Causality and happens before
??

## State and Events

