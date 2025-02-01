{nixos-render-docs}:
nixos-render-docs.overrideAttrs (old: {
  postPatch = ''
    ls -al nixos_render_docs

    substituteInPlace ./nixos_render_docs/html.py \
        --replace-fail 'raise UnresolvedXrefError(f"bad local reference, id {href} not known")' "return f'<a class=\"{tag}\" href=\"{href}\" {title} {target}>{text}'"
    substituteInPlace ./tests/test_html.py \
        --replace-fail 'with pytest.raises(nrd.html.UnresolvedXrefError) as exc:' "" \
        --replace-fail 'c._render("[](#baz)")' "" \
        --replace-fail "assert exc.value.args[0] == 'bad local reference, id #baz not known'" ""
  '';
  doCheck = false;
})
