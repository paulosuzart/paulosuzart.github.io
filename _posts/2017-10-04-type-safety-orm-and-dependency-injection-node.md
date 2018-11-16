---
layout: post
title: "Type Safety, ORM and Dependency Injection with node.js"
date: 2017-10-04 22:35
comments: true
categories: [graphql, node.js, typescript, orm]
---

This time I'll share direct knowledge from day to day job with [node.js](nodejs.org) and [TypeScript](https://www.typescriptlang.org).


You probably know I come from Java world. Did JVM stuff from 2004 to 2016 without a break. So you might think I miss the static type check, etc, right? And yes, wouldn't say missing is the right word, but I think it brings a lot of advantages! <!--more-->

# Intro 

Although extremely slow JVM startup time, poor ecosystem and crazy build tools, Java (and here I extend to Kotlin and Scala) provide good type systems with support for OO and FP styles. This may be seen as a slow down to productivity at first, but as you repeatedly work with dynamic langs like Python and ES6, the productivity you have for not carrying about types can escalate and become a burden if you have bit less documentation and bit less testing.

Working at datacloud.ai (a now extinct project), a product entirely written in Node.js, allowed us to try pure ES6, ES6 + [Facebook's Flow](https://flow.org/) and lately, our main API with [TypeScript](https://www.typescriptlang.org). Lets how it went for us.

# ORM

All projects involved require ORM for one or other reason. We have one project using [Bookshelf](bookshelfjs.org) and I have to confess this is pretty neat piece of software. It is unlikely that for this specific service we replace Bookshelf for anything else due to the dynamic nature of the service. It plays nicely with Flow with one not interfering with the other.

But this is a singular case where the server queries a arbitrary database with models, relations and everything else defined at runtime. For a more traditional API, we had the chance to use types everywhere.

For this case we used [TypeORM](http://typeorm.io/) and considering a lib in its early `0.1.0-alpha5.0`, I have seen few projects with such maturity and excellence in the Node world.

It resembles ~~Hibernate~~, but simpler and with a powerful [`QueryBuilder`](http://typeorm.io/#/select-query-builder) API that don't get on your way. Take the simple entity definition below as example.


``` typescript
@Entity()
export class Organization extends BaseEntity {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  jwtSecret: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(type => User, owner => owner.owns, { eager: true })
  @JoinColumn({ name: "ownerId" })
  owner: User;

  @AfterInsert()
  addJwtSecret() {
    this.jwtSecret = 'some-random-secret';
  }
}


// sample use
const org = const Organization.findOneById(3);
```

Check that by extending `BaseEntity` you can use Active Record like static methods, making it easy to use and manipulate data. Also pay attention to `@AfterInsert()` [decorator](https://www.typescriptlang.org/docs/handbook/decorators.html) that allows for modifying the entity itself before it is flushed to the database. More listeners available.

TypeORM also makes it easy to add common columns like the date of creation of a record and the date of last update by leveraging `@UpdateDateColumn()` and `@CreateDateColumn()`.

# Migrations

Another super key point here is the ability to generate migrations. There are couple options out there like [Sequelize](http://docs.sequelizejs.com/) and [Loopback](https://loopback.io/) provide some good tools, but none of them compares to [Django](https://docs.djangoproject.com/en/1.11/topics/migrations/)'s migration capability, for example. This is not the case for TypeORM that is able to generate precise migrations.

By using `ts-node node_modules/.bin/typeorm migrations:generate -n Bootstrap`, TypeORM will generate a migration like this:

``` typescript
export class Bootstrap1507151187498 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<any> {
        await queryRunner.query("CREATE TABLE `organization` (`id` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT, `name` varchar(255) NOT NULL, `jwtSecret` varchar(255) NOT NULL, `createdAt` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), `updatedAt` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), `ownerId` int(11)) ENGINE=InnoDB");
    }
    // ... down function continues from here
```

It looks awesome to me. You can customize the generated migration, as long as you keep `up` and `down`  compatible, or you can create a empty migration where you specify everything by hand.

Migrations are important piece of productivity and safety IMO and TypeORM takes a 10 grade here.

# DI (Dependency Injection)

What is a a life of a life long Java developer without dependency injection? :D Of course this is a joke, it is not something required, but helps keep things well tidy.

Take for example GraphQL resolvers. What people do is usually passing a bloated context full of whatever might be needed in a given depth of a query. This works actually, but you can use [TypeDI](https://github.com/pleerock/typedi) and use its container to manage and use Services, Factories, and also most TypeORM related objects.

Taking our sample entity, we could have a service written like this:

``` typescript
@Service()
export class OrganizationService {
  private repository: Repository<Organization>;

  constructor(@OrmRepository(Organization) repository: Repository<Organization>) {
    this.repository = repository;
  }

  byId(id: number): Promise<Organization> {
    return this.repository.createQueryBuilder("organization")
      .where("id=:id")
      .setParameters({ id: id })
      .getOne();
  }

}
```
And in your GraphQL resolver, you could get a instance of this Service like this:

``` typescript
import { Container } from "typedi";

const resolvers = {
  addMember(root: any, { input }: { input: AddMemberInputType } , context: any, info: any): any {
    const organizationService = Container.get(OrganizationService);
    // ... do your logic here
  }
}
```

Of course by using Organization as a `BaseEntity` such service is not needed, but take is as illustration.

In this case the `Container` is being accessed directly, but if you had this `addMember` as a member of a class you could inject the `OrganizationService` and much more.

TypeDI support factories, so you can take full control on how / when / etc services are instantiated. Being somehow optimistic, TypeORM is the [Google Guice](https://github.com/google/guice) of TypeScript.

By adding [typeorm-typedi-extensions](https://github.com/typeorm/typeorm-typedi-extensions), it is possible to use `@OrmRepository` and other decorators to help you grab the instances at will.

# TypeScript

This language reminds me C# a lot. Not that I'm any specialist on C#, but from my researches, it is a close cousin.

You might be wondering, *if you are using node.js with a strong typed language, why don't you continue your life with Java or Kotlin or Scala?*. Well, I wouldn't say TypeScript is strong typed, it is just typed a la cart. You could replace everything with a `any` and it would still be more practical than using `java.lang.Object`. Of course you don't want to do that and waste your type support, right?

This is the good thing, you can step down and use javascript maps or any other "typeless" structure at any time without ceremony. You can also sort of cast a object to a rich TypeScript type. I think TypeScript is the middle ground giving you full control, safety and protecting your team from discovering that bug in production only.

It also offers cool [Advanced Type](https://www.typescriptlang.org/docs/handbook/advanced-types.html) features like Intersection Types, Union Types, Nullable Types, String Literal Types and Discriminated Unions. These features make this language really powerful and expressive even looking like Java or C#.

What else do I get? I would summarize other important points like:

   - No `require`, just `import`
   - Forward export. So you can re-export in a `index.ts` the local exports of other modules
   - Turn off types at will. You may produce types that are hard to predict its shape, or it doesn't worth the effort, just use `any`
   - Better IDE / Editor support
   - Documentation that works. We've struggled to get decent code documentation generation for ES6 and Flow. But using [Typedoc](http://typedoc.org/) it simply works
   - [VSCode](https://code.visualstudio.com/) like a glove

Conclusion
===

**Warning!** the product that I mentioned in this post is, by the time of writing, in closed beta and its home page and documentation are preliminary.

I like Facebook's Flow and for some scenarios, will be forced to continue using it. But for many others, TypeScripts is the best option IMO. As your team grows, your code base grows and as you release more to production, having support from types without compromising productivity is simply awesome.

People that started their careers in the node.js world may dislike this position, but I can assure these conclusions come with relevant background, blood and sweat.

Happy TypeScript!
