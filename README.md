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

- `draft-liu-parecki-oauth-delegation-chaining-00.xml` is the source of truth.
- [draft-liu-parecki-oauth-delegation-chaining-00.md](draft-liu-parecki-oauth-delegation-chaining-00.md) is the generated Markdown rendering, kept at the repository root for easy review and discussion.
- `build/` holds the generated HTML and text versions, rebuilt automatically on every XML change by GitHub Actions.
- `tools/md-filter.lua` cleans the Markdown output when converting from HTML.

## Building locally

    pip install xml2rfc
    xml2rfc --v3 draft-liu-parecki-oauth-delegation-chaining-00.xml --html -o build/draft.html
    xml2rfc --v3 draft-liu-parecki-oauth-delegation-chaining-00.xml --text -o build/draft.txt

## Reviewing

The Markdown file at the repository root is intended for line-based review and
discussion. Please send changes to the XML source, not to the generated files.
