defmodule GaDocsTest do
  use ExUnit.Case
  doctest GaDocs

  test "greets the world" do
    assert GaDocs.hello() == :world
  end
end
