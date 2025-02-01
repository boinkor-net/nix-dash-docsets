{dashing}:
dashing.overrideAttrs (old: {
  patches = [./use-id-values.diff];
})
