{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "rices";

  options = with delib; let
    rice = {
      options = riceSubmoduleOptions;
    };
  in {
    rice = riceOption rice;
    rices = ricesOption rice;
  };

  home.always = {myconfig, ...}: {
    # imports = [inputs.stylix.homeModules.stylix];
    assertions = delib.riceNamesAssertions myconfig.rices;
  };

  nixos.always = {myconfig, ...}: {
    imports = [inputs.stylix.nixosModules.stylix];
    assertions = delib.riceNamesAssertions myconfig.rices;
  };
}
