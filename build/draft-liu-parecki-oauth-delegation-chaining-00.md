| Internet-Draft | Delegation Chaining for ID-JAG | October 2026 |
|----------------|--------------------------------|--------------|
| Liu & Parecki  | Expires 18 April 2027          | \[Page\]     |

<div id="external-metadata" class="document-information">

</div>

<div id="internal-metadata" class="document-information">

Workgroup:  
Network Working Group

Internet-Draft:  
draft-liu-parecki-oauth-delegation-chaining-00

Published:  
15 October 2026

Intended Status:  
Standards Track

Expires:  
18 April 2027

Authors:  
<div class="author">

<div class="author-name">

D. Liu

</div>

<div class="org">

Alibaba Group

</div>

</div>

<div class="author">

<div class="author-name">

A. Parecki

</div>

<div class="org">

Okta

</div>

</div>

</div>

# Delegation Chaining for the Identity Assertion JWT Authorization Grant

<div id="section-abstract" class="section">

## <a href="#abstract" class="selfRef">Abstract</a>

The Identity Assertion JWT Authorization Grant (ID-JAG) defines how a client obtains a delegated authorization grant from an identity assertion. It leaves the validation of the actor_token, the related policy evaluation, and the act claim of the issued ID-JAG open for future profiles. This specification defines those rules for delegation chains, in which a series of workloads, such as AI agents, act on behalf of an initial end-user across multiple hops.<a href="#section-abstract-1" class="pilcrow">¶</a>

Each delegating workload authenticates with a SPIFFE JWT-SVID and presents the ID-JAG it holds as the subject_token of an OAuth 2.0 Token Exchange request. The Authorization Server validates the workload identity, checks that the actor matches the may_act claim of the subject_token, and enforces monotonic scope attenuation. It then issues a new ID-JAG for the next hop, carrying the actor chain in the act claim. An optional variant based on self-issued Delegation Assertions is defined for hops where the Authorization Server is not reachable.<a href="#section-abstract-2" class="pilcrow">¶</a>

</div>

<div id="status-of-memo">

<div id="section-boilerplate.1" class="section">

## <a href="#name-status-of-this-memo" class="section-name selfRef">Status of This Memo</a>

This Internet-Draft is submitted in full conformance with the provisions of BCP 78 and BCP 79.<a href="#section-boilerplate.1-1" class="pilcrow">¶</a>

Internet-Drafts are working documents of the Internet Engineering Task Force (IETF). Note that other groups may also distribute working documents as Internet-Drafts. The list of current Internet-Drafts is at <https://datatracker.ietf.org/drafts/current/>.<a href="#section-boilerplate.1-2" class="pilcrow">¶</a>

Internet-Drafts are draft documents valid for a maximum of six months and may be updated, replaced, or obsoleted by other documents at any time. It is inappropriate to use Internet-Drafts as reference material or to cite them other than as "work in progress."<a href="#section-boilerplate.1-3" class="pilcrow">¶</a>

This Internet-Draft will expire on 18 April 2027.<a href="#section-boilerplate.1-4" class="pilcrow">¶</a>

</div>

</div>

<div id="copyright">

<div id="section-boilerplate.2" class="section">

## <a href="#name-copyright-notice" class="section-name selfRef">Copyright Notice</a>

Copyright (c) 2026 IETF Trust and the persons identified as the document authors. All rights reserved.<a href="#section-boilerplate.2-1" class="pilcrow">¶</a>

This document is subject to BCP 78 and the IETF Trust's Legal Provisions Relating to IETF Documents (<https://trustee.ietf.org/license-info>) in effect on the date of publication of this document. Please review these documents carefully, as they describe your rights and restrictions with respect to this document. Code Components extracted from this document must include Revised BSD License text as described in Section 4.e of the Trust Legal Provisions and are provided without warranty as described in the Revised BSD License.<a href="#section-boilerplate.2-2" class="pilcrow">¶</a>

</div>

</div>

<div id="toc">

<div id="section-toc.1" class="section">

<a href="#" class="toplink" onclick="scroll(0,0)">▲</a>

## <a href="#name-table-of-contents" class="section-name selfRef">Table of Contents</a>

- <div id="section-toc.1-1.1">

  <a href="#section-1" class="auto internal xref">1</a>.  <a href="#name-introduction-and-problem-st" class="internal xref">Introduction and Problem Statement</a>

  </div>

- <div id="section-toc.1-1.2">

  <a href="#section-2" class="auto internal xref">2</a>.  <a href="#name-terminology-and-architectur" class="internal xref">Terminology and Architecture Overview</a>

  </div>

- <div id="section-toc.1-1.3">

  <a href="#section-3" class="auto internal xref">3</a>.  <a href="#name-workload-identity-of-the-ac" class="internal xref">Workload Identity of the Actor</a>

  </div>

- <div id="section-toc.1-1.4">

  <a href="#section-4" class="auto internal xref">4</a>.  <a href="#name-delegation-chaining-with-to" class="internal xref">Delegation Chaining with Token Exchange</a>

  - <div id="section-toc.1-1.4.2.1">

    <a href="#section-4.1" class="auto internal xref">4.1</a>.  <a href="#name-overview" class="internal xref">Overview</a>

    </div>

  - <div id="section-toc.1-1.4.2.2">

    <a href="#section-4.2" class="auto internal xref">4.2</a>.  <a href="#name-token-exchange-request" class="internal xref">Token Exchange Request</a>

    </div>

  - <div id="section-toc.1-1.4.2.3">

    <a href="#section-4.3" class="auto internal xref">4.3</a>.  <a href="#name-authorization-server-proces" class="internal xref">Authorization Server Processing Requirements</a>

    </div>

  - <div id="section-toc.1-1.4.2.4">

    <a href="#section-4.4" class="auto internal xref">4.4</a>.  <a href="#name-the-issued-id-jag" class="internal xref">The Issued ID-JAG</a>

    </div>

  </div>

- <div id="section-toc.1-1.5">

  <a href="#section-5" class="auto internal xref">5</a>.  <a href="#name-optional-variant-self-issue" class="internal xref">Optional Variant: Self-Issued Delegation Assertions</a>

  - <div id="section-toc.1-1.5.2.1">

    <a href="#section-5.1" class="auto internal xref">5.1</a>.  <a href="#name-applicability" class="internal xref">Applicability</a>

    </div>

  - <div id="section-toc.1-1.5.2.2">

    <a href="#section-5.2" class="auto internal xref">5.2</a>.  <a href="#name-assertion-format" class="internal xref">Assertion Format</a>

    </div>

  - <div id="section-toc.1-1.5.2.3">

    <a href="#section-5.3" class="auto internal xref">5.3</a>.  <a href="#name-re-issuance-rules" class="internal xref">Re-Issuance Rules</a>

    </div>

  - <div id="section-toc.1-1.5.2.4">

    <a href="#section-5.4" class="auto internal xref">5.4</a>.  <a href="#name-redemption-at-the-authoriza" class="internal xref">Redemption at the Authorization Server</a>

    </div>

  </div>

- <div id="section-toc.1-1.6">

  <a href="#section-6" class="auto internal xref">6</a>.  <a href="#name-security-considerations" class="internal xref">Security Considerations</a>

  - <div id="section-toc.1-1.6.2.1">

    <a href="#section-6.1" class="auto internal xref">6.1</a>.  <a href="#name-audience-and-hop-binding" class="internal xref">Audience and Hop Binding</a>

    </div>

  - <div id="section-toc.1-1.6.2.2">

    <a href="#section-6.2" class="auto internal xref">6.2</a>.  <a href="#name-monotonic-attenuation" class="internal xref">Monotonic Attenuation</a>

    </div>

  - <div id="section-toc.1-1.6.2.3">

    <a href="#section-6.3" class="auto internal xref">6.3</a>.  <a href="#name-replay-prevention" class="internal xref">Replay Prevention</a>

    </div>

  - <div id="section-toc.1-1.6.2.4">

    <a href="#section-6.4" class="auto internal xref">6.4</a>.  <a href="#name-transport-and-confidentiali" class="internal xref">Transport and Confidentiality</a>

    </div>

  - <div id="section-toc.1-1.6.2.5">

    <a href="#section-6.5" class="auto internal xref">6.5</a>.  <a href="#name-workload-identity-compromis" class="internal xref">Workload Identity Compromise</a>

    </div>

  </div>

- <div id="section-toc.1-1.7">

  <a href="#section-7" class="auto internal xref">7</a>.  <a href="#name-iana-considerations" class="internal xref">IANA Considerations</a>

  </div>

- <div id="section-toc.1-1.8">

  <a href="#section-8" class="auto internal xref">8</a>.  <a href="#name-normative-references" class="internal xref">Normative References</a>

  </div>

- <div id="section-toc.1-1.9">

  <a href="#section-9" class="auto internal xref">9</a>.  <a href="#name-informative-references" class="internal xref">Informative References</a>

  </div>

- <div id="section-toc.1-1.10">

  <a href="#appendix-A" class="auto internal xref">Appendix A</a>.  <a href="#name-complete-end-to-end-use-cas" class="internal xref">Complete End-to-End Use Case: Multi-Hop Financial Research Agent Workflow</a>

  - <div id="section-toc.1-1.10.2.1">

    <a href="#appendix-A.1" class="auto internal xref">A.1</a>.  <a href="#name-scenario-overview" class="internal xref">Scenario Overview</a>

    </div>

  - <div id="section-toc.1-1.10.2.2">

    <a href="#appendix-A.2" class="auto internal xref">A.2</a>.  <a href="#name-step-by-step-protocol-flow" class="internal xref">Step-by-Step Protocol Flow</a>

    </div>

  </div>

- <div id="section-toc.1-1.11">

  <a href="#appendix-B" class="auto internal xref"></a><a href="#name-acknowledgments" class="internal xref">Acknowledgments</a>

  </div>

- <div id="section-toc.1-1.12">

  <a href="#appendix-C" class="auto internal xref"></a><a href="#name-authors-addresses" class="internal xref">Authors' Addresses</a>

  </div>

</div>

</div>

<div id="introduction">

<div id="section-1" class="section">

## <a href="#section-1" class="section-number selfRef">1.</a> <a href="#name-introduction-and-problem-st" class="section-name selfRef">Introduction and Problem Statement</a>

In modern distributed multi-tier application architectures and autonomous AI agent ecosystems (e.g., User -\> Agent A -\> Agent B -\> Agent C -\> MCP Tool), service-to-service execution chains frequently cross trust boundaries while operating on behalf of an initial end-user.<a href="#section-1-1" class="pilcrow">¶</a>

The OAuth 2.0 framework <a href="#RFC6749" class="internal xref">RFC 6749</a> and the Identity Assertion JWT Authorization Grant (ID-JAG) <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a> address identity assertions and authorization grants for single-hop scenarios. However, two gaps remain in multi-hop execution chains:<a href="#section-1-2" class="pilcrow">¶</a>

1.  <div id="section-1-3.1">

    The actor_token validation gap. <a href="https://datatracker.ietf.org/doc/html/draft-ietf-oauth-identity-assertion-authz-grant-04#section-4.3" class="relref">Section 4.3</a> of \[<a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="cite xref">I-D.ietf-oauth-identity-assertion-authz-grant</a>\] states: "This specification does not define normative processing requirements for actor_token or whether an act claim is included in the issued ID-JAG. Future profiles or extensions MAY define how actor_token is validated, how it influences policy evaluation, and whether it results in an act claim in the issued ID-JAG."<a href="#section-1-3.1.1" class="pilcrow">¶</a>

    </div>

2.  <div id="section-1-3.2">

    The delegation continuation gap. A standardized mechanism is needed that lets an intermediate delegate, e.g., Agent B, propagate the end-user's authorization further down the chain, e.g., to Agent C, with strictly narrowed privileges, while keeping every hop verifiable against a common trust root.<a href="#section-1-3.2.1" class="pilcrow">¶</a>

    </div>

This specification is such a profile. It defines how actor_token is validated, how it influences policy evaluation, and how the act claim is populated when ID-JAGs are chained across multiple hops. The mechanism combines:<a href="#section-1-4" class="pilcrow">¶</a>

1.  <div id="section-1-5.1">

    SPIFFE workload identities, carried as JWT-SVIDs, as the machine identity of each actor <a href="#SPIFFE-ID" class="internal xref">SPIFFE-ID</a> <a href="#SPIFFE-JWT-SVID" class="internal xref">SPIFFE-JWT-SVID</a>.<a href="#section-1-5.1.1" class="pilcrow">¶</a>

    </div>

2.  <div id="section-1-5.2">

    OAuth 2.0 Token Exchange <a href="#RFC8693" class="internal xref">RFC 8693</a> as the point where the machine identity of the delegating workload and the delegated authorization of the end-user are verified and merged by the Authorization Server (AS).<a href="#section-1-5.2.1" class="pilcrow">¶</a>

    </div>

3.  <div id="section-1-5.3">

    The may_act claim (<a href="https://rfc-editor.org/rfc/rfc8693#section-4.4" class="relref">Section 4.4</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\]) to bind each issued ID-JAG to the entity entitled to redeem it at the next hop, and the act claim (<a href="https://rfc-editor.org/rfc/rfc8693#section-4.1" class="relref">Section 4.1</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\]) to carry the delegation lineage.<a href="#section-1-5.3.1" class="pilcrow">¶</a>

    </div>

Every hop of the chain performs exactly one Token Exchange request. The AS is the only issuer of ID-JAGs in the chain, so privilege attenuation is enforced by the AS at every hop rather than merely asserted by the delegating entity, and the full lineage, e.g., User -\> Agent A -\> Agent B -\> Agent C, is carried in the act claim of the final Access Token.<a href="#section-1-6" class="pilcrow">¶</a>

For hops where a round trip to the AS is not practical, for example across trust domains with no reachable common AS, this document also defines an optional variant based on self-issued Delegation Assertions, see <a href="#self-issued" class="auto internal xref">Section 5</a>. That variant offers weaker guarantees and supplements, but does not replace, the Token Exchange mechanism.<a href="#section-1-7" class="pilcrow">¶</a>

</div>

</div>

<div id="terminology">

<div id="section-2" class="section">

## <a href="#section-2" class="section-number selfRef">2.</a> <a href="#name-terminology-and-architectur" class="section-name selfRef">Terminology and Architecture Overview</a>

This specification uses the terms "authorization server" (AS), "client", "resource server" (RS), and "access token" defined in <a href="#RFC6749" class="internal xref">RFC 6749</a>, the token exchange parameters defined in <a href="https://rfc-editor.org/rfc/rfc8693#section-2.1" class="relref">Section 2.1</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\], and the act and may_act claims defined in <a href="https://rfc-editor.org/rfc/rfc8693#section-4.1" class="relref">Section 4.1</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\] and <a href="https://rfc-editor.org/rfc/rfc8693#section-4.4" class="relref">Section 4.4</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\].<a href="#section-2-1" class="pilcrow">¶</a>

In addition, this specification defines the following roles and credentials:<a href="#section-2-2" class="pilcrow">¶</a>

<span class="break"></span>

ID-JAG  
An Identity Assertion JWT Authorization Grant <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a>. In this profile, an ID-JAG represents the delegated authorization of the end-user held by one entity of the chain.<a href="#section-2-3.2" class="pilcrow">¶</a>

Delegating Entity (e.g., Agent A / Service A)  
An upstream workload that holds an ID-JAG and delegates a sub-operation or task to a downstream entity.<a href="#section-2-3.4" class="pilcrow">¶</a>

Target Entity (e.g., Agent B / Service B)  
A downstream workload that receives the delegated authorization, executes computations, or further delegates to subsequent entities.<a href="#section-2-3.6" class="pilcrow">¶</a>

Workload Identity (SPIFFE SVID)  
A machine identity credential issued to each workload instance by trusted infrastructure, such as SPIRE, serving as the immutable actor proof <a href="#SPIFFE-ID" class="internal xref">SPIFFE-ID</a> <a href="#SPIFFE-JWT-SVID" class="internal xref">SPIFFE-JWT-SVID</a>.<a href="#section-2-3.8" class="pilcrow">¶</a>

Delegation Assertion (DA)  
A short-lived JWT self-issued by a delegating entity in the optional variant of <a href="#self-issued" class="auto internal xref">Section 5</a>, carrying the initial user context, the delegation history, and privilege attenuation limits.<a href="#section-2-3.10" class="pilcrow">¶</a>

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 \[<a href="#RFC2119" class="cite xref">RFC2119</a>\] \[<a href="#RFC8174" class="cite xref">RFC8174</a>\] when, and only when, they appear in all capitals, as shown here.<a href="#section-2-4" class="pilcrow">¶</a>

</div>

</div>

<div id="workload-identity">

<div id="section-3" class="section">

## <a href="#section-3" class="section-number selfRef">3.</a> <a href="#name-workload-identity-of-the-ac" class="section-name selfRef">Workload Identity of the Actor</a>

Every workload in the chain, for example an AI agent runtime or a container hosting an agentic loop, is provisioned with a cryptographic machine identity by trusted infrastructure, such as a SPIRE server. The identity is a SPIFFE ID <a href="#SPIFFE-ID" class="internal xref">SPIFFE-ID</a> of the form:<a href="#section-3-1" class="pilcrow">¶</a>

<div id="section-3-2" class="sourcecode">

    spiffe://<trust-domain>/ns/<namespace>/sa/<workload-name>

<a href="#section-3-2" class="pilcrow">¶</a>

</div>

The workload proves this identity with a JWT-SVID, a JWT whose sub claim carries the SPIFFE ID and which is signed by the SPIRE server of the trust domain. Verifying a JWT-SVID requires the SPIFFE trust bundle of that trust domain. JWT-SVIDs are short-lived by design <a href="#SPIFFE-JWT-SVID" class="internal xref">SPIFFE-JWT-SVID</a>.<a href="#section-3-3" class="pilcrow">¶</a>

In this profile, the JWT-SVID of the delegating entity is presented as the actor_token of the Token Exchange request described in <a href="#exchange-request" class="auto internal xref">Section 4.2</a>. This binds the machine identity of the current actor into the delegation chain, independently of any application-level identity. The JWT-SVID MAY also serve as the client authentication credential at the token endpoint, as described in <a href="#I-D.ietf-oauth-spiffe-client-auth" class="internal xref">draft-ietf-oauth-spiffe-client-auth</a>. When SVID-based client authentication is not used, the AS MUST still authenticate the client with some other mechanism.<a href="#section-3-4" class="pilcrow">¶</a>

</div>

</div>

<div id="chaining">

<div id="section-4" class="section">

## <a href="#section-4" class="section-number selfRef">4.</a> <a href="#name-delegation-chaining-with-to" class="section-name selfRef">Delegation Chaining with Token Exchange</a>

<div id="chain-overview">

<div id="section-4.1" class="section">

### <a href="#section-4.1" class="section-number selfRef">4.1.</a> <a href="#name-overview" class="section-name selfRef">Overview</a>

The chain starts like any ID-JAG flow. The end-user authenticates to the AS, for example with OpenID Connect <a href="#OpenID.Core" class="internal xref">OpenID.Core</a>. The first workload, Agent A, requests its initial ID-JAG with the ID-JAG grant <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a>, presenting the end-user's identity assertion. The initial ID-JAG has the end-user as its subject and carries the end-user's authorization for Agent A.<a href="#section-4.1-1" class="pilcrow">¶</a>

When Agent A decides to delegate a sub-operation to Agent B, it does not mint the delegated credential itself. Agent A sends a Token Exchange request to the token endpoint of the AS: subject_token is the ID-JAG Agent A holds, actor_token is Agent A's JWT-SVID, and audience names Agent B. The AS validates the request as described in <a href="#as-processing" class="auto internal xref">Section 4.3</a> and issues a new ID-JAG. The subject remains the end-user, the act claim records Agent A as the current actor, and the may_act claim names Agent B as the entity entitled to redeem the new ID-JAG.<a href="#section-4.1-2" class="pilcrow">¶</a>

Agent A passes the new ID-JAG to Agent B over the inter-agent transport, for example an HTTP header, gRPC metadata, or an MCP payload. Agent B now holds the delegated authorization and can either redeem it for an Access Token of a resource server or delegate further to Agent C in exactly the same way. Each hop of the chain therefore performs exactly one Token Exchange request, and every ID-JAG in the chain is issued by the same AS.<a href="#section-4.1-3" class="pilcrow">¶</a>

The chain ends when the last workload exchanges the ID-JAG it holds for an Access Token of the resource server it needs to call. The Access Token carries the complete actor chain in its act claim, e.g., User -\> Agent A -\> Agent B -\> Agent C, which gives the resource server verifiable multi-hop provenance.<a href="#section-4.1-4" class="pilcrow">¶</a>

When the target entity operates in a different trust domain with its own AS, the AS of the delegating entity issues the ID-JAG with the aud claim set to the issuer identifier of the target domain's AS, as described in <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a>. The target entity redeems the ID-JAG there. The processing requirements of <a href="#as-processing" class="auto internal xref">Section 4.3</a> apply at whichever AS redeems the ID-JAG.<a href="#section-4.1-5" class="pilcrow">¶</a>

</div>

</div>

<div id="exchange-request">

<div id="section-4.2" class="section">

### <a href="#section-4.2" class="section-number selfRef">4.2.</a> <a href="#name-token-exchange-request" class="section-name selfRef">Token Exchange Request</a>

Each hop of the chain is one Token Exchange request to the token endpoint of the AS, as defined in <a href="https://rfc-editor.org/rfc/rfc8693#section-2.1" class="relref">Section 2.1</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\], with the following parameters:<a href="#section-4.2-1" class="pilcrow">¶</a>

<div id="section-4.2-2" class="sourcecode">

    grant_type=urn:ietf:params:oauth:grant-type:token-exchange
    subject_token=(the ID-JAG held by the delegating entity)
    subject_token_type=urn:ietf:params:oauth:token-type:id-jag
    actor_token=(the JWT-SVID of the delegating entity)
    actor_token_type=urn:ietf:params:oauth:token-type:jwt
    requested_token_type=urn:ietf:params:oauth:token-type:id-jag
    audience=(the SPIFFE ID or resource URI of the target entity)
    scope=(no wider than the scope of the subject_token)

<a href="#section-4.2-2" class="pilcrow">¶</a>

</div>

The audience parameter names the target entity of the delegation, e.g., its SPIFFE ID. The aud claim of the issued ID-JAG continues to identify the AS that redeems it, as required by <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a>. The AS records the target entity in the may_act claim of the issued ID-JAG instead, which binds the ID-JAG to the entity entitled to redeem it in the next exchange.<a href="#section-4.2-3" class="pilcrow">¶</a>

The delegating entity is both the authenticated client and the actor of the exchange. It SHOULD authenticate at the token endpoint with its JWT-SVID, as described in <a href="#I-D.ietf-oauth-spiffe-client-auth" class="internal xref">draft-ietf-oauth-spiffe-client-auth</a>, so that the client identity and the actor_token carry the same machine identity. Other client authentication methods MAY be used, in which case the AS still MUST verify that the actor_token matches the authenticated client, see <a href="#as-processing" class="auto internal xref">Section 4.3</a>.<a href="#section-4.2-4" class="pilcrow">¶</a>

The last hop of the chain requests an Access Token instead of an ID-JAG, with requested_token_type=urn:ietf:params:oauth:token-type:access_token and audience set to the resource server. The response to every exchange follows <a href="https://rfc-editor.org/rfc/rfc8693#section-2.2.1" class="relref">Section 2.2.1</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\]. For an ID-JAG, the ID-JAG is returned in the access_token parameter and token_type is set to N_A.<a href="#section-4.2-5" class="pilcrow">¶</a>

</div>

</div>

<div id="as-processing">

<div id="section-4.3" class="section">

### <a href="#section-4.3" class="section-number selfRef">4.3.</a> <a href="#name-authorization-server-proces" class="section-name selfRef">Authorization Server Processing Requirements</a>

Upon receiving a Token Exchange request as described in <a href="#exchange-request" class="auto internal xref">Section 4.2</a>, the AS executes the following verification and policy evaluation pipeline. These requirements answer the questions that <a href="https://datatracker.ietf.org/doc/html/draft-ietf-oauth-identity-assertion-authz-grant-04#section-4.3" class="relref">Section 4.3</a> of \[<a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="cite xref">I-D.ietf-oauth-identity-assertion-authz-grant</a>\] leaves open, and they apply at every hop of the chain:<a href="#section-4.3-1" class="pilcrow">¶</a>

1.  <div id="section-4.3-2.1">

    Client authentication: The AS MUST authenticate the client making the request. SVID-based client authentication <a href="#I-D.ietf-oauth-spiffe-client-auth" class="internal xref">draft-ietf-oauth-spiffe-client-auth</a> SHOULD be used, in which case the authenticated client is identified by its SPIFFE ID.<a href="#section-4.3-2.1.1" class="pilcrow">¶</a>

    </div>

2.  <div id="section-4.3-2.2">

    Actor validation: The actor_token MUST be a JWT-SVID <a href="#SPIFFE-JWT-SVID" class="internal xref">SPIFFE-JWT-SVID</a>. The AS MUST verify its signature against the SPIFFE trust bundle of the actor's trust domain, MUST verify its temporal validity (exp and nbf), and MUST verify that it is an intended audience of the JWT-SVID as identified by its aud claim. The SPIFFE ID in the sub claim of the actor_token MUST identify the authenticated client. The AS MUST reject the request otherwise.<a href="#section-4.3-2.2.1" class="pilcrow">¶</a>

    </div>

3.  <div id="section-4.3-2.3">

    Subject validation: The subject_token MUST be validated as an ID-JAG as required by <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a>, including signature, issuer, audience, expiration, not-before, and jti. The aud claim of the subject_token MUST identify the AS itself. Because the AS issued every ID-JAG in the chain, the signature of the subject_token also covers its act chain.<a href="#section-4.3-2.3.1" class="pilcrow">¶</a>

    </div>

4.  <div id="section-4.3-2.4">

    Hop binding: If the subject_token contains a may_act claim, the AS MUST verify that the sub member of may_act equals the SPIFFE ID of the actor_token, and MUST reject the request otherwise. This binds every ID-JAG to its intended redeemer, so a stolen ID-JAG cannot be redeemed by a different workload, and the delegating entity itself cannot redeem the ID-JAG it requested for its target. If the subject_token contains no may_act claim, the AS MUST apply its own policy to decide whether the current actor may delegate the subject_token further.<a href="#section-4.3-2.4.1" class="pilcrow">¶</a>

    </div>

5.  <div id="section-4.3-2.5">

    Attenuation check: The requested scope and authorization_details <a href="#RFC9396" class="internal xref">RFC 9396</a> MUST be a subset of or equal to those of the subject_token. The AS MUST reject any request that would widen privileges, including requests that add actions, datatypes, or locations to an authorization_details object of the subject_token. The AS MAY further narrow the granted scope and authorization_details based on policy.<a href="#section-4.3-2.5.1" class="pilcrow">¶</a>

    </div>

6.  <div id="section-4.3-2.6">

    Delegation policy: The AS MUST apply its delegation policy, e.g., which workloads may call which downstream entities, and which scopes each target entity may receive at all. Policy evaluation takes both the actor identity and the subject authorization as input.<a href="#section-4.3-2.6.1" class="pilcrow">¶</a>

    </div>

7.  <div id="section-4.3-2.7">

    Issuance: The AS issues the new ID-JAG with the subject unchanged, i.e., the end-user, and with the attenuated scope and authorization_details. The act and may_act claims are populated as described in <a href="#issued-id-jag" class="auto internal xref">Section 4.4</a>. The lifetime of the issued ID-JAG SHOULD be short, and the jti value MUST be unique among all tokens issued by the AS.<a href="#section-4.3-2.7.1" class="pilcrow">¶</a>

    </div>

</div>

</div>

<div id="issued-id-jag">

<div id="section-4.4" class="section">

### <a href="#section-4.4" class="section-number selfRef">4.4.</a> <a href="#name-the-issued-id-jag" class="section-name selfRef">The Issued ID-JAG</a>

The issued ID-JAG carries the end-user as its subject, the attenuated privileges, and the actor chain. The act claim follows <a href="https://rfc-editor.org/rfc/rfc8693#section-4.1" class="relref">Section 4.1</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\]: the outermost value represents the current actor, and nested values represent prior actors. At each exchange, the AS sets the outermost act value to the actor of the current request and nests the act claim of the subject_token inside it. The may_act claim follows <a href="https://rfc-editor.org/rfc/rfc8693#section-4.4" class="relref">Section 4.4</a> of \[<a href="#RFC8693" class="cite xref">RFC8693</a>\] and names the target entity, i.e., the party entitled to act as the actor in the next exchange.<a href="#section-4.4-1" class="pilcrow">¶</a>

The following is an example of the ID-JAG issued for the first hop, where Agent A delegates to Agent B:<a href="#section-4.4-2" class="pilcrow">¶</a>

<div id="section-4.4-3" class="lang-json sourcecode">

    {
      "iss": "https://auth.enterprise.net",
      "sub": "user_original_12345",
      "aud": "https://auth.enterprise.net",
      "client_id": "spiffe://cluster.local/ns/ai/sa/agent-researcher",
      "exp": 1776326800,
      "iat": 1776326740,
      "jti": "urn:uuid:8e41-4b72-9b2a-111122223333",
      "scope": "reports:read",
      "act": {
        "sub": "spiffe://cluster.local/ns/ai/sa/agent-researcher"
      },
      "may_act": {
        "sub": "spiffe://cluster.local/ns/ai/sa/agent-db-proxy"
      }
    }

<a href="#section-4.4-3" class="pilcrow">¶</a>

</div>

The following is an example of the ID-JAG issued for the second hop, where Agent B delegates to Agent C. The act claim nests the actor chain, and the scope has been attenuated further:<a href="#section-4.4-4" class="pilcrow">¶</a>

<div id="section-4.4-5" class="lang-json sourcecode">

    {
      "iss": "https://auth.enterprise.net",
      "sub": "user_original_12345",
      "aud": "https://auth.enterprise.net",
      "client_id": "spiffe://cluster.local/ns/ai/sa/agent-db-proxy",
      "exp": 1776326900,
      "iat": 1776326840,
      "jti": "urn:uuid:f901-2222-3333-444455556666",
      "scope": "reports:read:q3_only",
      "act": {
        "sub": "spiffe://cluster.local/ns/ai/sa/agent-db-proxy",
        "act": {
          "sub": "spiffe://cluster.local/ns/ai/sa/agent-researcher"
        }
      },
      "may_act": {
        "sub": "spiffe://cluster.local/ns/ai/sa/agent-db-worker"
      }
    }

<a href="#section-4.4-5" class="pilcrow">¶</a>

</div>

Deployments MAY carry additional claims in the issued ID-JAG, e.g., task context for AI agent workloads, as long as the claims required by <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a> are present.<a href="#section-4.4-6" class="pilcrow">¶</a>

</div>

</div>

</div>

</div>

<div id="self-issued">

<div id="section-5" class="section">

## <a href="#section-5" class="section-number selfRef">5.</a> <a href="#name-optional-variant-self-issue" class="section-name selfRef">Optional Variant: Self-Issued Delegation Assertions</a>

This section defines an optional variant for hops where a Token Exchange round trip to the AS is not practical. It keeps the protocol shape of the primary mechanism, a signed JWT passed in-band and redeemed together with a workload identity, but moves assertion issuance from the AS to the delegating entities themselves.<a href="#section-5-1" class="pilcrow">¶</a>

<div id="self-issued-applicability">

<div id="section-5.1" class="section">

### <a href="#section-5.1" class="section-number selfRef">5.1.</a> <a href="#name-applicability" class="section-name selfRef">Applicability</a>

The self-issued variant applies when the delegating entity and the target entity operate in trust domains with no common reachable AS, or when the added latency of a synchronous exchange at every hop is unacceptable for the workload.<a href="#section-5.1-1" class="pilcrow">¶</a>

The self-issued variant SHOULD NOT be used when the AS of the chain is reachable. Token Exchange gives the AS the opportunity to validate the actor and enforce attenuation at every hop. The self-issued variant cannot provide those guarantees, see <a href="#self-issued-redemption" class="auto internal xref">Section 5.4</a>.<a href="#section-5.1-2" class="pilcrow">¶</a>

</div>

</div>

<div id="self-issued-format">

<div id="section-5.2" class="section">

### <a href="#section-5.2" class="section-number selfRef">5.2.</a> <a href="#name-assertion-format" class="section-name selfRef">Assertion Format</a>

A Delegation Assertion (DA) is a JWT <a href="#RFC7519" class="internal xref">RFC 7519</a>. A delegating entity, e.g., Agent A, MUST possess a valid authorization grant or active token representing the end-user (sub) before it issues a downstream Delegation Assertion.<a href="#section-5.2-1" class="pilcrow">¶</a>

Each Delegation Assertion MUST be signed using a private key cryptographically tied to the delegating entity's SPIFFE workload identity lifecycle. The AS validates the signature using the delegating entity's registered public key, retrieved via JWKS <a href="#RFC7517" class="internal xref">RFC 7517</a> or trusted infrastructure metadata.<a href="#section-5.2-2" class="pilcrow">¶</a>

A Delegation Assertion contains the following claims:<a href="#section-5.2-3" class="pilcrow">¶</a>

- <div id="section-5.2-4.1">

  iss: the SPIFFE ID of the delegating entity.<a href="#section-5.2-4.1.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.2">

  sub: the subject identifier of the initial end-user.<a href="#section-5.2-4.2.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.3">

  aud: the token endpoint of the AS at which the assertion is redeemed.<a href="#section-5.2-4.3.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.4">

  exp and nbf: a short temporal validity window, a lifetime of 60 seconds or less is recommended.<a href="#section-5.2-4.4.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.5">

  jti: a unique assertion identifier, used for replay prevention.<a href="#section-5.2-4.5.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.6">

  scope: the attenuated privilege scope, no wider than the privileges of the issuing entity.<a href="#section-5.2-4.6.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.7">

  authorization_details: optional fine-grained authorization details via <a href="#RFC9396" class="internal xref">RFC 9396</a>, e.g., access to specific API paths or MCP tools.<a href="#section-5.2-4.7.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.8">

  act: nested actor identities, see <a href="#self-issued-rules" class="auto internal xref">Section 5.3</a>.<a href="#section-5.2-4.8.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.2-4.9">

  agent_context: optional agentic context, e.g., task_id, goal, and delegation_depth.<a href="#section-5.2-4.9.1" class="pilcrow">¶</a>

  </div>

The following is an example of an initial-hop Delegation Assertion:<a href="#section-5.2-5" class="pilcrow">¶</a>

<div id="section-5.2-6" class="lang-json sourcecode">

    {
      "iss": "spiffe://cluster.local/ns/prod/sa/service-a",
      "sub": "user_original_12345",
      "aud": "https://auth.enterprise.net/oauth/token",
      "exp": 1776326800,
      "nbf": 1776326740,
      "jti": "urn:uuid:8e41-4b72-9b2a-111122223333",
      "scope": "reports:read",
      "authorization_details": [
        {
          "type": "api_access",
          "actions": ["GET"],
          "locations": ["/api/v1/reports/q3.pdf"]
        }
      ]
    }

<a href="#section-5.2-6" class="pilcrow">¶</a>

</div>

</div>

</div>

<div id="self-issued-rules">

<div id="section-5.3" class="section">

### <a href="#section-5.3" class="section-number selfRef">5.3.</a> <a href="#name-re-issuance-rules" class="section-name selfRef">Re-Issuance Rules</a>

When an intermediate entity, e.g., Agent B, needs to delegate further down the chain, e.g., to Agent C, it MUST NOT forward the original upstream assertion directly and MUST NOT contact the root IdP. It self-issues a new downstream Delegation Assertion following three rules:<a href="#section-5.3-1" class="pilcrow">¶</a>

1.  <div id="section-5.3-2.1">

    Monotonic Scope Attenuation Rule: The re-issued assertion's scope or authorization_details MUST be a subset of or equal to the permissions granted to the re-issuing entity. Privilege escalation is strictly prohibited.<a href="#section-5.3-2.1.1" class="pilcrow">¶</a>

    </div>

2.  <div id="section-5.3-2.2">

    Actor Chain Nesting Rule: The re-issuing entity MUST append the upstream issuer's identity into an act claim structure within the assertion payload, preserving auditability.<a href="#section-5.3-2.2.1" class="pilcrow">¶</a>

    </div>

3.  <div id="section-5.3-2.3">

    Audience Re-Binding Rule: The re-issuing entity MUST update the aud claim to target the token endpoint of the downstream AS or resource boundary.<a href="#section-5.3-2.3.1" class="pilcrow">¶</a>

    </div>

The following is an example of a re-issued assertion for the hop Agent B to Agent C:<a href="#section-5.3-3" class="pilcrow">¶</a>

<div id="section-5.3-4" class="lang-json sourcecode">

    {
      "iss": "spiffe://cluster.local/ns/ai/sa/agent-b",
      "sub": "user_original_12345",
      "aud": "https://auth.enterprise.net/oauth/token",
      "exp": 1776326900,
      "nbf": 1776326840,
      "jti": "urn:uuid:f901-2222-3333-444455556666",
      "act": {
        "sub": "spiffe://cluster.local/ns/ai/sa/agent-a"
      },
      "scope": "reports:read:q3_only",
      "agent_context": {
        "task_id": "task-q3-summary-001",
        "delegation_depth": 2
      }
    }

<a href="#section-5.3-4" class="pilcrow">¶</a>

</div>

</div>

</div>

<div id="self-issued-redemption">

<div id="section-5.4" class="section">

### <a href="#section-5.4" class="section-number selfRef">5.4.</a> <a href="#name-redemption-at-the-authoriza" class="section-name selfRef">Redemption at the Authorization Server</a>

A target entity that received a Delegation Assertion redeems it at the AS named by the aud claim. The request is the Token Exchange request of <a href="#exchange-request" class="auto internal xref">Section 4.2</a>, with the Delegation Assertion as the subject_token, subject_token_type set to urn:ietf:params:oauth:token-type:jwt, and the target entity's JWT-SVID as the actor_token. The AS validates the Delegation Assertion signature via the delegating entity's public keys, checks exp, nbf, and jti, verifies the act chain lineage, and applies the attenuation and policy checks of <a href="#as-processing" class="auto internal xref">Section 4.3</a> before issuing an Access Token.<a href="#section-5.4-1" class="pilcrow">¶</a>

This variant has weaker guarantees than the primary mechanism, and implementers need to understand them:<a href="#section-5.4-2" class="pilcrow">¶</a>

- <div id="section-5.4-3.1">

  The root authorization of the end-user is asserted by the first delegating entity, not issued by the AS. The AS SHOULD corroborate it, for example by requiring the end-user's token alongside the Delegation Assertion at redemption.<a href="#section-5.4-3.1.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.4-3.2">

  Attenuation performed by intermediate entities is not independently verifiable. The AS trusts the signatures of the self-issued assertions and applies its own policy, but a compromised intermediate can misstate the privileges it inherited.<a href="#section-5.4-3.2.1" class="pilcrow">¶</a>

  </div>

- <div id="section-5.4-3.3">

  A Delegation Assertion does not name the entity entitled to present it. Presenters are authenticated, but any holder can attempt redemption. Short lifetimes and policy restrictions limit this exposure but do not remove it.<a href="#section-5.4-3.3.1" class="pilcrow">¶</a>

  </div>

</div>

</div>

</div>

</div>

<div id="security-considerations">

<div id="section-6" class="section">

## <a href="#section-6" class="section-number selfRef">6.</a> <a href="#name-security-considerations" class="section-name selfRef">Security Considerations</a>

<div id="sec-audience">

<div id="section-6.1" class="section">

### <a href="#section-6.1" class="section-number selfRef">6.1.</a> <a href="#name-audience-and-hop-binding" class="section-name selfRef">Audience and Hop Binding</a>

The aud claim of every ID-JAG in the chain identifies the AS that redeems it, which prevents cross-service injection of ID-JAGs into other security domains. The may_act claim additionally binds each ID-JAG to the single entity entitled to redeem it. An ID-JAG stolen in transit or from a compromised workload cannot be redeemed by a different workload, because its JWT-SVID does not match may_act.<a href="#section-6.1-1" class="pilcrow">¶</a>

For self-issued Delegation Assertions, the aud claim MUST be strictly locked to the token endpoint of the AS to prevent cross-service injection or replay.<a href="#section-6.1-2" class="pilcrow">¶</a>

</div>

</div>

<div id="sec-attenuation">

<div id="section-6.2" class="section">

### <a href="#section-6.2" class="section-number selfRef">6.2.</a> <a href="#name-monotonic-attenuation" class="section-name selfRef">Monotonic Attenuation</a>

Downstream privilege scopes can only be equal to or narrower than upstream permissions. The AS enforces this at every hop of the primary mechanism, which eliminates unauthorized privilege expansion across multi-hop agent or service chains. In the self-issued variant, attenuation is asserted by the delegating entities and checked only at redemption time, see <a href="#self-issued-redemption" class="auto internal xref">Section 5.4</a>.<a href="#section-6.2-1" class="pilcrow">¶</a>

</div>

</div>

<div id="sec-replay">

<div id="section-6.3" class="section">

### <a href="#section-6.3" class="section-number selfRef">6.3.</a> <a href="#name-replay-prevention" class="section-name selfRef">Replay Prevention</a>

The AS MUST enforce jti uniqueness for the tokens it issues and for the Delegation Assertions it redeems. Self-issued Delegation Assertions MUST have a short lifespan, a lifetime of 60 seconds or less is recommended.<a href="#section-6.3-1" class="pilcrow">¶</a>

</div>

</div>

<div id="sec-transport">

<div id="section-6.4" class="section">

### <a href="#section-6.4" class="section-number selfRef">6.4.</a> <a href="#name-transport-and-confidentiali" class="section-name selfRef">Transport and Confidentiality</a>

ID-JAGs and Delegation Assertions are credentials passed over inter-agent transports, e.g., HTTP headers, gRPC metadata, or MCP payloads. They MUST be sent over TLS or an equivalently protected transport. They MUST NOT be logged or persisted in plaintext by intermediaries.<a href="#section-6.4-1" class="pilcrow">¶</a>

</div>

</div>

<div id="sec-workload">

<div id="section-6.5" class="section">

### <a href="#section-6.5" class="section-number selfRef">6.5.</a> <a href="#name-workload-identity-compromis" class="section-name selfRef">Workload Identity Compromise</a>

The actor_token binds the chain to workload identities. A compromised workload can act within the privileges delegated to it. JWT-SVIDs are short-lived and rotated by the infrastructure, which limits the window of a stolen SVID. Compromise of an intermediate workload is bounded by the monotonic attenuation already applied upstream, but AS policy SHOULD also cap the total delegation depth and the privileges available to each hop.<a href="#section-6.5-1" class="pilcrow">¶</a>

</div>

</div>

</div>

</div>

<div id="iana">

<div id="section-7" class="section">

## <a href="#section-7" class="section-number selfRef">7.</a> <a href="#name-iana-considerations" class="section-name selfRef">IANA Considerations</a>

This document has no IANA actions.<a href="#section-7-1" class="pilcrow">¶</a>

</div>

</div>

<div id="section-8" class="section">

## <a href="#section-8" class="section-number selfRef">8.</a> <a href="#name-normative-references" class="section-name selfRef">Normative References</a>

\[RFC2119\]  
<span class="refAuthor">Bradner, S.</span>, <span class="refTitle">"Key words for use in RFCs to Indicate Requirement Levels"</span>, <span class="seriesInfo">BCP 14</span>, <span class="seriesInfo">RFC 2119</span>, <span class="seriesInfo">DOI 10.17487/RFC2119</span>, March 1997, \<<https://www.rfc-editor.org/info/rfc2119>\>.

\[RFC6749\]  
<span class="refAuthor">Hardt, D., Ed.</span>, <span class="refTitle">"The OAuth 2.0 Authorization Framework"</span>, <span class="seriesInfo">RFC 6749</span>, <span class="seriesInfo">DOI 10.17487/RFC6749</span>, October 2012, \<<https://www.rfc-editor.org/info/rfc6749>\>.

\[RFC7519\]  
<span class="refAuthor">Jones, M.</span>, <span class="refAuthor">Bradley, J.</span>, and <span class="refAuthor">N. Sakimura</span>, <span class="refTitle">"JSON Web Token (JWT)"</span>, <span class="seriesInfo">RFC 7519</span>, <span class="seriesInfo">DOI 10.17487/RFC7519</span>, May 2015, \<<https://www.rfc-editor.org/info/rfc7519>\>.

\[RFC8174\]  
<span class="refAuthor">Leiba, B.</span>, <span class="refTitle">"Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words"</span>, <span class="seriesInfo">BCP 14</span>, <span class="seriesInfo">RFC 8174</span>, <span class="seriesInfo">DOI 10.17487/RFC8174</span>, May 2017, \<<https://www.rfc-editor.org/info/rfc8174>\>.

\[RFC8693\]  
<span class="refAuthor">Jones, M.</span>, <span class="refAuthor">Nadalin, A.</span>, <span class="refAuthor">Campbell, B., Ed.</span>, <span class="refAuthor">Bradley, J.</span>, and <span class="refAuthor">C. Mortimore</span>, <span class="refTitle">"OAuth 2.0 Token Exchange"</span>, <span class="seriesInfo">RFC 8693</span>, <span class="seriesInfo">DOI 10.17487/RFC8693</span>, January 2020, \<<https://www.rfc-editor.org/info/rfc8693>\>.

\[RFC9396\]  
<span class="refAuthor">Lodderstedt, T.</span>, <span class="refAuthor">Richer, J.</span>, and <span class="refAuthor">B. Campbell</span>, <span class="refTitle">"OAuth 2.0 Rich Authorization Requests"</span>, <span class="seriesInfo">RFC 9396</span>, <span class="seriesInfo">DOI 10.17487/RFC9396</span>, May 2023, \<<https://www.rfc-editor.org/info/rfc9396>\>.

\[I-D.ietf-oauth-identity-assertion-authz-grant\]  
<span class="refAuthor">Parecki, A.</span>, <span class="refAuthor">McGuinness, K.</span>, and <span class="refAuthor">B. Campbell</span>, <span class="refTitle">"Identity Assertion JWT Authorization Grant"</span>, <span class="refContent">Work in Progress</span>, <span class="seriesInfo">Internet-Draft, draft-ietf-oauth-identity-assertion-authz-grant-04</span>, 21 May 2026, \<<https://datatracker.ietf.org/doc/html/draft-ietf-oauth-identity-assertion-authz-grant-04>\>.

\[SPIFFE-ID\]  
<span class="refAuthor">SPIFFE Project</span>, <span class="refTitle">"SPIFFE ID Standards"</span>, \<<https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE-ID.md>\>.

\[SPIFFE-JWT-SVID\]  
<span class="refAuthor">SPIFFE Project</span>, <span class="refTitle">"JWT-SVID Standards"</span>, \<<https://github.com/spiffe/spiffe/blob/main/standards/JWT-SVID.md>\>.

</div>

<div id="section-9" class="section">

## <a href="#section-9" class="section-number selfRef">9.</a> <a href="#name-informative-references" class="section-name selfRef">Informative References</a>

\[RFC7517\]  
<span class="refAuthor">Jones, M.</span>, <span class="refTitle">"JSON Web Key (JWK)"</span>, <span class="seriesInfo">RFC 7517</span>, <span class="seriesInfo">DOI 10.17487/RFC7517</span>, May 2015, \<<https://www.rfc-editor.org/info/rfc7517>\>.

\[I-D.ietf-oauth-spiffe-client-auth\]  
<span class="refAuthor">Schwenkschuster, A.</span>, <span class="refAuthor">Kasselman, P.</span>, <span class="refAuthor">Rose, S.</span>, <span class="refAuthor">Thorgersen, S.</span>, and <span class="refAuthor">N. Cam-Winget</span>, <span class="refTitle">"OAuth SPIFFE Client Authentication"</span>, <span class="refContent">Work in Progress</span>, <span class="seriesInfo">Internet-Draft, draft-ietf-oauth-spiffe-client-auth-02</span>, 15 June 2026, \<<https://datatracker.ietf.org/doc/html/draft-ietf-oauth-spiffe-client-auth-02>\>.

\[OpenID.Core\]  
<span class="refAuthor">Sakimura, N.</span>, <span class="refAuthor">Bradley, J.</span>, <span class="refAuthor">Jones, M.</span>, <span class="refAuthor">de Medeiros, B.</span>, and <span class="refAuthor">C. Jayawardena</span>, <span class="refTitle">"OpenID Connect Core 1.0 incorporating errata set 1"</span>, November 2014, \<<https://openid.net/specs/openid-connect-core-1_0.html>\>.

</div>

<div id="use-case">

<div id="appendix-A" class="section">

## <a href="#appendix-A" class="section-number selfRef">Appendix A.</a> <a href="#name-complete-end-to-end-use-cas" class="section-name selfRef">Complete End-to-End Use Case: Multi-Hop Financial Research Agent Workflow</a>

To illustrate the practical application of this specification, this appendix provides a step-by-step walkthrough of a multi-hop AI agent workflow.<a href="#appendix-A-1" class="pilcrow">¶</a>

<div id="scenario-overview">

<div id="appendix-A.1" class="section">

### <a href="#appendix-A.1" class="section-number selfRef">A.1.</a> <a href="#name-scenario-overview" class="section-name selfRef">Scenario Overview</a>

An enterprise user (alice@enterprise.com) wants to generate a Q3 financial summary. The workflow involves the following entities:<a href="#appendix-A.1-1" class="pilcrow">¶</a>

1.  <div id="appendix-A.1-2.1">

    User / Client App: Initiates the high-level request.<a href="#appendix-A.1-2.1.1" class="pilcrow">¶</a>

    </div>

2.  <div id="appendix-A.1-2.2">

    Agent A (Research Coordinator, spiffe://cluster.local/ns/ai/sa/agent-researcher): Receives the user goal and delegates raw data retrieval.<a href="#appendix-A.1-2.2.1" class="pilcrow">¶</a>

    </div>

3.  <div id="appendix-A.1-2.3">

    Agent B (Database Proxy Agent, spiffe://cluster.local/ns/ai/sa/agent-db-proxy): Receives the delegated task and delegates specific query execution to a specialized worker.<a href="#appendix-A.1-2.3.1" class="pilcrow">¶</a>

    </div>

4.  <div id="appendix-A.1-2.4">

    Agent C (Financial DB Worker / MCP Server, spiffe://cluster.local/ns/ai/sa/agent-db-worker): Executes the underlying database query.<a href="#appendix-A.1-2.4.1" class="pilcrow">¶</a>

    </div>

5.  <div id="appendix-A.1-2.5">

    Authorization Server (https://auth.enterprise.net): Manages identity validation, Token Exchange, and actor chain generation.<a href="#appendix-A.1-2.5.1" class="pilcrow">¶</a>

    </div>

6.  <div id="appendix-A.1-2.6">

    Financial Database Resource Server (https://db.enterprise.net): Serves the report data.<a href="#appendix-A.1-2.6.1" class="pilcrow">¶</a>

    </div>

</div>

</div>

<div id="protocol-flow">

<div id="appendix-A.2" class="section">

### <a href="#appendix-A.2" class="section-number selfRef">A.2.</a> <a href="#name-step-by-step-protocol-flow" class="section-name selfRef">Step-by-Step Protocol Flow</a>

Step 1 (Initial Authentication): Alice authenticates to the AS via OpenID Connect <a href="#OpenID.Core" class="internal xref">OpenID.Core</a>. Agent A requests its initial ID-JAG with the ID-JAG grant <a href="#I-D.ietf-oauth-identity-assertion-authz-grant" class="internal xref">draft-ietf-oauth-identity-assertion-authz-grant</a>, presenting Alice's ID Token as the identity assertion and requesting the scope "reports:read mail:send".<a href="#appendix-A.2-1" class="pilcrow">¶</a>

Step 2 (Hop 1, Agent A to Agent B): Agent A decides to delegate the data retrieval. It sends the Token Exchange request of <a href="#exchange-request" class="auto internal xref">Section 4.2</a> with subject_token set to its ID-JAG, actor_token set to its JWT-SVID, audience set to Agent B's SPIFFE ID, and scope set to reports:read. The AS validates the request as described in <a href="#as-processing" class="auto internal xref">Section 4.3</a> and issues the ID-JAG shown in the first example of <a href="#issued-id-jag" class="auto internal xref">Section 4.4</a>, with act recording Agent A and may_act naming Agent B. Agent A passes the ID-JAG to Agent B over the A2A transport.<a href="#appendix-A.2-2" class="pilcrow">¶</a>

Step 3 (Hop 2, Agent B to Agent C): Agent B needs the specialized worker for the actual query. It presents the received ID-JAG as the subject_token and its own JWT-SVID as the actor_token, with audience set to Agent C's SPIFFE ID and scope set to reports:read:q3_only. The AS verifies that Agent B matches the may_act claim of the subject_token, checks the attenuation from reports:read to reports:read:q3_only, and issues the ID-JAG shown in the second example of <a href="#issued-id-jag" class="auto internal xref">Section 4.4</a>. Agent B passes it to Agent C.<a href="#appendix-A.2-3" class="pilcrow">¶</a>

Step 4 (Final Exchange at Agent C): Agent C presents the received ID-JAG and its own JWT-SVID, requesting an Access Token for https://db.enterprise.net with scope reports:read:q3_only. The AS validates as before and issues an Access Token that carries the complete lineage:<a href="#appendix-A.2-4" class="pilcrow">¶</a>

<div id="appendix-A.2-5" class="lang-json sourcecode">

    {
      "iss": "https://auth.enterprise.net",
      "sub": "user_original_12345",
      "aud": "https://db.enterprise.net",
      "exp": 1776326950,
      "iat": 1776326890,
      "jti": "urn:uuid:1a2b-3c4d-5e6f-708192a3b4c5",
      "scope": "reports:read:q3_only",
      "act": {
        "sub": "spiffe://cluster.local/ns/ai/sa/agent-db-worker",
        "act": {
          "sub": "spiffe://cluster.local/ns/ai/sa/agent-db-proxy",
          "act": {
            "sub": "spiffe://cluster.local/ns/ai/sa/agent-researcher"
          }
        }
      }
    }

<a href="#appendix-A.2-5" class="pilcrow">¶</a>

</div>

Step 5 (Execution): Agent C presents the Access Token to the Financial Database Resource Server. The Resource Server validates the audience and reads the act chain, achieving verifiable multi-hop provenance: User Alice -\> Agent-Researcher -\> Agent-DB-Proxy -\> Agent-DB-Worker.<a href="#appendix-A.2-6" class="pilcrow">¶</a>

</div>

</div>

</div>

</div>

<div id="appendix-B" class="section">

## <a href="#name-acknowledgments" class="section-name selfRef">Acknowledgments</a>

The authors thank Hongru Zhu, Hui Xue, and Suresh Krishnan for enlightening discussions.<a href="#appendix-B-1" class="pilcrow">¶</a>

</div>

<div id="authors-addresses">

<div id="appendix-C" class="section">

## <a href="#name-authors-addresses" class="section-name selfRef">Authors' Addresses</a>

<div class="left" dir="auto">

<span class="fn nameRole">Dapeng Liu</span>

</div>

<div class="left" dir="auto">

<span class="org">Alibaba Group</span>

</div>

<div class="email">

Email: <max.ldp@alibaba-inc.com>

</div>

<div class="left" dir="auto">

<span class="fn nameRole">Aaron Parecki</span>

</div>

<div class="left" dir="auto">

<span class="org">Okta</span>

</div>

<div class="email">

Email: <aaron@parecki.com>

</div>

</div>

</div>
