# FaktoryTutorial

I created this repo using `mix new . --app faktory_tutorial`.

Purpose of this repo is to dcoument and record my understanding how to use elixir and faktory.

However, in order to understand it in the context of my job:

I am using the faktory version that my work uses, so my `docker-compose.yml` setup includes:

```yml
services:
  faktory:
    image: contribsys/faktory:0.8.0
    ports:
      - "7419:7419"
      - "7420:7420"
```

I am using their current `faktory_worker_es` version:

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

Note here, that this is not a Phoenix application. This is a straightforward mix project.
From the quickstart docs in the `faktory_worker_ex` readme, we can just do the following:

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

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `faktory_tutorial` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:faktory_tutorial, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/faktory_tutorial](https://hexdocs.pm/faktory_tutorial).
