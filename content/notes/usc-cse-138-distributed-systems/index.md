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
- Needs a **strongly connected** graph so as to be able to **simulate a complete graph**.
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
- Will capture process state as well as channel state (which represents in-transit message).
> Refer: [Distributed Snapshots: Determining Global States of Distributed Systems](https://lamport.azurewebsites.net/pubs/chandy.pdf) <!-- @utk: TOREAD -->

## Safety and Liveness
- Safety Property
    - Says that a "bad" thing won't happen.
    - Can be voilated in a finite execution.
- Liveness Property
    - Says that eventually something "good" will happen.
    - Cannot be voilated in a finite execution.
### Reliable Delivery
- Let \\(P_1\\) be a prcocess that sends a message \\(m\\) to process \\(P_2\\). If neither \\(P_1\\) nor \\(P_2\\) crashes and not all messages are lost, then \\(P_2\\)
eventually eventually delivers \\(m\\).

> Refer: [Proving the Correctness of Multiprocess Programs](https://www.microsoft.com/en-us/research/uploads/prod/2016/12/Proving-the-Correctness-of-Multiprocess-Programs.pdf) <!-- @utk: TOREAD -->

## Fault Models
- Is a specification that says what kinds of faults a system can exhibit and this tells what kinds of faults need to be tolerated.
- Omission fault: A message is lost (a process fails to send or receive a single message).
- Crash fault: A process fails by haulting (stops sending/receiving messages) and not everyone necessarily knows it crashed.
    - Special case of omission faults where all the messages are omitted.
- Fail-Stop fault: A process fails by halting and everyone knows it crashed.
- Timing fault: A process responds too late (or too late).
- Byzantine fault: A process behaves in arbitrary or in a malicious way.

## Two Generals Problem
- In **omission model**, it is **impossible** for the 2 generals to attack and know for sure that the other will as well.
- Workarounds:
    1. **Probabilistic Certainity**: General 1 can keep sending the messages till they receive an ACK from the general 2. The idea is that, given enough retries,
    some messages will make through. If General 2 receives the message from general 1 even after ACKing then it needs to resend the message.
    2. **Common Knowledge**: We say there is a common knowledge of \\(P\\) is when everyone knows \\(P\\), everyone knows that everyone knows \\(P\\),
    everyone knows that everyone knows that everyone knows \\(P\\)... .
> Refer: [Knowledge and Common Knowledge in a Distributed Environment](https://web.eecs.umich.edu/~manosk/assets/papers/p549-halpern.pdf) <!-- @utk: TOREAD -->

## Fault Tolerance
- A correct program satisfies both its safety and liveness properties.
- How wrong does a program go in the presence of a given class of faults?
    |          | live        | not live  |
    |----------|-------------|-----------|
    | safe     | masking     | fail-safe |
    | not-safe | non-masking | :(        |

## Idempotence
- \\(f\\) is idempotent if \\(f(x) = f(f(x)) = f(f(f(x))) = ...\\)
- A messge that's OK to receive more than once is **idempotent**.

## Reliable Delivery
- Is **at-least-once** delivery.
- Systems that claim **exactly-once** delivery usually mean
    1. The message were idempotent anyway.
    2. They are making an effort to deduplicate messages.

## Reliable Broadcast
- If a correct process delivers \\(m\\) then all correct processes deliver \\(m\\) where \\(m\\) is a broadcast message.
    - Here the correct process means different as per the fault model under consideration.

> 💡 Fault tolerance often involves making copies!

## Throughput and Latency
- Throughput: Number of actions per unit of time.
- Latency: Time between start and end of one action.

## Replication
- Pros
    - Fault tolerance
    - Improve data locality (have data close to clients that need it)
    - Dividing up the work
- Cons
    - Potentially slower writes
    - Costlier as it will involve more hardware either on premise or in cloud
    - Potential inconsistency between data
        - Sometimes it is OK to have the replicas be out of sync
- **Strong Consistency (Informally)**: A replicate storage system is strongly consistent if clients cannot tell if the data is replicated.


### Primary-Backup Replication
{{< svgx src="primary-backup-replication.svg" class="component-svgx" >}}
- Client will send both read and write requests to the primary and primary will then make sure to replicate data on the backup nodes. Once the 
primary receives ACK from all the backups then it will ACK the client.
- Good for fault tolerance but not good for workload split and data locality.
- Due to heavy reliance on the primary node, throughput of primary-backup isn't that good.

### Chain Replication
{{< svgx src="chain-replication.svg" class="component-svgx" >}}
- Client will send read requests to the _tail_ node while will send write requests to the _head_ node. Write requests are then chain replicated to all
the other nodes and finally is written to the tail node which responds to the client with ACK.
- Good for fault tolerance and splitting workload but not so good for data locality.
- Gives better throughput than Primary-Backup replication scheme because read and writes are handled by different nodes.
- Most optimal workload for chain replication is 85% reads and 15% writes.
- Write latency is inversly proportional to the number of nodes in the chain.

> Refer: [Chain Replication for Supporting High Throughput and Availability](https://www.cs.cornell.edu/home/rvr/papers/OSDI04.pdf) <!-- @utk: TOREAD -->

> Refer: [Object Storage on CRAQ](https://pdos.csail.mit.edu/6.824/papers/craq.pdf) <!-- @utk: TOREAD -->

## Consistency Models
- Model: Set of assumptions.
- Read Your Writes Consistency: Enforces that the client should be able to read their own writes.
- FIFO Consistency: Writes done by a process are seen by all processes in the order they were issued.
- Causal Consistency: Writes that are related by happens-before must be seen in the same (causal) order by all processes.
- Strong Consistency (Informally): A replicate storage system is strongly consistent if clients cannot tell if the data is replicated.

- Causal consistency is usually considered pretty good compromise.

> Refer: [Consistency in Non-Transactional Distributed Storage Systems](https://dl.acm.org/doi/10.1145/2926965) <!-- @utk: TOREAD -->

{{< svgx src="consistency-heirarchy.svg" class="component-svgx" >}}

## Consensus
- Needed for
    - Leader election
    - Totally ordered broadcast (Atomic broadcast)
    - Group Membership
    - Distributed Mututal Exclusion
    - Distributed transaction commit
    - etc...
- Properties that consensus algorithms _try_ to satisfy:
    - Termination: Each correct process eventually decides on a value.
    - Agreement: All correct processes decide on the same value.
    - Validity/Integrity/Non-triviality: The agreed upon value must be one of the proposed values.
- No consensus algorithm can satisfy all three properties (proved in 1983 in the FLP paper) in an asynchronous network model and crash-fault model.
    - **Paxos** chooses agreement and validity while compromises termination.

> Refer: [Impossibility of Distributed Consensus with One Faulty Process](https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf) <!-- @utk: TOREAD -->

### Paxos
- There are 3 roles for processes
    1. Proposer - Proposes values
    2. Acceptor - Contributes to choosing from among the proposed values
    3. Learner - Learns the agreed upon value
- One process could take on multiple roles.
- Paxos Node
    - Any node that plays any role.
    - Must be able to persist data.
    - All the nodes need to know how many nodes is a majority of acceptors.
- Example:
    - Paxos Phase 1
        - Proposer
            - Send a `Prepare(n)` messge to (at least) a majority of acceptors.
            - `n` must be
                - Unique (globally).
                - Higher than any proposal number that this proposer has used before.
        - Acceptor:
            - On receiving a `Prepare(n)` message
                - Ignores the request if has already promised to ignore the requests with that proposal number, else promises now.
                - Replies with `Promise(n)` if makes a promises. Which implies that the acceptor is promising to ignore any request
                that comes with proposal number lower than `n`.
    - Paxos Phase 2: Proposer has received `Promise(n)` from a majority of acceptors (for some `n`)
        - Proposer
            - Send an `Accept(n, val)` message to (at least) a majority of acceptors, where
                - `n` is the proposal number that was promised.
                - `val` is the actual value it wants to propose.
        - Acceptor
            - On receiving an `Accept(n, val)`
                - Ignores if has already promised to ignore requests with the proposal number or else replies with `Accepted(n, val)` and also sends
                that message to other learners.
    - Run:
        {{< svgx src="paxos-run-example.svg" class="component-svgx" >}}

- Multi-Paxos
    - Used for deciding a sequence of values.
    - The basic idea is that a proposer can do Paxos phase 1 once and then keep on doing Paxos phase 2 (with the same proposal number) for as
    long as no other proposer comes in with a higher proposal number. The hope here is that new proposers won't show up that often and the
    system can work in harmony.
    - Once a new proposer with higher proposal number shows up, multi-paxos degrades to simple paxos again until Paxos phase 2 is started in loop
    again.
- Fault Tolerance
    - Can tolerate failures of \\(\lfloor \frac{n}{2} \rfloor\\) (minority) acceptors.
        - \\(2f + 1\\) acceptors will be needed to tolerate failure of \\(f\\) acceptors.
    - Paxos does OK under omission faults. It might not terminate but it anyway compromises termination.

- Other consensus algorithms
    1. VSR (Viewstamped Replication)
    2. ZAB (Zookeeper Atomic Broadcast)
    3. Raft

> Refer: [The Part-Time Parliament](https://www.microsoft.com/en-us/research/uploads/prod/2016/12/The-Part-Time-Parliament.pdf) <!-- @utk: TOREAD -->

> Refer: [Paxos Made Simple](https://lamport.azurewebsites.net/pubs/paxos-simple.pdf) <!-- @utk: TOREAD -->

> Refer: [Paxos Made Live: An Engineering Perspective](https://courses.cs.vt.edu/~cs5204/fall08-kafura/Papers/FaultTolerance/Paxos-Chubby.pdf) <!-- @utk: TOREAD -->

> Refer: [Zab: High Peformance Broadcast for Primary-Backup Systems](https://marcoserafini.github.io/papers/zab.pdf) <!-- @utk: TOREAD -->

> Refer: [In Search of an Understandable Consensus Algorithm (Raft)](https://raft.github.io/raft.pdf) <!-- @utk: TOREAD -->

> Refer: [Viewstamped Replication Revisisted](https://www.pmg.csail.mit.edu/papers/vr-revisited.pdf) <!-- @utk: TOREAD -->

> Refer: [Vive La Difference: Paxos vs Viewstamped Replication vs Zab](https://www.cs.cornell.edu/fbs/publications/vivaLaDifference.pdf) <!-- @utk: TOREAD -->

> Refer: [Total Order Broadcast and Multicast Algorithms: Taxonomy and Survey](https://csis.pace.edu/~marchese/CS865/Papers/defago_200356.pdf) <!-- @utk: TOREAD -->

## Active vs Passive Replication
- Both Primary-Backup and Chain Replication can be used to implement active/passive replication.
- Active Replication
    - Execute an operation on every replica.
    - Better if state update is large while the operation can be and will be smaller.
    - Operation needs to be deterministic or else every replica will end up with different state.
    - Also called **state machine replication**.
    - Consensus algorithms can be used to implement this, Paxos Made Simple paper talks about this as well.
- Passive Replication
    - Replicate the final state (after runnign the op against itself) on every replica instead of running the operation against each replica.
    - Better if state update is expensive, in that case, it can be done only on the primary and then the final state can be propagated.

## Eventual Consistency
- Reminder: If you want to be fault tolerant and strong consistency then you will need consensus sooner or later.
- Informally defined as replica eventually agreeing if clients stop submitting updates.
- Is a liveness property.
- <amrk>Other consistency guarantees are actually safety properties.</mark>
- **Strong Convergence**: Replicas that have delivered the same set of updates have equivalent state.
- **Strong eventual consistency**: Strong Convergence (safety property) + Eventual Consistency (liveness property).

## CAP
- Consistency, Availability, Partition Tolerance.
- Partitions are unavoidable.
- Cannot choose consistency and completely ignore availability because these are merely tradeoffs.

## Dynamo: Amazon's Highly Avaialable Key-value Store
- Covered in the course but will take notes in a separate section dedicated to Dynamo paper. <!-- @utk: TODO -->

## Quorum Consistency
- Quorum systems allow configuring the number of replicas that the client needs to talk to.
    - `N` - Number of replicas.
    - `W` - Write quorum - how many replicas have to acknowledge a write operation.
    - `R` - Read quorum - how many replicas have to acknowledge a read operation.
- **ROWA (Read-one-Writa-all)**
    - `W = N; R = 1`
    - Doesn't necessarily give strong consistency.
- \\(R + W > N\\) ensures that read quorum will have intersect with the write quorums.

## Sharding / Data Partitioning
- Allows to store more data that can be stored on a single node.
- Allows for more throughput.
- Good sharding strategy ingredients
    - Avoid hotspots
- \\(\frac{K}{N}\\) (where \\(K\\) is the total number of keys and \\(N\\) is the total number of nodes) is the minimum movement possible
to get an even split.

### Consistent Hashing
- Gives us the minimum data movement.
- The basic idea
    - Imagine the nodes being arranged in a ring such that each node has a value assigned to themselves.
    - Hash the items and place the item on the node whose value is just greater than the hashed value of the item 
    itself (when moving in clock-wise direction).
    - When a node is added, the items from the next node whose hashed value is lesser than the value of the newly added node should be moved
    to the newly added node.
    - If a node dies or is removed from the ring, then the next node in the ring (clockwise) needs to hold all the data being held by the
    dead node.
- One physical node can be presented as multiple virtual nodes. This allows for a better balancing as well as can account for nodes which have more
compute/storage.
- > It seems that the node should NOT be added if the ring is already stressed as the data migration might make things worse?

## Online vs Offline systems

- Online
    - Wait for client requests and try to handle them quickly
    - Low latency and availability often prioritized
    - Examples: Databases, web servers, caches etc
- Offline
    - Also called batch processing systems
    - Process LOTS of data
    - High throughput is the requirement, latency is not
    - MapReduce is a classic example
- Streaming sytems
    - Kind of a hybrid between online and offline systems.
    - Fairly new

