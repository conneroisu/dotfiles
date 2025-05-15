{delib, ...}:
delib.module {
  name = "constants";

  options.constants = with delib; {
    username = readOnly (strOption "connerohnesorge");
    userfullname = readOnly (strOption "Conner Ohnesorge");
    useremail = readOnly (strOption "conneroisu@outlook.com");
  };
}
