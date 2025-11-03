#!make

include .env.dev

SHELL := /bin/bash
.PHONY: test

install:
	mix deps.get

test:
	MIX_ENV=test mix test

iex:
	iex -S mix phx.server