{
  outputs = { self }: {
    templates = {
      python = {
        path = ./python;
        description = "A basic python/poetry flake";
      };
      rust = {
        path = ./rust;
        description = "A devenv-based rust flake";
      };
    };
  };
}
