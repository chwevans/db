# Db

Db is a data access layer implementation in Elixir.

It defines 2 protocols:
* Db.Backend: This defines how to handle queries returned by implementors of the Db behaviour.
* Db.Router: This defines how to find a module implementing the Db behaviour.

And a behaviour:
* Db: Implementors of this behaviour return a struct that implements Db.Backend in their implementation of handle/2.

An example backend can be found in https://github.com/chwevans/db_dets.
An end to end example of usage can be found in test/
* Backend defined in test/test_helper.ex
* Db behaviour implementor and Db.Router implementor found in test/db_test.ex

# Testing
MIX_ENV=test coveralls

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add db to your list of dependencies in `mix.exs`:

        def deps do
          [{:db, "~> 0.0.1"}]
        end

  2. Ensure db is started before your application:

        def application do
          [applications: [:db]]
        end

