---
title: "Etcd"
description: 
date: 2023-06-01T23:34:33+05:30
draft: false
tags: ["Distributed Systems"]
---
# Notes

- Uses Raft consensus algorithm
    - Client don’t have to know the leader or send their queries to the leader either. If a request is received by a follower node it will be forwarded to the leader if it is required.
    - Some queries can be processed by the follower without the intereference of the leader in which case the requests are not actually forwarded.
- Recommends not running more than 7 nodes citing
    - Google’s chubby lock service used internally at google also just runs on 5 nodes.
    - Increasing the nodes increases the fault tolerance but write performance suffers quite a lot because at least n / 2 nodes are required to agree on the value.
- Cross data centre deployments are encouraged for increased fault tolerance but will affect the performance because
    - Latency would be increased.
    - Increased latency might result in hearbeat loss which might trigger elections even when they are not required. Project recommends tuning the deployments based on the requirements.
- Recommends first removing an unhealthy node and then adding a new healthy node and never do the first because
    - Adding a new node would increase the required quorum by 1 which will cause more problem if the cluster is already unhealthy.
    - Removing 1 node first keeps the quorum size required to be same (for example if the nodes were 5 - quorum required is ( 5 / 2 + 1) 3 nodes and if one node is removed then the quorum size would still be (4 / 2 + 1) 3 nodes hence the quorum isn’t disrupted).
- By default rejects operations which etcd deems to disrupt quorums.
- Disk latency is part of leader liveness. That is to say that the leaders which have slower disks will be denounced as a leader because they can potentially slow down the entire cluster. This is done by keeping the election timeout pretty small.
- Cluster token has cluster ID as part of it which ensures that even if the token is valid the cluster shouldn’t process the request if the cluster ID isn’t the same as it could be a node of another etcd cluster or maybe a previously running etcd cluster.
- Have there own benchmarking tool.
- Recommends `fio` to benchmark disk.
- Sends snapshots to slow followers. Assumes not to take more than 30 seconds on a 1Gbps network.
- Allows changing configs both via flags as well as environment variables.
- Uses Uber’s `zap` library for logging.
- Uses gRPC + Proto Buffers for both clients and servers. Doesn’t have a query language. `etcdctl` supports some subcommands to run on the cluster like `put` , `get` etc.