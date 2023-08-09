---
title: "Notes: Introduction to Reliable and Secure Distributed Programming"
description: Notes on Introduction to Reliable and Secure Distributed Programming
date: 2023-04-28T16:16:12Z
draft: false
tags: ["distributed systems", "book"]
---

These are my chapter by chapter notes from the book Introduction to Reliable and Secure Distributed Programming by Christian Cachin, Rachid Guerraoui and Luis Rodrigues.

# Chapter 1: Introduction
> A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable - Leslie Lamport

Distributed computing addresses algorithms for a set of processes that seek to achieve some form of cooperation.

**Partial failure** is a characteristic of distributed system.

## Interaction Patterns
1. Client - Server Interaction: A client process communicates with a server process. This is a distributed system as more than 1 process are cooperating to achieve a certain goal.
2. Multiparty interaction: More than 2 processes cooperate to achieve a certain goal.

More often than not it is matter of perspective. A simple looking client-server interaction might in reality be a multiparty interaction on the server side (or maybe on the client or both side).

_peer-to-peer computing_ experssion is used to indicate absence of a central server component.

## Distributed Programming Abstractions
Two primary abstractions to represent the underlying physical system:
1. processes: The _processes_ of a distributed program abstract the active entities that perform computations. It might represent a PC, a CPU core, a thread, etc.
2. links: The _links_ abstract the physical and logical network that supports communication among processes.

By combining different properties of the above abstractions, we can construct several different type of distributed system models.

Several different abstractions are constructed on top of the given system model which capture a recurring pattern in a distributed system. For example, agreeing on a certain value is a recurring pattern in a distributed system, hence it is worth creating abstraction for this pattern such that other distributed program can consume this abstraction as a module.

Sometimes the need for abstraction is a consequence of the nature of the problem (for example building a cooperative text-editor which by its very nature will involve >= 1 server and >= 1 clients) while other times it is an engineering requirement (for example building a fault-tolerant object store which store several replicas of your dog photos).

## Software Components
### Composition Model
- The book uses pseudo code for describing algorithms.
- Pseudo code reflects a reactive computing model where components of the same process communicate by exchanging events.
- An algorithm in the pseudo code is described as a set of event handlers. Event handlers react to income events and possibly trigger new events.
- Every process can be composed of >= 1 modules.
- Components/Modules is constructed as a state machine whose transitions are triggered by the reception of events.
- Event structure: `<co, EventType | Attributes, ...>` where `co` is the component for which the event is intended.
- Events from the same component are processed in the same order in which they are generated. This FIFO ordering is enforced on events exchanged locally only.
- No concurrent handling of the events. Each handling is mutually exclusive by default.

Pseudo code example:
```plain
upon event <co_1, Event_1 | att_1, att_2, ...> do
	something();
	trigger <co_2, Event_2 | att_3, att_4, ...>; // Sends Event_2 to component co_2

upon condition do // gets triggered when an internal condition turns true
	something();

// This will not process the event Event until `condition` evaluates to true. The
// algorithm assumes that the runtime can maintain a unbounded buffer to store these
// unprocessed events
upon event <co, Event | att_1, att_2, ...> such that condition do
	something();
```

### Programming Interface
- APIs of components include 2 types of events:
    1. Requests: One service invokes services of another service by sending event of `Request` type. Acts like an input for the service getting invoked. May or may not carry any payload.
	2. Indication: Used by services to deliver information to another service. Acts like output for the service firing the event. May or may not carry any payload.


### Example
- It is possible that more than one instance of a module exists, `instance <id>` helps distinguish between copies of the same module.

Example of a module:
```plain
------------------------------------------------------
module 1.1: Interface and properties of a job handler
------------------------------------------------------
Module:
	Name: JobHandler, instance jh.

Events:
	Request: <jh, Submit | job>: Requests a job to processed.
	Indication: <jh, Confirm | job>: Confirms that the given job has been (or will be) processed.

Properties:
	JH1: Guaranteed response: Every submitted job is eventually confirmed.
```

Example of a synchronous algorithm implementing the `JobHandler` module.
```plain
---------------------------------------
Algorithm 1.1: Synchronous Job Handler 
---------------------------------------
Implements:
	JobHandler, instance jh.

upon event <jh, Submit | job> do
	process(job);
	trigger <jh, Confirm | job>;
```

Example of an asynchronous algorithm implementing the `JobHandler` module.
```plain
----------------------------------------
Algorithm 1.2: Asynchronous Job Handler
----------------------------------------
Implements:
	JobHandler, instance jh.

upon event <jh, Init> do
	buffer := ∅;

upon event <jh, Submit | job> do 
	buffer := buffer ∪ {job};
	trigger <jh, Confirm | job>;

upon buffer != $phi do
	job := selectjob(buffer);
	process(job);
	buffer := buffer \ {job};
```

[^1]: [100s of impossibility results for distributed computing](https://doi.org/10.1007/s00446-003-0091-y)
