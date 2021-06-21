---
layout: post
title: "A Bit of Block Chain"
date: 2021-06-05 16:22
comments: true
tags: [blockchain, cosmwasm]
---

Hey you! Blockchain is engulfing our daily lives. With all sorts of applications built on it, the day where Blockchain will back the basic stuff you do online is coming.  Blockchain is a topic I've been following closely since 2017 and have finally given a real try from a development perspective. In this post, we will see a straightforward Smart Contract in [Cosmwasm](https://cosmwasm.com/) a [Smart Contract](https://www.investopedia.com/terms/s/smart-contracts.asp) platform built for the [Cosmos ecosystem](https://cosmos.network/). Let's check it out!

<!--more-->

# Smart Contracts

There are much better explanations about Smart Contracts out there. And much better answers about [Blockchain](https://academy.binance.com/en/articles/what-is-blockchain-technology-a-comprehensive-guide-for-beginners). I don't have to try. Some of them are [pretty skeptical](https://jimmysong.medium.com/the-truth-about-smart-contracts-ae825271811f), by the way. And I tend to agree with [most of the skepticism](https://medium.com/hackernoon/smart-contracts-are-useless-f710293ec15f) around "smart" "contracts." They aren't smart, and the resemblance with an actual on-paper contract stops at the name.

In the end, whatever they may become, Smart Contracts need to be much more accessible to the average engineer. From hello worlds to testnets, to languages, to libraries and then monitoring, metrics, profiling, better limits _(I mean resource limits)_, better querying, friendliness to the enterprise world, so on and so forth.

[Cosmwasm](https://cosmwasm.com/) is doing an amazing job in this direction, and other full-blown chains are providing similar end-to-end experiences, with [Neo](https://neo.org/) and [Klaytn](https://www.klaytn.com/) being instances of this kind of effort. We can mention others like [Celo](https://celo.org/) and [EOS](https://eos.io/) too.

Because of the current distance between Blockchain and the regular engineer, I would dare to compare the current state of affairs in the blockchain world with Java Enterprise development back in 2000. Very complex, cumbersome, cryptic, [EJB](https://en.wikipedia.org/wiki/Jakarta_Enterprise_Beans), Remoting, WebServers for deploying bizarre packages like WAR and EAR. Today t heWeb is either built on the abstracted complexity of that time or is a much simpler version of that time. And I believe the same is going to happen for Smart Contracts on a blockchain.

The Blockchain that, by the way, must have a clear cut between the ability to execute Smart Contracts as a reaction to transactions and attain consensus about these transactions.

# Consensus?

Consensus is something old in [distributed computing](https://en.wikipedia.org/wiki/Consensus_(computer_science)), with some of the algorithms becoming popular and accessible to the masses. Take, for example, [Raft](https://raft.github.io/) and [Paxos](https://www.cs.yale.edu/homes/aspnes/pinewiki/Paxos.html), they are present in most backend engineering interview nowadays.

In Java, we have great libraries offering some constructs on top of Raft protocol: [Atomix](https://atomix.io/) or [Apache Ratis](https://ratis.apache.org/). Great, so the consensus is nothing new at all, then why the hype? 

The thing is, these early consensus algorithms were not aiming to have arbitrary nodes, potentially run by not so well-intentioned players, to participate in a network that seeks to be [decentralized](https://aws.amazon.com/blockchain/decentralization-in-blockchain/). A network where any participating element can suggest changes, so a thriving community governs the network. Participants can either be trusted or [slashed](https://docs.cosmos.network/v0.42/modules/slashing/) if necessary.

As an engineer working in Payments, I want to say that I started to see many similarities between what we have been doing and the idea of Blockchain, [oracles](https://academy.binance.com/en/articles/blockchain-oracles-explained), Tokens, etc.

So yes, if you had a perception that a set of nodes playing some consensus algorithm in your private network to maintain a distributed (not decentralized) coherent state resembles a blockchain, you are right. In fact [Kaleido](https://www.kaleido.io/blockchain-blog/consensus-algorithms-poa-ibft-or-raft) offers the option to run a chain with Raft:

> With the Go-ethereum client, it offers Proof-of-Authority, Quorum client supports Istanbul BFT and Raft, and finally with Pantheon you get Proof-of-Authority and Istanbul BFT*. Let's take a closer look at them so you can decide with confidence which algorithm best fits the business needs for your consortium.

## Before the sample

Before we see the sample, I want to share where I stand regarding Blockchain or what crosses my mind when I read and study all this.

Most companies will likely aim for running their Blockchain instead of blindly going for Etherium ([Permissionless chains](https://101blockchains.com/permissioned-vs-permissionless-blockchains/)) or any other. However, although distributed, they are a 3rd party (parties?) that does not offer many guarantees compared to a cloud provider, for example, with an on-paper contract and someone you can sue if things go wrong. Thus my research orbits mostly around permissioned solutions.

Another angle pointing to Blockchain is that big companies run applications in a handful of data centers simultaneously. So we need to pick the best option to keep the state of these applications. A central database? A global database that does most of the discussed above - in terms of consensus - for us, like [Google Spanner](https://cloud.google.com/spanner? Or perhaps you have a database per data center then find a way to shard and route requests across them?

The idea of Blockchain comes pretty naturally, or daringly speaking: an application with its embedded database that remains consistent with the same application running in the other data centers. A blockchain! 

Now consider instead of multiple applications with their embedded database and a consensus devouring our network, why not N applications on top of the same consensus? Oh, smart contracts!

# 'Transactions' chain

Let's pretend we have a blockchain *(by the end of this article, you can run it if you want)* that keeps records of transactions. It also supports update these transactions to mark them as settled. *Settled* here can be understood as simple confirmation with a bank or 3rd party Payments Provider that a transaction went through.

If we were to represent the data (or state) of this contract that holds transactions. We could use something like:

"`yaml
data:
  amount: 25000 
  id: # composite id with a 3rd party name and the id of an authorization
    authz_id: "123"
    provider_name: SCR
  owner: wasm1vpt59jg3c9f8w9a8hty9m7gjwuwzp85ahgnfpg # the wallet that owns the transaction
  settled: true # flag indicating if the transaction was settled.
  # I didn't add the timestamp of settling, but it's good enough as a very minimal example
```

Great, we have the idea of the State to use in our project. Now we need to define a way to interact with this state. We provide two operations: `record_charge` and `settle.` The first is to save a [Charge*](https://stripe.com/docs/api/charges/create) and the second to make the created charge as settled.

**Charge here is a concept borrowed from Stripe for didactical purposes. I'm using interchangeably with Transaction here*

Encoding this in rust / Cosmwasm is pretty straightforward. Here the state:

```rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Transaction {
    pub id: ChargeId,
    pub amount: i32,
    pub owner: Addr,
    pub settled: bool,
}

// Just to make more practical the Charge Id is a separate struct
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct ChargeId {
    pub provider_name: std::string::String,
    pub authz_id: std::string::String,
}
```

For the `record_charge` operation, we are relying on the chain itself to get the owner from `info.sender`. This way, we know someone with a valid wallet
signed the request. We could assert if the amount is larger than 0, for example, or other assertions. But let's do it with a simplified model:

"`Rust
pub fn record_charge(
    deps: DepsMut,
    info: MessageInfo,
    id: ChargeId,
    amount: i32,
) -> Result<Response, ContractError> {

    let data = Transaction {
        id: id.clone(),
        amount: amount,
        owner: info.sender,
        settled: false,
    };

    TRANS.save(deps.storage, id.as_k().as_bytes(), &data)?;
    let mut result = Response::new();
    result.add_attribute("action", "record");
    Ok(result)
}
```

After instantiating a Transaction (not blockchain transaction, our transaction model above), we just save it and return a `Response` that will be sent to tendermint. `Attribute` here is more like a form of log / event of our transaction. If you are curious to know what is this `TRANS`, check the git repo (link at the end of the article). Now the `settle` operation:

```rust
pub fn settle(deps: DepsMut, _info: MessageInfo, id: ChargeId) -> Result<Response, ContractError> {
    let mut state: Transaction = TRANS.load(deps.storage, id.as_k().as_bytes())?;
    if state.settled {
        return Err(ContractError::AlreadySettled {});
    }

    state.settled = true;
    TRANS.save(deps.storage, id.as_k().as_bytes(), &state)?;
    let mut result = Response::new();
    result.add_attribute("action", "settle");
    Ok(result)
}
``` 

Slightly more work this time. We check first if the charge exists (yes, the magical `?` up there) and if it is not settled yet. If this is the case, we update the flag to true, and that's it.

Now, who is calling these methods? A good old pattern match on a Comswasm entrypoint:

```rust
#[entry_point]
pub fn execute(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::RecordCharge { id, amount } => record_charge(deps, info, id, amount),
        ExecuteMsg::Settle { id } => settle(deps, info, id),
    }
}
```

The structure of a Cosmwasm contract works like a Dispatcher. So remember that Comswasm is just a go module that calls a web assembly code you write in Rust. Even if you use a pure tendermint application with cosmos SDK, you see they use the same pattern, given that tendermint itself communicates with the Blockchain application using a very concise protocol described in [the specification](https://docs.tendermint.com/master/spec/). Imagine it's a dispatch [servlet](https://stackoverflow.com/questions/2769467/what-is-dispatcher-servlet-in-spring).


If you follow the Git repo and the Cosmwasm tutorial to build and deploy this contract you should be able to interact with it using the following commands, if you deploy to [oysternet-1](https://github.com/CosmWasm/testnets/tree/master/oysternet-1):

```bash
# record a charge
wasmd tx wasm execute wasm1xxlalvsdjd07p07y3rc5fu6ll8k4tmejq0 \
'{"record_charge": {"id": {"provider_name": "SCR", "authz_id" : "123"}, "amount": 25000}}' \
--from fred  --node http://rpc.oysternet.cosmwasm.com:80 \
--chain-id oysternet-1 --gas-prices 0.001usponge \
--gas auto --gas-adjustment 1.3 -y
# settle it
wasmd tx wasm execute wasm1xxlalvsdjd07p07y3rc5fu6ll8k4tmejq0 \
'{"settle": {"id": {"provider_name": "SCR", "authz_id" : "123"}}}' --from fred  --node http://rpc.oysternet.cosmwasm.com:80 --chain-id oysternet-1 --gas-prices 0.001usponge --gas auto --gas-adjustment 1.3 -y
# query it 
wasmd query wasm contract-state smart wasm1xxlalvsdjd07p07y3rc5fu6ll8k4tmejq \
'{"get_charge": {"id": {"provider_name": "SCR", "authz_id" : "123"}}}' --node http://rpc.oysternet.cosmwasm.com:80
# it outputs
data:
  amount: 25000
  id:
    authz_id: "123"
    provider_name: SCR
  owner: wasm1vpt59jg3c9f8w9a8hty9m7gjwuwzp85ahgnfpg
  settled: true 
```

This article is an ultra compressed tutorial for the sake of brevity and to point you out to more [complete and patiently written tutorials](https://docs.terra.money/contracts/tutorial/implementation.html).

With that, we were able to use the consensus of a [Byzantine Fault Tolerant](https://docs.tendermint.com/master/introduction/what-is-tendermint.html) network to make sure the transactions are correct. The use of gas in tendermint is optional, but oysternet is a real testnet provided by [Confio](https://confio.tech/), so they have it enabled.

# Conclusion
Like mentioned at some point in the post, the code is available in my github: [transactions](https://github.com/paulosuzart/transactions). *Warning: I didn't fix the tests that come with the template.* You can see the contract, the messages, and a simple query by id with more details.

It's important to remember that taking a hello world like this to a chain you / your company can run would take a lot more effort. You will need to spin up all required [nodes](https://docs.tendermint.com/master/nodes/), make sure they communicate across the data centers, establish backups, logging, and monitor recovery procedures, etc. Besides, of course, some decent CI / CD for your contracts.

There are other open questions:

**1. How to make other multi data center applications interact with this Blockchain?**
Would a light client be enough so each data center communicates with the smart contract via the local light client?

**2. How to make sure events from the Blockchain will be propagated to other systems?**
Her we fall into the typical problem of delivery guaranties. Polling vs subscribe. Diffs, offsets, and this seems to be a permanent unsolved problem even with Cosmos [IBC Relayer](https://docs.cosmos.network/master/ibc/relayer.html).

**3. How to make a back end application talk to the contracts?**
We see, by default, a lot of effort from the Blockchain niche to provide direct integration with Javascript, with a browser. This makes sense, but this almost implies building a blockchain where every user will have a wallet. And that might not be the case. Still, if that is your case, you have plenty of js libraries and [CosmosJs](https://github.com/cosmostation/cosmosjs) being a good one for cosmos ecosystem. 

**4. How slow will it be to have a blockchain in user-facing applications?**
Of course, if the user is up to use a blockchain application like Uniswap, Aaave, Yearn, and others, they are just happy with whatever latency they face. But when you plan to add a blockchain as a piece to your fleet of services, things may require a more profound analysis.

**5. How to do mass migrations of contract state?**
This situation often happens, you do an excellent design, interview your stakeholders, define your ubiquitous language, and after a couple of releases, we are to do substantial changes to schemas. How to deal with this situation if part of your fleet of services is a blockchain?

But so far, I would say my interaction with Blockchain was elucidating and removed much of the hype. It also showed me how many concepts we already use at work and that it might be a good direction to go, especially in this world of Payments. Yet, I believe the Blockchain of 5 to 10 years ahead will have few in common with what we see today, especially application development. To become mainstream, Blockchain needs to be commoditized or popularized as much as cloud computing. My research is ongoing and by no means comprehends the whole Blockchain niche. I'm sure I'll continue to learn, find answers and people who are pushing the boundaries.

What I'm up to now? I'm studying scaling blockchains with techniques like [State Channels](https://magmo.com/nitro-protocol.pdf), [Plasma](https://magmo.com/nitro-protocol.pdf) and [Roll ups](https://vitalik.ca/general/2021/01/05/rollup.html). Blockchain scaling ideas would bring some exciting constructs in the Payments world that do not necessarily involve the end-user and make a blockchain scale to the levels big e-commerce platforms need.

As blockchain enthusiasts, we must spend our energy to have impactful use cases that show their power and relevance and stop chasing the next exponential growth that will bring you a *lembo*. In the end, developers (or companies) will buy Ether if they have a nice thing to build without having to stumble upon poorly written outdated tutorials (like my own tutorial above) and solutions that are not professional enough to enter the enterprise. At least I'm committed to taking my parcel. And I hope this article brought a lot of resources you can start.

Last but not least, I genuinely believe we in engineering should be stretching our knowledge. If you dedicate time to study Blockchain, you will find ideas you can use right now, technologies, tooling, concepts. So I highly encourage you to start playing with it and collect the benefits.