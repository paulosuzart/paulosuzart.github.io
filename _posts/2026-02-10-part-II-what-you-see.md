---
layout: post
title: "Vibe Parte II - What you see"
date: 2026-02-10 10:21
comments: true
tags: [ai, vibe-coding]
---

In the previous post, a [vibe manifesto]({% link _posts/2026-02-05-part-I-the-vibe-manifesto.md %}) was presented. It was blunt, no bigger context, no warning. Just a series of wishes, a series of considerations I wish people would consider when using AI to build software.

This post is a follow up on that, but with a different focus. It's not about what we should do, but about what we see when vibing. More on the downside of it.

<!-- more -->

# What you see

The sections below depict whta we can consider as patterns (or are they anti-patterns) when using AI to build software. There's a lot of behavioural observations, more than technical ones.


## The Oracle Relationship

**Where it shows up:** Meetings, Slack, decision-making moments.

**The scene:** A non-engineer hears a technical explanation from the team. Later, they check with ChatGPT. In the next meeting: "GPT also says the same." The engineer's input wasn't trusted until the oracle confirmed it.

**The dynamic:** Human knowledge requires external AI validation to be trusted.

## The Authority Escape Hatch

**Where it shows up:** Technical debates, architecture discussions, code reviews

**The scene:** An engineer is challenged on a decision. Instead of defending the reasoning, they deflect: "But this is what the LLM says." Conversation over. The AI's output is treated as the final word.

**The dynamic:** AI as unchallengeable authority, used to bypass difficult discussions.

## The Evaporating Domain Model

**Where it shows up:** Codebase, documentation (or lack of it), onboarding

**The scene:** After weeks of vibing, someone asks: "Wait, what's the difference between a Project and a Workspace in our system?" Silence. Nobody knows. The concepts were never defined. Everything was looking fine because the endpoints returned the right JSON to be displayed on the screen.

**The dynamic:** The illusion that AI will "figure it out" replaces the hard work of modeling reality.

## The Demo-to-Production Fallacy

**Where it shows up:** Planning meetings, estimation sessions, roadmap discussions

**The scene:** A PM built a sample app with ChatGPT over a weekend. Now they're in sprint planning, visibly frustrated: "Why does this take two weeks? I basically built the same thing in a few hours."

**The dynamic:** 
- Engineers feel pressured to ship fast, go all-in on vibing 
- High speed, low quality, and critically—low extensibility
- New features that should take hours take days
- Business is shocked: "But the first version was so fast!"

## The Accountability Inversion

**Where it shows up:** Retros, post-mortems, stakeholder escalations

**The scene:** The product is buggy. Iterations are slow. Leadership wants answers. The engineers are blamed, but the business never specified what they wanted, and pushed for speed. Now they are asking the questions, not answering them. They are asking "why is this not done yet?" when they never defined what "this" is in concrete terms.

**The dynamic:** Those who created the ambiguity judge those who implemented it.

# Conclusion

These patterns are not exclusive to AI-assisted development, but they are amplified by it. The speed of AI can make these patterns more dangerous, as they can spread more quickly and have a greater impact. It's crucial to be aware of these patterns and to actively work against them. Otherwise, we risk building software that is not only slow and buggy, but also impossible to maintain or extend.


*This series of posts express my sole opinion and not the opinion of any employer.*