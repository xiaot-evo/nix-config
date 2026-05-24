{ den, ... }:
{
  den.aspects.services.kdeconnect = {
    homeManager = {
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };
    };
  };
}
