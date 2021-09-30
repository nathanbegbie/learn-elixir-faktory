# FaktoryTutorial

## Progress

I created this repo using `mix new . --app faktory_tutorial`.

Purpose of this repo is to dcoument and record my understanding how to use elixir and faktory.

However, in order to understand it in the context of my job:

1. I am using the faktory version that my work uses, so my `docker-compose.yml` setup includes:

```yml
services:
  faktory:
    image: contribsys/faktory:0.8.0
    ports:
      - "7419:7419"
      - "7420:7420"
```

2. I am using their current `faktory_worker_es` version:

```elixir
...
  {:faktory_worker_ex, "~> 0.7.0",
  runtime: Mix.env() != :test,
  github: "smn/faktory_worker_ex",
  branch: "feature/combined-fixes"},
...
```

There are two Elixir packages for Faktory - [`faktory_worker`](https://github.com/seated/faktory_worker) and [`faktory_worker_ex`](https://github.com/cjbottaro/faktory_worker_ex).
The former seems to be the more popular version, while we used a forked version of the latter.
There are historical and technical reasons for this, which I won't get in to here.

## Getting Faktory Integrated with the Mix App

Note that this is not a Phoenix application. This is a straightforward mix project.
From the [quickstart docs](https://github.com/smn/faktory_worker_ex/tree/feature/combined-fixes#quickstart) in the `faktory_worker_ex` README, we will adapt the following:

```elixir
# For enqueuing jobs
defmodule MyFaktoryClient do
  use Faktory.Client, otp_app: :my_cool_app
end

# For processing jobs
defmodule MyFaktoryWorker do
  use Faktory.Worker, otp_app: :my_cool_app
end

# You must add them to your app's supervision tree
defmodule MyCoolApp.Application do
  use Application

  def start(_type, _args) do
    children = [MyFaktoryClient, MyFaktoryWorker]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule MyGreeterJob do
  use Faktory.Job

  def perform(greeting, name) do
    IO.puts("#{greeting}, #{name}!!")
  end
end

# List argument must match the arity of MyGreeterJob.perform
MyGreeterJob.perform_async(["Hello", "Genevieve"])
```

let's add a `docker-compose.yml` file with faktory and try this out.

I've just realised that I need to have a supervisor tree. To include this in the project,
I should have included the `--sup` command. Luckily, the elixir folks had thought
of this, so rerunning `mix new . --app faktory_tutorial --sup` just checked each time
it was going to overwrite a file. Nifty.

Right! So now we have an `application.ex` file as well.

## Running Faktory

I've added the `docker-compose.yml` file. To check that it is working
I have gone to [`http://localhost:7420/`](http://localhost:7420/) to
get the Faktory dashboard and confirm that it is working.

## Adding Some Glue Code

We need to stick some things together. If you see in the instructions above,
you need to declare a Worker and a Client. When I looked at how we'd done this
with work, this is basically a renaming exercise, where we create our own
modules, and then just pass two arguments to a macro.

```diff
diff --git a/lib/faktory_tutorial/faktory_client.ex b/lib/faktory_tutorial/faktory_client.ex
new file mode 100644
index 0000000..1067b99
--- /dev/null
+++ b/lib/faktory_tutorial/faktory_client.ex
@@ -0,0 +1,4 @@
+defmodule FaktoryTutorial.FaktoryClient do
+  @moduledoc false
+  use Faktory.Client, otp_app: :faktory_tutorial
+end
```

```diff
diff --git a/lib/faktory_tutorial/faktory_worker.ex b/lib/faktory_tutorial/faktory_worker.ex
new file mode 100644
index 0000000..2a1d9a9
--- /dev/null
+++ b/lib/faktory_tutorial/faktory_worker.ex
@@ -0,0 +1,4 @@
+defmodule FaktoryTutorial.FaktoryWorker do
+  @moduledoc false
+  use Faktory.Worker, otp_app: :faktory_tutorial
+end
```

So not exactly rocket science at this point. Then we add these
modules to the Supervisor tree, so that these processes are started
when we run `iex -S mix`.

```diff
diff --git a/lib/faktory_tutorial/application.ex b/lib/faktory_tutorial/application.ex
index ae5798f..03d328e 100644
--- a/lib/faktory_tutorial/application.ex
+++ b/lib/faktory_tutorial/application.ex
@@ -10,6 +10,8 @@ defmodule FaktoryTutorial.Application do
     children = [
       # Starts a worker by calling: FaktoryTutorial.Worker.start_link(arg)
       # {FaktoryTutorial.Worker, arg}
+      FaktoryTutorial.FaktoryClient,
+      FaktoryTutorial.FaktoryWorker,
     ]

     # See https://hexdocs.pm/elixir/Supervisor.html
```

Okay, so let's add the final bit of the puzzle, which is a module that actually does something. We'll keep it simple at first, with a `IO.puts`
like the site suggests, but then we can get a bit fancier.

## Current State

Do the following:

1. `git clone git@github.com:nathanbegbie/learn-elixir-faktory.git`
1. `docker-compose up -d`, you should be able to visit Faktory on [`http://localhost:7420/`](http://localhost:7420/)
1. `mix deps.get`
1. `iex -S mix`
1. `FaktoryTutorial.DoSomething.perform_async(["Hello", "Genevieve"])`
1. Then open another terminal and run `mix faktory`

At this point, I get the following error:

```elixir
16:44:40.930 [error] Process #PID<0.261.0> raised an exception
** (Faktory.Error.InvalidJobType) FaktoryTutorial.DoSomething
    (faktory_worker_ex 0.7.0) lib/faktory/runner.ex:42: anonymous fn/2 in Faktory.Runner.handle_events/3
```

[This is where the exception is thrown](https://github.com/smn/faktory_worker_ex/blob/feature/combined-fixes/lib/faktory/runner.ex#L39-L45).

I'm not sure why this is at present.
