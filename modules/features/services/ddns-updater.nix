{
  den.aspects.services.ddns-updater.nixos = {
    services.ddns-updater = {
      enable = true;
      environment = {
        SERVER_ENABLED = "no";
        CONFIG_FILEPATH = "/etc/ddns-updater/config.json";
        PERIOD = "5m";
        PUBLICIPV6_HTTP_PROVIDERS = "seeip,ipify";
        PUBLICIP_DNS_PROVIDERS = "cloudflare";
      };
    };
  };
}
