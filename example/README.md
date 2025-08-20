# OpenFGA Ruby SDK Examples

This directory contains examples demonstrating how to use the OpenFGA Ruby SDK.

## Prerequisites

- Ruby 3.2+
- OpenFGA server running

## Installation

Add to your Gemfile:
```ruby
gem 'openfga'
```

Then run:
```bash
bundle install
```

## Running OpenFGA

Start OpenFGA server:
```bash
make start-openfga
```

## Examples

### Example 1: Basic Usage

Located in `example1/example1.rb`

This example demonstrates:
- Store management
- Authorization models
- Relationship tuples
- Authorization checks
- Batch checks with concurrency

Run the example:
```bash
make run-example1
```

## Configuration

Set the OpenFGA server URL (default: `http://localhost:8080`):
```bash
export OPENFGA_API_URL=https://your-openfga-server.com
```
