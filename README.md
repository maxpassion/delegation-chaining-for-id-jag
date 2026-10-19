# Delegation Chaining for the Identity Assertion JWT Authorization Grant

Source repository for the individual Internet-Draft
`draft-liu-parecki-oauth-delegation-chaining`.

This draft is the companion profile that Section 4.3 of
[ID-JAG](https://datatracker.ietf.org/doc/draft-ietf-oauth-identity-assertion-authz-grant/)
defers to: it defines how the actor_token of a Token Exchange is validated, how
it influences policy evaluation, and how the act claim is populated when ID-JAGs
are chained across multi-hop delegation chains, using SPIFFE workload
identities as the actor.

## Layout

- [draft-liu-parecki-oauth-delegation-chaining-00.md](draft-liu-parecki-oauth-delegation-chaining-00.md)
  is the source.
- [draft-liu-parecki-oauth-delegation-chaining-00.txt](/build/draft-liu-parecki-oauth-delegation-chaining-00.txt)
  is the txt version.

- `build/` holds the generated RFC XML v3, HTML, and text renditions, rebuilt
  automatically on every Markdown change by GitHub Actions.

## Building locally

    gem install kramdown-rfc2629
    pip install xml2rfc
    kdrfc -3 -h draft-liu-parecki-oauth-delegation-chaining-00.md

This produces the `.xml`, `.html`, and `.txt` renditions next to the Markdown
source and caches fetched references in `.refcache/`.

## Reviewing

Please edit the Markdown source directly. Citations use the kramdown-rfc
syntax: `{{!RFC6749}}` for a normative reference, `{{?RFC7517}}` for an
informative one, and `{{Section 4.1 of !RFC8693}}` to cite a specific section.
Do not edit the files under `build/`; they are generated.
