{
  outputs = { self }: {
    templates = {
      python = {
        path = ./python;
        description = "A basic python/poetry flake";
      };
    };
  };
}
