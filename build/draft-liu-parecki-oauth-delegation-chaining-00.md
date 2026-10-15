# Delegation Chaining for the Identity Assertion JWT Authorization Grant

## Abstract

The Identity Assertion JWT Authorization Grant (ID-JAG) defines how a client obtains a delegated authorization grant from an identity assertion. It leaves the validation of the actor_token, the related policy evaluation, and the act claim of the issued ID-JAG open for future profiles. This specification defines those rules for delegation chains, in which a series of workloads, such as AI agents, act on behalf of an initial end-user across multiple hops.¶

Each delegating workload authenticates with a SPIFFE JWT-SVID and presents the ID-JAG it holds as the subject_token of an OAuth 2.0 Token Exchange request. The Authorization Server validates the workload identity, checks that the actor matches the may_act claim of the subject_token, and enforces monotonic scope attenuation. It then issues a new ID-JAG for the next hop, carrying the actor chain in the act claim. An optional variant based on self-issued Delegation Assertions is defined for hops where the Authorization Server is not reachable.¶

## 1. Introduction and Problem Statement

In modern distributed multi-tier application architectures and autonomous AI agent ecosystems (e.g., User -\> Agent A -\> Agent B -\> Agent C -\> MCP Tool), service-to-service execution chains frequently cross trust boundaries while operating on behalf of an initial end-user.¶

The OAuth 2.0 framework RFC 6749 and the Identity Assertion JWT Authorization Grant (ID-JAG) draft-ietf-oauth-identity-assertion-authz-grant address identity assertions and authorization grants for single-hop scenarios. However, two gaps remain in multi-hop execution chains:¶

1.  The actor_token validation gap. <a href="https://datatracker.ietf.org/doc/html/draft-ietf-oauth-identity-assertion-authz-grant-04#section-4.3" class="relref">Section 4.3</a> of \[I-D.ietf-oauth-identity-assertion-authz-grant\] states: "This specification does not define normative processing requirements for actor_token or whether an act claim is included in the issued ID-JAG. Future profiles or extensions MAY define how actor_token is validated, how it influences policy evaluation, and whether it results in an act claim in the issued ID-JAG."¶

2.  The delegation continuation gap. A standardized mechanism is needed that lets an intermediate delegate, e.g., Agent B, propagate the end-user's authorization further down the chain, e.g., to Agent C, with strictly narrowed privileges, while keeping every hop verifiable against a common trust root.¶

This specification is such a profile. It defines how actor_token is validated, how it influences policy evaluation, and how the act claim is populated when ID-JAGs are chained across multiple hops. The mechanism combines:¶

1.  SPIFFE workload identities, carried as JWT-SVIDs, as the machine identity of each actor SPIFFE-ID SPIFFE-JWT-SVID.¶

2.  OAuth 2.0 Token Exchange RFC 8693 as the point where the machine identity of the delegating workload and the delegated authorization of the end-user are verified and merged by the Authorization Server (AS).¶

3.  The may_act claim (<a href="https://rfc-editor.org/rfc/rfc8693#section-4.4" class="relref">Section 4.4</a> of \[RFC8693\]) to bind each issued ID-JAG to the entity entitled to redeem it at the next hop, and the act claim (<a href="https://rfc-editor.org/rfc/rfc8693#section-4.1" class="relref">Section 4.1</a> of \[RFC8693\]) to carry the delegation lineage.¶

Every hop of the chain performs exactly one Token Exchange request. The AS is the only issuer of ID-JAGs in the chain, so privilege attenuation is enforced by the AS at every hop rather than merely asserted by the delegating entity, and the full lineage, e.g., User -\> Agent A -\> Agent B -\> Agent C, is carried in the act claim of the final Access Token.¶

For hops where a round trip to the AS is not practical, for example across trust domains with no reachable common AS, this document also defines an optional variant based on self-issued Delegation Assertions, see Section 5. That variant offers weaker guarantees and supplements, but does not replace, the Token Exchange mechanism.¶

## 2. Terminology and Architecture Overview

This specification uses the terms "authorization server" (AS), "client", "resource server" (RS), and "access token" defined in RFC 6749, the token exchange parameters defined in <a href="https://rfc-editor.org/rfc/rfc8693#section-2.1" class="relref">Section 2.1</a> of \[RFC8693\], and the act and may_act claims defined in <a href="https://rfc-editor.org/rfc/rfc8693#section-4.1" class="relref">Section 4.1</a> of \[RFC8693\] and <a href="https://rfc-editor.org/rfc/rfc8693#section-4.4" class="relref">Section 4.4</a> of \[RFC8693\].¶

In addition, this specification defines the following roles and credentials:¶

<span class="break"></span>

ID-JAG  
An Identity Assertion JWT Authorization Grant draft-ietf-oauth-identity-assertion-authz-grant. In this profile, an ID-JAG represents the delegated authorization of the end-user held by one entity of the chain.¶

Delegating Entity (e.g., Agent A / Service A)  
An upstream workload that holds an ID-JAG and delegates a sub-operation or task to a downstream entity.¶

Target Entity (e.g., Agent B / Service B)  
A downstream workload that receives the delegated authorization, executes computations, or further delegates to subsequent entities.¶

Workload Identity (SPIFFE SVID)  
A machine identity credential issued to each workload instance by trusted infrastructure, such as SPIRE, serving as the immutable actor proof SPIFFE-ID SPIFFE-JWT-SVID.¶

Delegation Assertion (DA)  
A short-lived JWT self-issued by a delegating entity in the optional variant of Section 5, carrying the initial user context, the delegation history, and privilege attenuation limits.¶

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 \[RFC2119\] \[RFC8174\] when, and only when, they appear in all capitals, as shown here.¶

## 3. Workload Identity of the Actor

Every workload in the chain, for example an AI agent runtime or a container hosting an agentic loop, is provisioned with a cryptographic machine identity by trusted infrastructure, such as a SPIRE server. The identity is a SPIFFE ID SPIFFE-ID of the form:¶

    spiffe://<trust-domain>/ns/<namespace>/sa/<workload-name>

¶

The workload proves this identity with a JWT-SVID, a JWT whose sub claim carries the SPIFFE ID and which is signed by the SPIRE server of the trust domain. Verifying a JWT-SVID requires the SPIFFE trust bundle of that trust domain. JWT-SVIDs are short-lived by design SPIFFE-JWT-SVID.¶

In this profile, the JWT-SVID of the delegating entity is presented as the actor_token of the Token Exchange request described in Section 4.2. This binds the machine identity of the current actor into the delegation chain, independently of any application-level identity. The JWT-SVID MAY also serve as the client authentication credential at the token endpoint, as described in draft-ietf-oauth-spiffe-client-auth. When SVID-based client authentication is not used, the AS MUST still authenticate the client with some other mechanism.¶

## 4. Delegation Chaining with Token Exchange

### 4.1. Overview

The chain starts like any ID-JAG flow. The end-user authenticates to the AS, for example with OpenID Connect OpenID.Core. The first workload, Agent A, requests its initial ID-JAG with the ID-JAG grant draft-ietf-oauth-identity-assertion-authz-grant, presenting the end-user's identity assertion. The initial ID-JAG has the end-user as its subject and carries the end-user's authorization for Agent A.¶

When Agent A decides to delegate a sub-operation to Agent B, it does not mint the delegated credential itself. Agent A sends a Token Exchange request to the token endpoint of the AS: subject_token is the ID-JAG Agent A holds, actor_token is Agent A's JWT-SVID, and audience names Agent B. The AS validates the request as described in Section 4.3 and issues a new ID-JAG. The subject remains the end-user, the act claim records Agent A as the current actor, and the may_act claim names Agent B as the entity entitled to redeem the new ID-JAG.¶

Agent A passes the new ID-JAG to Agent B over the inter-agent transport, for example an HTTP header, gRPC metadata, or an MCP payload. Agent B now holds the delegated authorization and can either redeem it for an Access Token of a resource server or delegate further to Agent C in exactly the same way. Each hop of the chain therefore performs exactly one Token Exchange request, and every ID-JAG in the chain is issued by the same AS.¶

The chain ends when the last workload exchanges the ID-JAG it holds for an Access Token of the resource server it needs to call. The Access Token carries the complete actor chain in its act claim, e.g., User -\> Agent A -\> Agent B -\> Agent C, which gives the resource server verifiable multi-hop provenance.¶

When the target entity operates in a different trust domain with its own AS, the AS of the delegating entity issues the ID-JAG with the aud claim set to the issuer identifier of the target domain's AS, as described in draft-ietf-oauth-identity-assertion-authz-grant. The target entity redeems the ID-JAG there. The processing requirements of Section 4.3 apply at whichever AS redeems the ID-JAG.¶

### 4.2. Token Exchange Request

Each hop of the chain is one Token Exchange request to the token endpoint of the AS, as defined in <a href="https://rfc-editor.org/rfc/rfc8693#section-2.1" class="relref">Section 2.1</a> of \[RFC8693\], with the following parameters:¶

    grant_type=urn:ietf:params:oauth:grant-type:token-exchange
    subject_token=(the ID-JAG held by the delegating entity)
    subject_token_type=urn:ietf:params:oauth:token-type:id-jag
    actor_token=(the JWT-SVID of the delegating entity)
    actor_token_type=urn:ietf:params:oauth:token-type:jwt
    requested_token_type=urn:ietf:params:oauth:token-type:id-jag
    audience=(the SPIFFE ID or resource URI of the target entity)
    scope=(no wider than the scope of the subject_token)

¶

The audience parameter names the target entity of the delegation, e.g., its SPIFFE ID. The aud claim of the issued ID-JAG continues to identify the AS that redeems it, as required by draft-ietf-oauth-identity-assertion-authz-grant. The AS records the target entity in the may_act claim of the issued ID-JAG instead, which binds the ID-JAG to the entity entitled to redeem it in the next exchange.¶

The delegating entity is both the authenticated client and the actor of the exchange. It SHOULD authenticate at the token endpoint with its JWT-SVID, as described in draft-ietf-oauth-spiffe-client-auth, so that the client identity and the actor_token carry the same machine identity. Other client authentication methods MAY be used, in which case the AS still MUST verify that the actor_token matches the authenticated client, see Section 4.3.¶

The last hop of the chain requests an Access Token instead of an ID-JAG, with requested_token_type=urn:ietf:params:oauth:token-type:access_token and audience set to the resource server. The response to every exchange follows <a href="https://rfc-editor.org/rfc/rfc8693#section-2.2.1" class="relref">Section 2.2.1</a> of \[RFC8693\]. For an ID-JAG, the ID-JAG is returned in the access_token parameter and token_type is set to N_A.¶

### 4.3. Authorization Server Processing Requirements

Upon receiving a Token Exchange request as described in Section 4.2, the AS executes the following verification and policy evaluation pipeline. These requirements answer the questions that <a href="https://datatracker.ietf.org/doc/html/draft-ietf-oauth-identity-assertion-authz-grant-04#section-4.3" class="relref">Section 4.3</a> of \[I-D.ietf-oauth-identity-assertion-authz-grant\] leaves open, and they apply at every hop of the chain:¶

1.  Client authentication: The AS MUST authenticate the client making the request. SVID-based client authentication draft-ietf-oauth-spiffe-client-auth SHOULD be used, in which case the authenticated client is identified by its SPIFFE ID.¶

2.  Actor validation: The actor_token MUST be a JWT-SVID SPIFFE-JWT-SVID. The AS MUST verify its signature against the SPIFFE trust bundle of the actor's trust domain, MUST verify its temporal validity (exp and nbf), and MUST verify that it is an intended audience of the JWT-SVID as identified by its aud claim. The SPIFFE ID in the sub claim of the actor_token MUST identify the authenticated client. The AS MUST reject the request otherwise.¶

3.  Subject validation: The subject_token MUST be validated as an ID-JAG as required by draft-ietf-oauth-identity-assertion-authz-grant, including signature, issuer, audience, expiration, not-before, and jti. The aud claim of the subject_token MUST identify the AS itself. Because the AS issued every ID-JAG in the chain, the signature of the subject_token also covers its act chain.¶

4.  Hop binding: If the subject_token contains a may_act claim, the AS MUST verify that the sub member of may_act equals the SPIFFE ID of the actor_token, and MUST reject the request otherwise. This binds every ID-JAG to its intended redeemer, so a stolen ID-JAG cannot be redeemed by a different workload, and the delegating entity itself cannot redeem the ID-JAG it requested for its target. If the subject_token contains no may_act claim, the AS MUST apply its own policy to decide whether the current actor may delegate the subject_token further.¶

5.  Attenuation check: The requested scope and authorization_details RFC 9396 MUST be a subset of or equal to those of the subject_token. The AS MUST reject any request that would widen privileges, including requests that add actions, datatypes, or locations to an authorization_details object of the subject_token. The AS MAY further narrow the granted scope and authorization_details based on policy.¶

6.  Delegation policy: The AS MUST apply its delegation policy, e.g., which workloads may call which downstream entities, and which scopes each target entity may receive at all. Policy evaluation takes both the actor identity and the subject authorization as input.¶

7.  Issuance: The AS issues the new ID-JAG with the subject unchanged, i.e., the end-user, and with the attenuated scope and authorization_details. The act and may_act claims are populated as described in Section 4.4. The lifetime of the issued ID-JAG SHOULD be short, and the jti value MUST be unique among all tokens issued by the AS.¶

### 4.4. The Issued ID-JAG

The issued ID-JAG carries the end-user as its subject, the attenuated privileges, and the actor chain. The act claim follows <a href="https://rfc-editor.org/rfc/rfc8693#section-4.1" class="relref">Section 4.1</a> of \[RFC8693\]: the outermost value represents the current actor, and nested values represent prior actors. At each exchange, the AS sets the outermost act value to the actor of the current request and nests the act claim of the subject_token inside it. The may_act claim follows <a href="https://rfc-editor.org/rfc/rfc8693#section-4.4" class="relref">Section 4.4</a> of \[RFC8693\] and names the target entity, i.e., the party entitled to act as the actor in the next exchange.¶

The following is an example of the ID-JAG issued for the first hop, where Agent A delegates to Agent B:¶

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

¶

The following is an example of the ID-JAG issued for the second hop, where Agent B delegates to Agent C. The act claim nests the actor chain, and the scope has been attenuated further:¶

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

¶

Deployments MAY carry additional claims in the issued ID-JAG, e.g., task context for AI agent workloads, as long as the claims required by draft-ietf-oauth-identity-assertion-authz-grant are present.¶

## 5. Optional Variant: Self-Issued Delegation Assertions

This section defines an optional variant for hops where a Token Exchange round trip to the AS is not practical. It keeps the protocol shape of the primary mechanism, a signed JWT passed in-band and redeemed together with a workload identity, but moves assertion issuance from the AS to the delegating entities themselves.¶

### 5.1. Applicability

The self-issued variant applies when the delegating entity and the target entity operate in trust domains with no common reachable AS, or when the added latency of a synchronous exchange at every hop is unacceptable for the workload.¶

The self-issued variant SHOULD NOT be used when the AS of the chain is reachable. Token Exchange gives the AS the opportunity to validate the actor and enforce attenuation at every hop. The self-issued variant cannot provide those guarantees, see Section 5.4.¶

### 5.2. Assertion Format

A Delegation Assertion (DA) is a JWT RFC 7519. A delegating entity, e.g., Agent A, MUST possess a valid authorization grant or active token representing the end-user (sub) before it issues a downstream Delegation Assertion.¶

Each Delegation Assertion MUST be signed using a private key cryptographically tied to the delegating entity's SPIFFE workload identity lifecycle. The AS validates the signature using the delegating entity's registered public key, retrieved via JWKS RFC 7517 or trusted infrastructure metadata.¶

A Delegation Assertion contains the following claims:¶

- iss: the SPIFFE ID of the delegating entity.¶

- sub: the subject identifier of the initial end-user.¶

- aud: the token endpoint of the AS at which the assertion is redeemed.¶

- exp and nbf: a short temporal validity window, a lifetime of 60 seconds or less is recommended.¶

- jti: a unique assertion identifier, used for replay prevention.¶

- scope: the attenuated privilege scope, no wider than the privileges of the issuing entity.¶

- authorization_details: optional fine-grained authorization details via RFC 9396, e.g., access to specific API paths or MCP tools.¶

- act: nested actor identities, see Section 5.3.¶

- agent_context: optional agentic context, e.g., task_id, goal, and delegation_depth.¶

The following is an example of an initial-hop Delegation Assertion:¶

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

¶

### 5.3. Re-Issuance Rules

When an intermediate entity, e.g., Agent B, needs to delegate further down the chain, e.g., to Agent C, it MUST NOT forward the original upstream assertion directly and MUST NOT contact the root IdP. It self-issues a new downstream Delegation Assertion following three rules:¶

1.  Monotonic Scope Attenuation Rule: The re-issued assertion's scope or authorization_details MUST be a subset of or equal to the permissions granted to the re-issuing entity. Privilege escalation is strictly prohibited.¶

2.  Actor Chain Nesting Rule: The re-issuing entity MUST append the upstream issuer's identity into an act claim structure within the assertion payload, preserving auditability.¶

3.  Audience Re-Binding Rule: The re-issuing entity MUST update the aud claim to target the token endpoint of the downstream AS or resource boundary.¶

The following is an example of a re-issued assertion for the hop Agent B to Agent C:¶

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

¶

### 5.4. Redemption at the Authorization Server

A target entity that received a Delegation Assertion redeems it at the AS named by the aud claim. The request is the Token Exchange request of Section 4.2, with the Delegation Assertion as the subject_token, subject_token_type set to urn:ietf:params:oauth:token-type:jwt, and the target entity's JWT-SVID as the actor_token. The AS validates the Delegation Assertion signature via the delegating entity's public keys, checks exp, nbf, and jti, verifies the act chain lineage, and applies the attenuation and policy checks of Section 4.3 before issuing an Access Token.¶

This variant has weaker guarantees than the primary mechanism, and implementers need to understand them:¶

- The root authorization of the end-user is asserted by the first delegating entity, not issued by the AS. The AS SHOULD corroborate it, for example by requiring the end-user's token alongside the Delegation Assertion at redemption.¶

- Attenuation performed by intermediate entities is not independently verifiable. The AS trusts the signatures of the self-issued assertions and applies its own policy, but a compromised intermediate can misstate the privileges it inherited.¶

- A Delegation Assertion does not name the entity entitled to present it. Presenters are authenticated, but any holder can attempt redemption. Short lifetimes and policy restrictions limit this exposure but do not remove it.¶

## 6. Security Considerations

### 6.1. Audience and Hop Binding

The aud claim of every ID-JAG in the chain identifies the AS that redeems it, which prevents cross-service injection of ID-JAGs into other security domains. The may_act claim additionally binds each ID-JAG to the single entity entitled to redeem it. An ID-JAG stolen in transit or from a compromised workload cannot be redeemed by a different workload, because its JWT-SVID does not match may_act.¶

For self-issued Delegation Assertions, the aud claim MUST be strictly locked to the token endpoint of the AS to prevent cross-service injection or replay.¶

### 6.2. Monotonic Attenuation

Downstream privilege scopes can only be equal to or narrower than upstream permissions. The AS enforces this at every hop of the primary mechanism, which eliminates unauthorized privilege expansion across multi-hop agent or service chains. In the self-issued variant, attenuation is asserted by the delegating entities and checked only at redemption time, see Section 5.4.¶

### 6.3. Replay Prevention

The AS MUST enforce jti uniqueness for the tokens it issues and for the Delegation Assertions it redeems. Self-issued Delegation Assertions MUST have a short lifespan, a lifetime of 60 seconds or less is recommended.¶

### 6.4. Transport and Confidentiality

ID-JAGs and Delegation Assertions are credentials passed over inter-agent transports, e.g., HTTP headers, gRPC metadata, or MCP payloads. They MUST be sent over TLS or an equivalently protected transport. They MUST NOT be logged or persisted in plaintext by intermediaries.¶

### 6.5. Workload Identity Compromise

The actor_token binds the chain to workload identities. A compromised workload can act within the privileges delegated to it. JWT-SVIDs are short-lived and rotated by the infrastructure, which limits the window of a stolen SVID. Compromise of an intermediate workload is bounded by the monotonic attenuation already applied upstream, but AS policy SHOULD also cap the total delegation depth and the privileges available to each hop.¶

## 7. IANA Considerations

This document has no IANA actions.¶

## 8. Normative References

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

## 9. Informative References

\[RFC7517\]  
<span class="refAuthor">Jones, M.</span>, <span class="refTitle">"JSON Web Key (JWK)"</span>, <span class="seriesInfo">RFC 7517</span>, <span class="seriesInfo">DOI 10.17487/RFC7517</span>, May 2015, \<<https://www.rfc-editor.org/info/rfc7517>\>.

\[I-D.ietf-oauth-spiffe-client-auth\]  
<span class="refAuthor">Schwenkschuster, A.</span>, <span class="refAuthor">Kasselman, P.</span>, <span class="refAuthor">Rose, S.</span>, <span class="refAuthor">Thorgersen, S.</span>, and <span class="refAuthor">N. Cam-Winget</span>, <span class="refTitle">"OAuth SPIFFE Client Authentication"</span>, <span class="refContent">Work in Progress</span>, <span class="seriesInfo">Internet-Draft, draft-ietf-oauth-spiffe-client-auth-02</span>, 15 June 2026, \<<https://datatracker.ietf.org/doc/html/draft-ietf-oauth-spiffe-client-auth-02>\>.

\[OpenID.Core\]  
<span class="refAuthor">Sakimura, N.</span>, <span class="refAuthor">Bradley, J.</span>, <span class="refAuthor">Jones, M.</span>, <span class="refAuthor">de Medeiros, B.</span>, and <span class="refAuthor">C. Jayawardena</span>, <span class="refTitle">"OpenID Connect Core 1.0 incorporating errata set 1"</span>, November 2014, \<<https://openid.net/specs/openid-connect-core-1_0.html>\>.

## Appendix A. Complete End-to-End Use Case: Multi-Hop Financial Research Agent Workflow

To illustrate the practical application of this specification, this appendix provides a step-by-step walkthrough of a multi-hop AI agent workflow.¶

### A.1. Scenario Overview

An enterprise user (alice@enterprise.com) wants to generate a Q3 financial summary. The workflow involves the following entities:¶

1.  User / Client App: Initiates the high-level request.¶

2.  Agent A (Research Coordinator, spiffe://cluster.local/ns/ai/sa/agent-researcher): Receives the user goal and delegates raw data retrieval.¶

3.  Agent B (Database Proxy Agent, spiffe://cluster.local/ns/ai/sa/agent-db-proxy): Receives the delegated task and delegates specific query execution to a specialized worker.¶

4.  Agent C (Financial DB Worker / MCP Server, spiffe://cluster.local/ns/ai/sa/agent-db-worker): Executes the underlying database query.¶

5.  Authorization Server (https://auth.enterprise.net): Manages identity validation, Token Exchange, and actor chain generation.¶

6.  Financial Database Resource Server (https://db.enterprise.net): Serves the report data.¶

### A.2. Step-by-Step Protocol Flow

Step 1 (Initial Authentication): Alice authenticates to the AS via OpenID Connect OpenID.Core. Agent A requests its initial ID-JAG with the ID-JAG grant draft-ietf-oauth-identity-assertion-authz-grant, presenting Alice's ID Token as the identity assertion and requesting the scope "reports:read mail:send".¶

Step 2 (Hop 1, Agent A to Agent B): Agent A decides to delegate the data retrieval. It sends the Token Exchange request of Section 4.2 with subject_token set to its ID-JAG, actor_token set to its JWT-SVID, audience set to Agent B's SPIFFE ID, and scope set to reports:read. The AS validates the request as described in Section 4.3 and issues the ID-JAG shown in the first example of Section 4.4, with act recording Agent A and may_act naming Agent B. Agent A passes the ID-JAG to Agent B over the A2A transport.¶

Step 3 (Hop 2, Agent B to Agent C): Agent B needs the specialized worker for the actual query. It presents the received ID-JAG as the subject_token and its own JWT-SVID as the actor_token, with audience set to Agent C's SPIFFE ID and scope set to reports:read:q3_only. The AS verifies that Agent B matches the may_act claim of the subject_token, checks the attenuation from reports:read to reports:read:q3_only, and issues the ID-JAG shown in the second example of Section 4.4. Agent B passes it to Agent C.¶

Step 4 (Final Exchange at Agent C): Agent C presents the received ID-JAG and its own JWT-SVID, requesting an Access Token for https://db.enterprise.net with scope reports:read:q3_only. The AS validates as before and issues an Access Token that carries the complete lineage:¶

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

¶

Step 5 (Execution): Agent C presents the Access Token to the Financial Database Resource Server. The Resource Server validates the audience and reads the act chain, achieving verifiable multi-hop provenance: User Alice -\> Agent-Researcher -\> Agent-DB-Proxy -\> Agent-DB-Worker.¶

## Acknowledgments

The authors thank Hongru Zhu, Hui Xue, and Suresh Krishnan for enlightening discussions.¶

## Authors' Addresses

<span class="fn nameRole">Dapeng Liu</span>

<span class="org">Alibaba Group</span>

Email: <max.ldp@alibaba-inc.com>

<span class="fn nameRole">Aaron Parecki</span>

<span class="org">Okta</span>

Email: <aaron@parecki.com>
