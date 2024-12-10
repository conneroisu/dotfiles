let
  connerohnesorge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjgRJ4+HQhHWXWfpJ/eFUG1rcs84A8KZrrTyoP5NIF4";
  users = [ connerohnesorge ];

  # system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJDyIr/FSz1cJdcoW69R+NrWzwGK/+3gJpqD1t8L2zE";
  # system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzxQgondgEYcLpcPdJLrTdNgZ2gznOHCAxMdaceTUT1";
  # systems = [ system1 system2 ];
in
{
  "login.age".publicKeys = [ connerohnesorge ];
  "secret2.age".publicKeys = users;
}
