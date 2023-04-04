# K8s Restarter

A small daemon meant to run alongside the official Kubernetes descheduler, performing destructive tasks on pods as necessary.

Currently supports;
- Force-deleting pods that are stuck terminating
- Deleting pods that never progress past pending
- Evicting pods that never become ready
- Evicting pods that have restarted too many times

## Usage

**TODO**

Not recommended for use yet

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ananace/ruby-k8s-restarter

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
