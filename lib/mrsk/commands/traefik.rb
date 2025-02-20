class Mrsk::Commands::Traefik < Mrsk::Commands::Base
  def run
    docker :run, "--name traefik",
      "--detach",
      "--restart", "unless-stopped",
      "--log-opt", "max-size=#{MAX_LOG_SIZE}",
      "--publish", port,
      "--volume", "/var/run/docker.sock:/var/run/docker.sock",
      "traefik",
      "--providers.docker",
      "--log.level=DEBUG",
      *cmd_args
  end

  def start
    docker :container, :start, "traefik"
  end

  def stop
    docker :container, :stop, "traefik"
  end

  def info
    docker :ps, "--filter", "name=traefik"
  end

  def logs(since: nil, lines: nil, grep: nil)
    pipe \
      docker(:logs, "traefik", (" --since #{since}" if since), (" --tail #{lines}" if lines), "--timestamps", "2>&1"),
      ("grep '#{grep}'" if grep)
  end

  def follow_logs(host:, grep: nil)
    run_over_ssh pipe(
      docker(:logs, "traefik", "--timestamps", "--tail", "10", "--follow", "2>&1"),
      (%(grep "#{grep}") if grep)
    ).join(" "), host: host
  end

  def remove_container
    docker :container, :prune, "--force", "--filter", "label=org.opencontainers.image.title=Traefik"
  end

  def remove_image
    docker :image, :prune, "--all", "--force", "--filter", "label=org.opencontainers.image.title=Traefik"
  end

  def port
    "#{config.raw_config.traefik.fetch("host_port", "80")}:80"
  end

  private
    def cmd_args
      config.raw_config.traefik.fetch("args", {}).collect { |(key, value)| [ "--#{key}", value ] }.flatten
    end
end
