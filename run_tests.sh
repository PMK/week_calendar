#!/bin/bash

echo "Running Week Calendar Test Suite..."
echo ""

echo "1. Running unit tests..."
flutter test test/models
flutter test test/providers
flutter test test/utils

echo ""
echo "2. Running widget tests..."
flutter test test/widgets

echo ""
echo "3. Running integration tests..."
flutter test integration_test

echo ""
echo "4. Generating coverage report..."
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

echo ""
echo "Tests completed! Coverage report available at coverage/html/index.html"
