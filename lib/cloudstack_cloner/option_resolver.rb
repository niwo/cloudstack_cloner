module CloudstackCloner
  module OptionResolver

    def resolve_zone(opts)
      if opts[:zone]
        zones = client.list_zones
        zone = zones.find {|z| z['name'] == opts[:zone] }
        if !zone
          msg = opts[:zone] ? "Zone '#{opts[:zone]}' is invalid." : "No zone found."
          say "Error: #{msg}", :red
          exit 1
        end
        opts[:zone_id] = zone['id']
      end
      opts
    end

    def resolve_domain(opts)
      if opts[:domain]
        if domain = client.list_domains(name: opts[:domain]).first
          opts[:domain_id] = domain['id']
        else
          say "Error: Domain #{opts[:domain]} not found.", :red
          exit 1
        end
      end
      opts
    end

    def resolve_project(opts)
      if opts[:project]
        if %w(ALL -1).include? opts[:project]
          opts[:project_id] = "-1"
        elsif project = client.list_projects(name: opts[:project], listall: true).first
          opts[:project_id] = project['id']
        else
          say "Error: Project #{opts[:project]} not found.", :red
          exit 1
        end
      end
      opts
    end

    def resolve_account(opts)
      if opts[:account]
        if account = client.list_accounts(name: opts[:account], listall: true).first
          opts[:account_id] = account['id']
          opts[:domain_id] = account['domainid']
        else
          say "Error: Account #{opts[:account]} not found.", :red
          exit 1
        end
      end
      opts
    end

    def resolve_networks(opts)
      networks = []
      available_networks = network = client.list_networks(
        zone_id: opts[:zone_id],
        project_id: opts[:project_id]
      )
      if opts[:networks]
        opts[:networks].each do |name|
          unless network = available_networks.find { |n| n['name'] == name }
            say "Error: Network '#{name}' not found.", :red
            exit 1
          end
          networks << network['id'] rescue nil
        end
      end
      networks.compact!
      if networks.empty?
        #unless default_network = client.list_networks(project_id: opts[:project_id]).find {
        #  |n| n['isdefault'] == true }
        unless default_network = client.list_networks(project_id: opts[:project_id]).first
          say "Error: No default network found.", :red
          exit 1
        end
        networks << available_networks.first['id'] rescue nil
      end
      opts[:network_ids] = networks.join(',')
      opts
    end

    def resolve_template(opts)
      if opts[:template]
        if template = client.list_templates(
            name: opts[:template],
            template_filter: "executable",
            project_id: opts[:project_id]
          ).first
          opts[:template_id] = template['id']
        else
          say "Error: Template #{opts[:template]} not found.", :red
          exit 1
        end
      end
      opts
    end

    def resolve_compute_offering(opts)
      if opts[:offering]
        if offering = client.list_service_offerings(name: opts[:offering]).first
          opts[:service_offering_id] = offering['id']
        else
          say "Error: Offering #{opts[:offering]} not found.", :red
          exit 1
        end
      end
      opts
    end

    def resolve_disk_offering(opts)
      if opts[:disk_offering]
        unless disk_offering = client.list_disk_offerings(name: opts[:disk_offering]).first
          say "Error: Disk offering '#{opts[:disk_offering]}' not found.", :red
          exit 1
        end
        opts[:disk_offering_id] = disk_offering['id']
      end
      opts
    end

    def resolve_virtual_machine(opts)
      if opts[:virtual_machine]
        args = { name: opts[:virtual_machine], listall: true }
        args[:project_id] = opts[:project_id]
        unless vm = client.list_virtual_machines(args).first
          say "Error: VM '#{opts[:virtual_machine]}' not found.", :red
          exit 1
        end
        opts[:virtual_machine_id] = vm['id']
      end
      opts
    end

    def resolve_snapshot(opts)
      if opts[:snapshot]
        args = { name: opts[:snapshot], listall: true }
        args[:project_id] = opts[:project_id]
        unless snapshot = client.list_snapshots(args).first
          say "Error: Snapshot '#{opts[:snapshot]}' not found.", :red
          exit 1
        end
        opts[:snapshot_id] = snapshot['id']
      end
      opts
    end

  end
end
