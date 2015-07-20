# CloudstackCloner

[![Gem Version](https://badge.fury.io/rb/cloudstack_cloner.png)](http://badge.fury.io/rb/cloudstack_cloner)

Automated CloudStack VM cloning and copying/attaching of existing data disks.
CloudstackCloner uses [cloudstack_client](https://github.com/niwo/cloudstack_client) for CloudStack API communication.

## Installation

Install the Gem:

```bash
$ gem install cloudstack_cloner
```

## Configuration

A [cloudstack-cli](https://github.com/niwo/cloudstack-cli) style configuration file is used for setting up URL, keys and secrets of your CloudStack API connection.

## Usage

### Preconditions
  * The machine to be cloned has to be in "Stopped" state.
  * The data disks to be copied have to be in state "Ready".

### Example

```bash
$ cloudstack_cloner clone --virtual_machine test01 --clone-name test-clone --project Playground --data-volumes test-volume --offering 2cpu_2gb
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cloudstack_cloner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
