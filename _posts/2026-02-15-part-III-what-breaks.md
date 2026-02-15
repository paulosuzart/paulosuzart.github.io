---
layout: post
title: "Vibe Part III - What breaks"
date: 2026-02-15 13:21
comments: true
tags: [ai, vibe-coding]
---

This is the third and final post of the Vibe code series. In the first post [we discussed a vibe manifesto]({% link _posts/2026-02-05-part-I-the-vibe-manifesto.md %}), and in the second post [we discussed what we see when vibing]({% link _posts/2026-02-10-part-II-what-you-see.md %}). This post is about what breaks when we go all-in on vibe coding.

<!-- more -->

# What breaks

The past post showed the manifestations of vibe coding at the collaboration level. Or at lest what can be exacerbated by it. This post is about what breaks when we go all-in on vibe coding. In other words, which foundations are realling breaking when we see these manifestations?

## The Erosion of Human Judgment

**Connects to**: [The Oracle Relationship]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-oracle-relationship), [The Authority Escape Hatch]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-authority-escape-hatch)

Human expertise—earned through years of context, mistakes, and domain immersion—gets downgraded to "just one opinion" that needs validation from a tool with no context.

It doesn't look like distrust. It looks like due diligence. But the implicit message accumulates: your judgment alone isn't sufficient.

**Long-term damage:** People stop developing judgment. Why build deep intuition if every call gets reviewed by the oracle? The skills of weighing tradeoffs, reading a codebase, sensing when something is off—they atrophy when they're never the final word.

## The Diffusion of Responsibility
**Connects to:** [The Authority Escape Hatch]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-authority-escape-hatch), [The Accountability Inversion]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-accountability-inversion)

Decisions get made, but ownership dissolves. When things go wrong, there's always somewhere else to point: "GPT suggested it," "the requirements were unclear," "we were told to move fast."

AI creates a new actor in the room that everyone can defer to but no one controls. It's not a team member you can hold accountable. It's a ghost in every decision that conveniently absorbs blame.

**Long-term damage:** Teams lose the muscle of standing behind their choices. Technical leadership erodes because leading means taking positions—and positions are risky when you can just "see what the AI says."

## The Loss of Shared Understanding
**Connects to:** [The Evaporating Domain Model]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-evaporating-domain-model), [The Accountability Inversion]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-accountability-inversion)

In healthy teams, there's a shared mental model: what are we building, what are the core concepts, how do they relate.

Vibing bypasses the conversations that create this. You end up with working software that nobody fully understands.
Building shared understanding is slow. It requires naming things, debating boundaries, writing things down, disagreeing and resolving. AI lets you skip to "it works," and the pressure to ship makes that skip feel like progress.

**Long-term damage:** Every future conversation is harder. Debugging becomes archaeology. Onboarding becomes impossible. The system becomes a black box maintained by people who are also guessing.

## Calibration Collapse

**Connects to:** [The Demo-to-Production Fallacy]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-demo-to-production-fallacy), [The Evaporating Domain Model]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-evaporating-domain-model)

People lose the ability to estimate how hard things are. Non-engineers see AI demos and assume production is similar. 

Engineers vibe through problems and lose the feel for what "doing it properly" would take.

When you vibe and it works (short-term), you update your intuition: "this is how long things take." When it breaks later, the delay is attributed to other causes. The original miscalibration never gets corrected.

**Long-term damage:** Planning becomes fiction. Roadmaps are fantasies. Teams are perpetually "behind" against expectations that were never grounded in reality.

## Short-Term Velocity as a Trap

**Connects to:** [The Demo-to-Production Fallacy]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-demo-to-production-fallacy), [The Evaporating Domain Model]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-evaporating-domain-model), [The Accountability Inversion]({% link _posts/2026-02-10-part-II-what-you-see.md %}#the-accountability-inversion)

Vibing is genuinely fast for getting something working. That speed becomes the baseline expectation. When velocity drops (because you're now fighting the mess), it reads as failure—not as the inevitable cost of the early approach.

Results are hard to argue with. When an MVP is "vibed" into existence in forty-eight hours, advocating for architectural rigor feels like obstructionism. The trap is that the cost is invisible: you can see the initial sprint, but you can't see the velocity you’re forfeiting later by skipping the foundation.

**Long-term damage:** The team gets locked into a mode where speed is the only legible metric. Quality and extensibility are invisible until they're catastrophically absent.


# Conclusion

This is a critique of the current relation among humans, and how they they play together with a LLM in the room. It's not a critique of AI itself, but of how we are using it. It's a call to be more intentional about how we use AI, and to be more aware of the potential consequences of our actions/expectations shaped by the hype.

A lot is being said about [Spec-Driven-Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) for AI. But without the [Vibe Manifesto]({% link _posts/2026-02-05-part-I-the-vibe-manifesto.md %}), the failure is around the corner, just with more steps before you hit the wall.

Most of the content relates to softeware development itself and some of them may have been discussed before when Agile came to be. Or when DevOps came to be. Or when Or when XP came to be. Or when TDD came to be. At the end of the day, building sotwares is complex, laborious, and this content basically shows that AI / Vibe is not fixing it, as long as we have humans in the loop.

At the moment, I strongly believe the good old software engineering practices are the best remedy for all of this. But I'm open to be convinced otherwise. I'll be writing more about this in the future.

*This series of posts express my sole opinion and not the opinion of any employer.*