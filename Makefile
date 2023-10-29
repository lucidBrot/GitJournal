# SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

DIR := ${CURDIR}
export PATH := $(DIR)/.flutter/bin/:$(PATH)


protos:
	protoc --dart_out=grpc:lib/analytics/generated -Ilib/analytics/ lib/analytics/analytics.proto
	protoc --dart_out=grpc:lib/markdown/generated -Ilib/markdown/ lib/markdown/markdown.proto
	protoc --dart_out=grpc:lib/generated -Iprotos protos/shared_preferences.proto
	protoc --dart_out=grpc:lib/generated -Iprotos protos/builders.proto
	protoc --dart_out=grpc:lib/generated -Iprotos protos/core.proto
	rm lib/analytics/generated/analytics.pbgrpc.dart
	flutter format lib/

	reuse addheader --license 'AGPL-3.0-or-later' --copyright 'Vishesh Handa <me@vhanda.in>' --year '2021' lib/analytics/generated/*
	reuse addheader --license 'AGPL-3.0-or-later' --copyright 'Vishesh Handa <me@vhanda.in>' --year '2021' lib/markdown/generated/*
	reuse addheader --license 'AGPL-3.0-or-later' --copyright 'Vishesh Handa <me@vhanda.in>' --year '2021' lib/generated/*

	git checkout lib/generated/locale_keys.g.dart

unused:
	flutter pub run dart_code_metrics:metrics check-unused-files lib
	flutter pub run dart_code_metrics:metrics check-unused-code lib

lint:
	flutter analyze
	flutter pub run dart_code_metrics:metrics lib

build_env:
	flutter scripts/setup_env.dart gen

build_runner:
	flutter packages pub run build_runner build --delete-conflicting-outputs

test:
	flutter test

version:
	./scripts/version.sh

bump_dart_git:
	flutter packages upgrade dart_git

# https://stackoverflow.com/a/26339924/147435
.PHONY: list test protos
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
help: list
