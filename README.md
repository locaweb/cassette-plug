# Getting started

A Plug to authenticate and authorize users based on Cassette

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add cassette_plug to your list of dependencies in `mix.exs`:

        def deps do
          [{:cassette_plug, "~> 0.0.1"}]
        end

  2. Ensure cassette is started before your application:

        def application do
          [applications: [:cassette]]
        end

## Usage

Please check the module docs on `Cassette.Plug` and `Cassette.Controller` for usage
