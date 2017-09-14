# Getting started

A Plug to authenticate and authorize users based on Cassette

![Build status](https://travis-ci.org/locaweb/cassette-plug.svg?branch=master)

## Installation

The package can be installed as:

  1. Add cassette_plug to your list of dependencies in `mix.exs`:

        def deps do
          [{:cassette_plug, "~> 1.0"}]
        end

  2. Ensure cassette-plug is started before your application:

        def application do
          [applications: [:cassette_plug]]
        end

## Usage

Please check the module docs on `Cassette.Plug` and `Cassette.Controller` for usage
