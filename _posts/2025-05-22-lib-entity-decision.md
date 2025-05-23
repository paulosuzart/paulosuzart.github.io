---
layout: post
title: "Exploring a Decision engine in Java"
date: 2025-05-23 13:21
comments: true
tags: [java]
---

Business logic are the value of our services, not the last fancy REST framework or the most language-native ORM. In this post I introduce [LibEntity-Decision](https://paulosuzart.github.io/lib-entity-doc/integrations/decision/) framework, a metamodel for business decisions inspired by [decision4j](https://github.com/decision4j/decision4j) that should help keeping create, maintain and understand complex business rules behind our entities.

<!-- more -->

# State machines and transition guards

It is very common to model state machines in our apps responsible for orchestrating business logic of aggregates. States can be tracked by simple mechanisms like [State Pattern](https://refactoring.guru/design-patterns/state/java/example), as well as complex state machines like [Stateless4j](https://github.com/stateless4j/stateless4j), or [kstatemachine](https://github.com/KStateMachine/kstatemachine).

For example, a transition guard from "Awaiting Payment" to "Paid" might have a guard: _"Payment amount received must equal the order total."_ This guard is a specific business rule that ensures the `"Paid"` state is only reached under a valid condition.

By default, people tend to encode these business rules as plain Java operations. For example:

```java
public boolean isPaymentAmountReceivedEqualOrderTotal(Order order) {
    return order.getPaymentAmountReceived().equals(order.getTotal());
}
```

Although legit and simple, this approach has a few downsides:


❌ Scattered logic: Rules get embedded across services, controllers, and utilities.

❌ Poor traceability: It’s hard to answer “Why did this payment transition fail?” or “What rule applied?”

❌ Limited diagnostics: No built-in insight into which rule matched or failed.

❌ Hard to test in isolation: Rules are often coupled to state and environment.

❌ High change risk: Modifying logic can introduce subtle regressions.

Ultimately, it is very common for engineers to operate large complex services without a clear picture of the business rules behind their entities. This means every change in the business logic requires a deep dive into the codebase, and it is not easy to reason about the impact of a change, or it is not easy to trace the origin of a business rule.

There is also the risk of changes in certain portions of the rules to overlap with other rules, leading to unexpected behavior and customer dissatisfaction.

What if we could encode these business rules in a way look like this:

✅ Centralized rules: Business rules are defined in one place using structured, testable constructs.

✅ Declarative API: Rules are expressed as data, not control flow, making them easier to read and change.

✅ Traceability: Rule matches are fully diagnosable allowing introspection into decision outcomes.

✅ Policied evaluation: Choose between several evaluation strategies like `First`, `Unique`, `Collect` or `Sum` for different business needs.

✅ Boilerplate free and type-safe.

✅ Composable matchers: Clean, reusable, and composable rule conditions like `isPresent()`, `in(...)`, `gt(...)`, etc.

# LibEntity-Decision

`LibEntity Decision` is part of `LibEntity` framework. A work in progress in the fields of metamodels for aggregates and business rules. From the doc:

> LibEntity is a powerful (and fun!) Java library for building type-safe, state-driven business entities with validation and action handling. It provides a clean, expressive DSL for defining entities, their states, fields, and actions. It's like Spring Boot for your business rules, but with more good vibes and less boilerplate!

Chek the full doc for LibEntity [here](https://paulosuzart.github.io/lib-entity-doc/).

The framework comes with a integrated, but independent sub-project called LibEntity-Decision. It is heavily inspired by [decisions4s](https://business4s.org/decisions4s/) _(although not a drop-in replacement or a port from Scala to Java)_.

## Show me the code.

Let's take a imaginary Payment Approval (it can be the payment of a invoice, of a order, etc). The decision requires the amount to be greater than zero, the approval date must be a tenure of 4 days, the number of approvals must be greater than 1, and the currency must be valid.

The output of the decision table, is a string "Allowed|Denied" indicating the approval and a percentage of a discount that can be applied. If more than one discount is applied, they must be summed.

A decision table in markdown would look like this:


|Amount | ApprovedSince | NumberOfApprovals | CurrencyIsValid | Approval (Out) | Discount (Out) |
| --- | --- | --- | --- | --- | --- |
| >= 80 | > 10 | >= 1 | true | "Allowed" | 2 |
| >=100 | >= 12 | >= 2 | true | "Allowed" | 10 |
| - | - | = 0 | true | "Denied" | 0 |

Pay attention to the two rules, both approve the payment, but with different discount. I won't waste time showing the java code to implement this decision table, because it will take too many lines.

Using LibEntity-Decision, we define a input class:

```java
@DecisionInput
@AllArgsConstructor
public class ApprovePaymentInput {
    Rule<BigDecimal> amount;
    Rule<Instant> approvedSince;
    Rule<Integer> numberOfApprovals;
    Rule<Boolean> currencyIsValid;
}
```

Classes annotated with `@DecisionInput` get's a value class and a `InputProvider` interface implementation.

Finally we define the rules:

```java
var rule1 = new ApprovePaymentInput(
        gte(BigDecimal.valueOf(80)),
        gt(Instant.now().minus(10, ChronoUnit.DAYS)),
        gte(1),
        is(true));
var rule1Output = new ApprovePaymentOutput("Allowed", 2);

// Using direct access to attribute intentionally for simplicity
var rule2 = new ApprovePaymentInput(
        gte(BigDecimal.valueOf(100)),
        gte(Instant.now().minus(12, ChronoUnit.DAYS)),
        gte(2),
        is(true));
var rule2Output = new ApprovePaymentOutput("Allowed", 10);

var rule2 = new ApprovePaymentInput(
        gte(any()),
        gte(any()),
        is(0),
        is(true));
var rule2Output = new ApprovePaymentOutput("Denied", 0);

var rules = List.of(
        MatchingRule.of(rule1, rule1Output, inputProvider),
        MatchingRule.of(rule2, rule2Output, inputProvider));
```

The attributes of `ApprovePaymentInput` are wrapped in `Rule` types that requires us to provide matchers.

- `Rule.any()`: Matches any value. Always true.
- `Rule.gt(T target)`: Matches if the value is greater than the given value.
- `Rule.gte(T target)`: Matches if the value is greater than or equal to the given value.
- `Rule.is(T target)`: Matches if the value is equal to the given value.

With the rules at hand, we can create a decision table.

```java
var inputValue =
        new ApprovePaymentInputValue(BigDecimal.valueOf(150), Instant.now().minus(5, ChronoUnit.DAYS), 5, true);
var decision = new DecisionTable<>("Discount amount", rules, inputProvider);
var out = decision.evaluateSum(inputValue,
        (o1, o2) -> new ApprovePaymentOutput(o1.approval(), o1.discount() + o2.discount()));
System.out.println(out.diagnose());
```

The decision table `evalue*` methods allow for the rules to be evaluted agains an inputValue, the type generated by the `@DecisionInput` annotation. The `inputProvider` type is also generated and used to avoid runtime reflection. It essentially gives to the engine the rules in a format that is easy to evaluate while opening the door for dynamic rules that can be stored in a database or configuration files.

Specific to this example, `evaluateSum` is a method that allows for the rules to be evaluated and the outputs to be summed. This is a simple way to implement a decision table that returns a single value.

## Dignosing the evaluation

The output to the `out.diagnose()` method is a string that shows the decision table evaluation result, the input values, and the rules that matched:

```
Hit Policy: Sum
Result: Optional[ApprovePaymentOutput(approval="Allowed", discount=12.0)]
Input:
  amount: 150
  approvedSince: 2025-05-12
  numberOfApprovals: 5
  currencyIsValid: true
Rule 0 [t]:
  amount            [t]: >= 80
  approvedSince     [t]: > 10
  numberOfApprovals [t]: >= 1
  currencyIsValid   [t]: true
  == ApprovePaymentOutput(approval="Allowed", discount=2)
Rule 1 [t]:
  amount            [t]: >= 100
  approvedSince     [t]: > 12
  numberOfApprovals [t]: >= 2
  currencyIsValid   [t]: true
  == ApprovePaymentOutput(approval="Allowed", discount=10)
Rule 2 [f]:
  amount            [t]: -
  approvedSince     [t]: -
  numberOfApprovals [t]: -
  currencyIsValid   [t]: true
  == x
```

The diagnosis is a important tool to help visualize the decision table evaluation process as well as assist the debugging process.

This output (or a soon available json format) can be used to store rule evaluation history, which can be useful for audit and explaning users how certain decisions were made. The capability of self introspection is of great value when it comes to complex products that users may not be able to understand the business rules behind.

Other Hit Policies are available:

- `First`: Returns the first matching rule output.
- `Unique`: Returns the unique matching rule output.
- `Collect`: Returns a list of matching rule outputs.

## How to mix and match rules?

Behind the scens, LibEntity-Decision is backed by plain Java [Predicates](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/function/Predicate.html). Composing them is very easy:

```java
@Test
void testAndMatching() {
    var insideRange = Rule.gt(0).and(Rule.lt(100));
    assertTrue(insideRange.eval(50));
    assertFalse(insideRange.eval(200));
    assertEquals("> 0 and < 100", insideRange.getMatcher().toString());
    assertTrue(insideRange.or(Rule.gt(70)).eval(50));
}
```

# Future explorations

At the moment evaluation happens eagerly and Policies are used as a way to extract the results. Future explorations may include a lazy evaluation approach, moving the evaluation.

Another crucial aspect is the rendering of the decision table in several formats, starting with Markdown.

# Conclusion

The express "let engineers concentrate in the business rules while we take care of the infrasrtructure" is a common theme in the software industry. LibEntity-Decision is a step towards this goal, providing a declarative API for defining business rules and a decision engine that can be used to evaluate them.

The rules of complex SaaS products in finance can be tough. A flawless set of rules are a must to avert loses and risks to the company and its users.

Finally, if you put in place a structure that is easy to reason and easy to iterate, you gain speed and agility while you evolve your product.
