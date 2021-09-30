defmodule FaktoryTutorialTest do
  use ExUnit.Case
  doctest FaktoryTutorial

  test "greets the world" do
    assert FaktoryTutorial.hello() == :world
  end
end
