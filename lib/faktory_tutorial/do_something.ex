defmodule FaktoryTutorial.DoSomething do
  use Faktory.Job

  def perform(greeting, name) do
    IO.puts("#{greeting}, #{name}!!")
  end

end
