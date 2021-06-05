---
layout: post
title: "A Bit of Block Chain"
date: 2021-06-05 16:22
comments: true
tags: [blockchain, cosmwasm]
---

Hey you! Blockchain is engulfing our daily lives. With all sorts of applications - *or use case* - on top if, it's more and more eminent the day where the basic stuff you do online will be backed by blockchain and you will be moving money, accessing your social networks, managing your health data, privacy, and much more with just a wallet and a couple of cross chain applications. Blockchain is a topic I've been following closer since 2017 and have finally decided to give a real try from a development perspective. In this post we will see a very simple Smart Contract in [Cosmwasm](https://cosmwasm.com/) a [Smart Contract](https://www.investopedia.com/terms/s/smart-contracts.asp) platform built for the [Cosmos ecosystem](https://cosmos.network/). Let's check it out!

<!--more-->

# Smart Contracts

There are a much better explanations about smart contracts out there. And much better explanations about [Blockchain](https://academy.binance.com/en/articles/what-is-blockchain-technology-a-comprehensive-guide-for-beginners). So I don't have to. Some of them are [pretty skeptical](https://jimmysong.medium.com/the-truth-about-smart-contracts-ae825271811f), by the way. And I tend to agree with [most of the skepticism](https://medium.com/hackernoon/smart-contracts-are-useless-f710293ec15f) around "smart" "contracts". They aren't smart, and the resemblance with a real on-paper contract stops at the name.

In the end, whatever they might become, Smart Contracts need to be much more accessible to the average engineer. From hello worlds to testnets, to languages, to libraries and then monitoring, metrics, profiling, better limits _(I mean resource limits)_, better querying, friendliness to the enterprise world, so on and so forth.

[Cosmwasm](https://cosmwasm.com/) is doing an amazing job in this direction and other full blown chains are providing similar end to end experiences, with [Neo](https://neo.org/) and [Klaytn](https://www.klaytn.com/) being instances of these kind of effort. We can mention others like [Celo](https://celo.org/) and [EOS](https://eos.io/) too.

Because of the current distance between blockchain and the regular engineer, I would dare to compare the current state of affairs in the blockchain world with the state of Java Enterprise development back in 2000. Very complex, cumbersome, cryptic, [EJB](https://en.wikipedia.org/wiki/Jakarta_Enterprise_Beans), Remoting, WebServers for deploying bizarre packages like WAR and EAR. Today much of Web is either built on top of abstracted complexity of that time or is a much better and simpler version of that time. And I believe the same is going to happen for Smart Contracts on a blockchain.

Blockchain, that by the way can / must have clear cut between the ability to execute smart contracts as a reaction to transactions and the ability to attain consensus about these transactions.

# Consensus?

Consensus is something pretty old in [distribute computing](https://en.wikipedia.org/wiki/Consensus_(computer_science)). With some of the algorithms becoming very popular and accessible to the masses. Take for example [Raft](https://raft.github.io/) and [Paxos](https://www.cs.yale.edu/homes/aspnes/pinewiki/Paxos.html).

Java offer a great library that offers some constructs on top of Raft protocol: [Atomix](https://atomix.io/) or [Apache Ratis](https://ratis.apache.org/). Great, so consensus is nothing new at all, so why the hype? The thing is, these early consensus algorithms were not aiming to have arbitrary nodes, potentially run by not so good intentioned players to participate in a network that aims to be [decentralized](https://aws.amazon.com/blockchain/decentralization-in-blockchain/), that is, a network where any participating element can suggest changes and be governed by a thriving community. To be able to decentralize and remain secure, secure elements need to be employed so a given proposed for a block in the blockchain would prove it retains a valid previous history of the chain, so the rest of the network can trust it, or even [slash](https://docs.cosmos.network/v0.42/modules/slashing/) a player it if necessary. 

I just wanna say that as a engineer working in Payments I started to see a lot of similarities between what we have been doing and the idea of blockchain, [oracles](https://academy.binance.com/en/articles/blockchain-oracles-explained), Tokens, etc.

So yes, if you was having a perception that a set of nodes playing some consensus algorithm in your own private network to maintain a distributed (not decentralized) coherent state resembles a blockchain, you are totally right. In fact [Kaleido](https://www.kaleido.io/blockchain-blog/consensus-algorithms-poa-ibft-or-raft) offers the option to run a chain with Raft:

> With the Go-ethereum client it offers Proof-of-Authority, Quorum client supports Istanbul BFT and Raft, and finally with Pantheon you get Proof-of-Authority and Istanbul BFT*. Let’s take a closer look at them so you can decide with confidence which algorithm best fits the business needs for your consortium.

## Before the sample

Before we see the sample: Most companies will be very likely aiming to run their own blockchain instead of blindly going for Etherium or any other. Although distributed, it is still a 3rd party that does not offer much guarantees when compared to a cloud provider with a on paper contract and someone you can sue if things go terribly wrong.

As in big companies we run applications in a handful of data centers at the same time, we need to choose between several options to keep the state. A central traditional database? A truly global database that does most of what was discussed above - in terms of consensus - for us, like [Google Spanner](https://cloud.google.com/spanner? Or perhaps you have a separate database per data center and find a way to shard and route requests across them?

And then the idea of blockchain, or daringly speaking, a application with it's own embedded database that remains consistent with the same application running in the other data centers. A blockchain! And going a bit further, instead of multiple applications with their own embedded database and a consensus devouring our network, why not N applications on top of the same consensus? Oh, smart contracts!

So here is where I stand in this whole history. And working in Payments recently, I see a lot of what we build having a total match with blockchain, contracts, oracles, etc. Now let's see the example.

# 'Transactions' chain

Let's pretend we have a blockchain *(by the end of this article you can actually run it if you want)* that keeps records of transactions and when they were settled. Let's take *settled* here as a simple confirmation with a bank or 3rd party Payments Provider, that a transaction went through as in the money was for example really authorized by the bank.

So if we were to represent the data (or state) of this Contract. We could use something like:

```yaml
data:
  amount: 25000 
  id: # composite id with a 3rd party name and the id of an authorization
    authz_id: "123"
    provider_name: SCR
  owner: wasm1vpt59jg3c9f8w9a8hty9m7gjwuwzp85ahgnfpg # the wallet that owns the transaction
  settled: true # flag indicating if the transaction was settled.
  # I didn't add the timestamp of settling, but it's good enough as a very minimal example
```

Great, so we have he idea of the State we are aiming. Then we need to define a way to interact with this state. Let's say we provide 2 operations: `record_charge`, and `settle`. The first to save, if not present, a [Charge*](https://stripe.com/docs/api/charges/create) and the second to make the created charge as settled.

**Charge here is a concept borrowed from Stripe for didactical purposes.*

Encoding this in rust / Cosmwasm is pretty straightforward. Here the state:

```rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Transaction {
    pub id: ChargeId,
    pub amount: i32,
    pub owner: Addr,
    pub settled: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct ChargeId {
    pub provider_name: std::string::String,
    pub authz_id: std::string::String,
}
```

For the `record_charge` operation we are relying on the chain itself to get the owner with `info.sender`. So we know someone with a valid wallet
signed the request. So there's no validations. We could assert if the amount is bigger than 0 for example or other assertions. But let's do it simple:

```rust
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
After instantiating a Transaction, we just save it and return a `Response` that will sent to tendermint. Attribute here is more like a form of log / event of our transaction. If you are curious to know what is this `TRANS`, then just check the git repo (link at the end of the article). Now the `settle`:

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
Here slightly more work. We check first if the charge was there (yes, the magical `?` up there) and if it is not settled yet. If this is the case we just update the flag to true and that's it.

Now, who is calling these methods? A good old pattern match on a cosmwasm entrypoint:

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

This works like a Dispatch. So remember that Comswasm is just a go module that calls a web assembly code you write in Rust. Even if you use a pure tendermint application with cosmos SDK, they use the same pattern as tendermint itself communicates with he blockchain application using a very small protocol you can find in [the specification](https://docs.tendermint.com/master/spec/). Forcing the comparison a bit, imagine it's a dispatch [servlet](https://stackoverflow.com/questions/2769467/what-is-dispatcher-servlet-in-spring).


If you follow the Git repo and the cosmwasm tutorial to build and deploy this contract you should be able to interact with it like this, if you deploy to [oysternet-1](https://github.com/CosmWasm/testnets/tree/master/oysternet-1):

```bash
# record a charge
wasmd tx wasm execute wasm1qxxlalvsdjd07p07y3rc5fu6ll8k4tmejq0 \
'{"record_charge": {"id": {"provider_name": "SCR", "authz_id" : "123"}, "amount": 25000}}' \
--from fred  --node http://rpc.oysternet.cosmwasm.com:80 \
--chain-id oysternet-1 --gas-prices 0.001usponge \
--gas auto --gas-adjustment 1.3 -y
# settle it
wasmd tx wasm execute wasm1qxxlalvsdjd07p07y3rc5fu6ll8k4tmejq0 \
'{"settle": {"id": {"provider_name": "SCR", "authz_id" : "123"}}}' --from fred  --node http://rpc.oysternet.cosmwasm.com:80 --chain-id oysternet-1 --gas-prices 0.001usponge --gas auto --gas-adjustment 1.3 -y
# query it 
wasmd query wasm contract-state smart wasm1qxxlalvsdjd07p07y3rc5fu6ll8k4tmejq \
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

This is ultra compressed for the sake of brevity and to point you out to more [complete patiently written tutorials](https://docs.terra.money/contracts/tutorial/implementation.html).

# Conclusion
Like mentioned at some point in the post, the code is available in my github: [transactions](https://github.com/paulosuzart/transactions). *Warning: I didn't fix the tests that comes with the template.*

It's important to remember that taking a hello world like this to a chain ran by yourself / company will take a lot more effort. You need to spin up all required [nodes](https://docs.tendermint.com/master/nodes/). Make sure they communicate across the data centers, establish backups, logging, monitoring and list goes. Besides of course some decent CI / CD for your contracts.

There are other open questions:

**1. How to make other multi data center applications interact with this block chain?**
Would a light client be enough, so each data center communicate with the smart contract via the local light client?

**2. How make sure events from the blockchain will be propagated to other systems?**
Her we fall into the typical problem of delivery guaranties. Polling vs subscribe. Diffs, offsets, and this seems to be a permanent unsolved problem even with Cosmos [IBC Relayer](https://docs.cosmos.network/master/ibc/relayer.html).

**3. How to make a back end application talk to the contracts?**
We see by default a lot of effort from blockchain niche to provide direct integration with Javascript, with a browser. What makes sense but this almost implies you are building a blockchain where every user will have a wallet. And that might not be the case. Still if that is your case you have plenty js libraries and [CosmosJs](https://github.com/cosmostation/cosmosjs) being a good one for cosmos ecosystem. 

**4. How slow will it be to have a blockchain in user facing applications?**
Of course, if the user is up to use a blockchain application like Uniswap, Aaave, Yearn and others, they are just happy with whatever latency they face. But when you plan to add a blockchain as a piece in your fleet of services, things may require a more profound analysis.

**5. How to do mass migrations of contract state?**
This always happens, you do a nice design, interview your stakeholders, define your ubiquitous language and after a couple of release here we are to do substantial changes to schemas. How to deal with this situation if part of your fleet of services is actually a blockchain?

And the list goes on. But so far I would say my interaction with blockchain was elucidating, and removed much of the hype. It also showed me how much concepts we already use at work and that it might really be a good direction to go especially in this world of Payments. Yet I believe the blockchain of 5 to 10 years will have few in common with what we see now especially for application development. Blockchain needs to be commoditized or popularized as much as cloud computing so it can become main stream of be present in a wider variety of industries. 

As blockchain enthusiasts, we must spend our energy to have impactful use cases that shows the power and relevance of it and stop chasing the next exponential growth that will bring you a *lembo*. In the end developers (or companies) will by Ether if they have a nice thing to build without having to stumble upon poorly written outdated tutorials (like my own tutorial above) and solutions that are not professional enough to enter the enterprise. At least I'm committed to take my parcel.