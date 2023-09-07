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
- <mark>Lamport clocks do not characterizes causality.</mark> That means that \\(LC(A) \lt LC(B)\\) does not imply \\(A \rightarrow B\\).
- Example
   
   {{< svgx src="lamport-clock-ex-1.svg" class="component-svgx" style="max-width: 600px" >}}

> What can be done with an implication? That is, how can \\(A \Rightarrow B\\) be helpful?
> If not directly, taking contrapositive of the implication can be helpful, i.e. \\(\neg B \Rightarrow \neg A\\).
>
> For Lamport clocks, if taken contrapositive, they can indicate when 2 events do not hold "happens before" relationship.

> Refer: [Time Clocks and the Ordering of Events in a Distributed System](https://lamport.azurewebsites.net/pubs/time-clocks.pdf). <!-- @utk: TOREAD -->

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
- Example
   
   {{< svgx src="vector-clock-ex-1.svg" class="component-svgx" >}}

## Delivery Guarantees

### FIFO Delivery
- If a process sends message \\(m_2\\) after message \\(m_1\\), any process delivering both delivers \\(m_1\\) first.
- Already part of TCP.
- Usual approach to implement FIFO delivery is to use sequence numbers.
    - Messages get tagged with sender ID and sender sequence number.
    - Senders increment their sequence number after sending.
    - If a received message's SN is the prev.SN + 1 then deliver.
- Works only if we have reliable delivery.
- Voilation
   
   {{< svgx src="fifo-voilation.svg" class="component-svgx" style="max-width: 300px" >}}

### Causal Delivery
- If \\(m_1\\)s send happened before \\(m_2\\)s send, then \\(m_1\\)s delivery must happen before \\(m_2\\)s delivery.
- It is possible that deliveries which do not voilate FIFO delivery do voilate Causal delivery. The example of this is the first diagram in the notes.
In that example, every message is delivered in the order sent by their senders (FIFO is maintained - notice that the FIFO delivery is concerned only with
ordering of messages sent by the same process) however it is a voilation of causal delivery. The reason of voilation of causal delivery is that we can easily
establish a happens-before relationship between the message's sends and then can observe that the deliveries are not in the causal order.
    - <mark>TCP cannot avoid voilation of causal delivery while it does prevent FIFO delivery voilations</mark>.
- Voilation
   
   {{< svgx src="causal-voilation.svg" class="component-svgx" style="max-width: 500px" >}}

### Totally Ordered Delivery
- If a process delivers \\(m_1\\) and then \\(m_2\\) then all processes delivering both \\(m_1\\) and \\(m_2\\) deliver \\(m_1\\) first.
- Voilation
   
   {{< svgx src="total-voilation.svg" class="component-svgx" style="max-width: 600px" >}}

## Executions
- Correctness properties of executions:
    1. FIFO Delivery
    2. Causal Delivery
    3. Totally Ordered Delivery
- There are many more correctness properties of executions.

{{< svgx src="executions.svg" class="component-svgx" >}}

## Message Types
- Unicast Messages (point-to-point): 1 sender, 1 receiver
- Multicast Messages: 1 sender and many receivers
    - Broadcast - 1 sends, everyone receives (including the sender)

## Implementing Causal Broadcast
- Vector Clocks algorithm (with a twist) - The twist being that don't count received message as events.
    - Algorithm
        1. Every process keeps a vector clock, initialized to all 0s.
        2. When a process sends a message it increments its own position in its vector clock and includes the VC with the message.
        3. When a proces **delivers** a message, it updates its VC to the pointwise maximum of its local VC and the received VC on the message.
    - Example
        
       {{< svgx src="causal-broadcast-ex1.svg" class="component-svgx" style="max-width: 600px" >}}
- Difference between Causal Delivery and Causal Broadcast
    - Delivery: Is the property of executions that we care about.
    - Broadcast: Is an algorithm that gives you causal delivery in a setting where all messages are broadcast messages.
- We want to define a deliverability condition that tells us if a received message is or is not OK to deliver.
    - This condition will use the vector clock on the message.
    - Condition: A message \\(m\\) is deliverable at a process \\(p\\) if
        1. \\(VC(m)[k] = VC(m)[k] + 1\\) if \\(k\\) is the sender.
        2. \\(VC(m)[k] \le VC(p)[k]\\) for any \\(k\\) which is not the sender.

## Distributed Snapshot
- Consistent Snapshopt: Given events \\(A\\) and \\(B\\) where \\(A \rightarrow B\\), if \\(B\\) is in the snapshot, \\(A\\) should be too.
- Channels are like communication queues which provide FIFO deliveries.
    - Denoted by \\(C_{sr}\\) where \\(s\\) is the sender process ID and \\(r\\) is the receiver process ID.
- Why?
    - Checkpointing
    - Deadlock detection
        - If we take a snapshot and find a deadlock in the snapshot then we can be sure that there is still a deadlock because once a process is
        in the state of deadlock then it will stay in the state of deadlock.
    - Detection of any stable property
        - A stable property is a property which stays true once it becomes true. Deadlock is one such property. Snapshotting can help in detection
        of such properties.

### Chandy-Lamport Snapshot Algorithm
- Developed in 1985, while vector clocks were first introduced in 1986 hence the algorithm does not uses them.
- Pros:
    - Does not require to pause application messages.
    - Takes consisten snapshots.
    - Guaranteed to terminate (assuming reliable delivery).
    - Allows having multiple initiators (**Decentralized Algorithm**).
- Cons:
    - Assumes messages are not lost, corrupted or duplicated.
    - Assumes **processes don't crash**.
- With \\(N\\) process, will require an exchange of \\(N(N - 1)\\) marker messages.
- Recording a snapshot:
    - The initiator process (one or more)
        1. Records its own state.
        2. Sends a marker message out on all its outgoing channels.
        3. Starts recording the messages it receives on all its incoming.
        channels.
    - When process \\(P_i\\) recieves a marker message on \\(C_{ki}\\)
        1. \\(P_i\\) records its state.
        2. \\(P_i\\) mark channel \\(C_{ki}\\) as empty.
        3. \\(P_i\\) sends a marker out on all its outgoing channels.
        4. \\(P_i\\) starts recording on all incoming channels except \\(C_{ki}\\).
    - Otherwise (\\(P_i\\) has already seen (sent or recvd) a marker message)
        1. \\(P_i\\) will stop recording on channel \\(C_{ki}\\).
> Refer: [Distributed Snapshots: Determining Global States of Distributed Systems](https://lamport.azurewebsites.net/pubs/chandy.pdf) <!-- @utk: TOREAD -->
