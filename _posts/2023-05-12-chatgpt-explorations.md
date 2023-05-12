---
layout: post
title: "ChatGPT Explorations"
date: 2023-05-12 13:00
comments: true
tags: [ai, chatgpt]
---

[ChatGPT](https://chat-gpt.org/) has spread the world like fire. The current generation of AI tools took the spotlight, overshadowing BitCoin, Blockchain, and the like. It was my turn now to surrender and give it a try finally.

In this post, I will share how I built a very simple trivia game using ChatGPT in Pythyon and deployed to [Streamlit](https://streamlit.io/).

<!--more-->

I haven't been active in writing. Every day there are more and more content available in this area. I feel a bit like The Tech Lead when he says he [quits coding](https://www.youtube.com/watch?v=ab6xJ4E23VQ) and that nerds are not cool anymore. But I may quit coding not because I'm leaving the computer screen but because some AI assistant will do it for me end-to-end.

ChatGPT is one of the enablers. I don't find what it does to be particularly intelligent, but what people did to build it, is absolutely clever. It can't produce anything intelligent at all, but then what in the world needs little intelligence? Automation. Of all kinds.

Writing tedious repository code to access databases and boring SQL queries to extract reports can be fully automated. These are tasks that will make you no better engineer or person. It's just the same repetitive tantrum. And this is where we must have AI help as soon as possible without fear of being replaced, but rather excited to be more productive.

We still will need to review the quality of whatever is generated. As there's no real intelligence whatsoever, we will position ourselves more and more to be supervisors of these machines harder than the workers. 

Doing software today became so much complex. Product Managers, Designers, Frontends, Product Marketing, Analytics, Backenders, Mobile, Platform/SRE, Engineering Experience, etc. This setup adds a lot of overhead especially in communication and collaboration. And this is also where I see AI tools helping removing the clutter.

# To the weeds

Enough talking. Let's see what we have for today! 

I found [LangChain](https://python.langchain.com/en/latest/). It is basically a framework that lets you overcome do a bunch of things in a standardized way across many different LLMs. It also helps with two immediate challenges of interacting with a chat/text based AI:

1. How to read back the produced content in a structured way so an application can take advantage of the responses to take some action?
1. How to efficiently give context to the chat so it can answer things about data you have, not only data it was trained on?

LangChain helps with this and much more. In this simple game, Lang Chain will be help us with the point 1 above. It does it by letting you define a [pydantic](https://docs.pydantic.dev/latest/) object like this and giving you a parser to use on the responses from the chat:

```python
class Question(BaseModel):
    question: str = Field(description='The question of the trivia')
    answer: str = Field(description='The correct answer')
    ops: list[str] = Field(description='Options')
    link: str = Field(description='A link to a content related to the answer')

parser = PydanticOutputParser(pydantic_object=Question)
retry_parser = RetryWithErrorOutputParser.from_llm(parser=parser, llm=llm)
```
We are basically preparing to read any response and extract into this shape. This is the concept of so-called Output Parsing and there are [several different options](https://python.langchain.com/en/latest/modules/prompts/output_parsers.html) you can use. 

With the LLM instance and the prompt at hand we can then get the trivia content for our game:

```python
prompt = PromptTemplate(
    input_variables=["subject"],
    template="""
    Prepare a trivia game. {format_instructions}.
    Prepare a trivia about the Subject: {subject}.
    Bring only 1 questions. 
    Give three alternatives to each question where one is the correct. Keep answers as short as possible.
    No sexual or minor than 18 years subjects must be brought up. Questions in english only.
""",
    partial_variables={"format_instructions": parser.get_format_instructions()}
)

q = prompt.format_prompt(subject=subject)
q2 = prompt.format(subject=_subject)
result = llm(q2)
return retry_parser.parse_with_prompt(result, q)
```

That is it. The call to `llm` is an abstracted call to any underlying llm. LangChain allows us to plug several LLMs. You are not required to use [OpenAI](https://openai.com/). 

One of the problems is that ChatGPT sometimes does not return the full response for whatever reason. And LangChain tries to fetch everything with [RetryOutputParser](https://python.langchain.com/en/latest/modules/prompts/output_parsers/examples/retry.html), which was not working very well. But in general, the game can run without problems.

Another nice abstraction LangChain gives us is the `PromptTemplate`. It is responsible for getting your instructions, merging them with any new input, and informing ChatGPT about the format you want for that output (see `{format_instructions}`).

You can find the complete code [repository](https://github.com/paulosuzart/triviagpt), and running it is straightforward. Just clone it and run it on https://streamlit.io/. I can't leave the application public as it uses my real OpenAI API keys.

The app looks more or less lie this:
<blockquote class="imgur-embed-pub" lang="en" data-id="a/RNRryV2" data-context="false" ><a href="//imgur.com/a/RNRryV2"></a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>

I don't want to spend much time on Streamlit, but this thing is so practical! You write your UI components using Python directly with your app logic, and this thing just works. It is flat, no layers, no b*ll sh*t. Just render your stuff and does the job (As most development platforms were supposed to be).

To build this nice UI, all I did was get the question back from ChatGPT and display it with the components:

```python
st.write('Here we go')
st.write(st.session_state.q.question)
options = ['-'] + st.session_state.q.ops
option = st.selectbox('Pick one', options)

if option == '-':
    st.stop()
if option == st.session_state.q.answer:
    st.success('Bingo!')
    st.snow()
else:
    st.error('Ooops, not this time')
```

Just plain and simple. There are other steps of the game that a call to GPT could be used, like letting user reply with a text and the verying if the question is correct, avoid duplicate questions, making some form of scoring. But you got the drill.

# Conclusion
The sky is the limit. What else can you automate with ChatGPT or other LLM to decide how to accomplish specific tasks?

This post was written with the help of AI. I have been using Grammarly for a long time. Did I get lazy? Perhaps, but the produced content is much more fluid to read. It feels now that there's no way of scaping the new productivity mode. The better you master these tools, the more productive you can be.

There are other deep concerns about the quality of the training data, the bias, the protection of your data when you use these kinds of tools, etc. Which data leaks will come? How many fraudulent "AI Tools" will be introduced? How will these tools be used to cause harm and control people's opinions and the information they consume? 

There's a long way ahead, and unlike Blockchain, which touched the bottom and didn't recover, AI tools are here to stay.

