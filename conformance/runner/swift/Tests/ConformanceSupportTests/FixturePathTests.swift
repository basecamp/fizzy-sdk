import Testing

@testable import ConformanceSupport

/// The implicit path invariant. The scripted transport answers any URL, so
/// without this an operation pointed at the wrong endpoint still consumes the
/// queued responses and passes its retry, status and auth assertions.
@Suite("Fixture path rendering")
struct FixturePathTests {
    @Test("Substitutes every placeholder")
    func substitutesEveryPlaceholder() {
        #expect(
            renderFixturePath(
                "/{accountId}/cards/{cardNumber}/steps.json",
                ["accountId": "999", "cardNumber": "123"])
                == .rendered("/999/cards/123/steps.json"))
    }

    @Test("A template without placeholders is unchanged")
    func templateWithoutPlaceholders() {
        #expect(renderFixturePath("/my/identity.json", [:]) == .rendered("/my/identity.json"))
    }

    @Test("A missing parameter is named rather than left to mismatch")
    func missingParameterIsNamed() {
        #expect(
            renderFixturePath("/{accountId}/boards/{boardId}", ["accountId": "999"])
                == .unsubstituted("boardId"))
    }

    @Test("Extra parameters are ignored")
    func extraParametersIgnored() {
        #expect(
            renderFixturePath("/{accountId}/boards.json", ["accountId": "999", "unused": "1"])
                == .rendered("/999/boards.json"))
    }
}

@Suite("Request path matching")
struct RequestPathMatchingTests {
    @Test("An exact match passes")
    func exactMatch() {
        #expect(requestPathMatches("/999/boards/42", fixturePath: "/999/boards/42"))
    }

    @Test("The .json suffix is the one allowance, in either direction")
    func jsonSuffixAllowance() {
        // BoardsService.get sends /999/boards/1 where retry.json spells
        // /{accountId}/boards/{boardId}.json; WebhooksService.list sends the
        // suffix where a fixture might not.
        #expect(requestPathMatches("/999/boards/1", fixturePath: "/999/boards/1.json"))
        #expect(requestPathMatches("/999/boards/1/webhooks.json", fixturePath: "/999/boards/1/webhooks"))
    }

    @Test("A sibling endpoint does not match")
    func siblingDoesNotMatch() {
        #expect(!requestPathMatches("/999/cards.json", fixturePath: "/999/boards.json"))
    }

    @Test("A suffix collision does not match")
    func suffixCollisionDoesNotMatch() {
        // The reason this is an equality test and not hasSuffix: an operation
        // that hit /999/my/pins.json instead of /999/pins.json would
        // otherwise pass, and the transport serves any URL.
        #expect(!requestPathMatches("/999/my/pins.json", fixturePath: "/pins.json"))
    }

    @Test("A dropped account segment does not match")
    func droppedAccountDoesNotMatch() {
        #expect(!requestPathMatches("/boards.json", fixturePath: "/999/boards.json"))
    }

    @Test("An unsubstituted template cannot match a real path")
    func unsubstitutedTemplateCannotMatch() {
        #expect(!requestPathMatches("/999/boards/42", fixturePath: "/{accountId}/boards/{boardId}"))
    }

    @Test("Only a trailing .json is stripped")
    func onlyTrailingSuffixStripped() {
        #expect(withoutJSONSuffix("/999/boards.json") == "/999/boards")
        #expect(withoutJSONSuffix("/999/boards.json/extra") == "/999/boards.json/extra")
        #expect(withoutJSONSuffix("/999/boards") == "/999/boards")
    }
}

@Suite("Link rel=next parsing")
struct NextLinkTests {
    @Test("Extracts a relative next target")
    func relativeTarget() {
        #expect(nextLinkTarget("</999/boards.json?page=2>; rel=\"next\"") == "/999/boards.json?page=2")
    }

    @Test("Extracts an absolute next target")
    func absoluteTarget() {
        #expect(
            nextLinkTarget("<https://evil.example.com/999/boards.json?page=2>; rel=\"next\"")
                == "https://evil.example.com/999/boards.json?page=2")
    }

    @Test("Picks next out of several links")
    func picksNext() {
        #expect(
            nextLinkTarget("</b?page=1>; rel=\"prev\", </b?page=3>; rel=\"next\"") == "/b?page=3")
    }

    @Test("A header without a next rel yields nil")
    func noNext() {
        #expect(nextLinkTarget("</b?page=1>; rel=\"prev\"") == nil)
        #expect(nextLinkTarget("") == nil)
        #expect(nextLinkTarget("garbage") == nil)
    }

    /// The runner must classify exactly the links the SDK classifies. These
    /// pin the SDK parser's own edges — `parseNextLink` in Pagination.swift —
    /// so a "tidy-up" that made this helper more tolerant (unquoted rel, a
    /// different case, spacing around `=`) would exempt a follower the SDK
    /// never sends, and one that made it stricter would hold a correctly
    /// followed link to the fixture's first path.
    @Test("Is exactly as tolerant as the SDK parser")
    func matchesTheSDKParser() {
        // Only the literal quoted, lowercase rel="next" counts.
        #expect(nextLinkTarget("</p?page=2>; rel=next") == nil)
        #expect(nextLinkTarget("</p?page=2>; rel=\"NEXT\"") == nil)
        #expect(nextLinkTarget("</p?page=2>; rel = \"next\"") == nil)
        // Spacing around the separators is fine; the SDK trims and searches.
        #expect(nextLinkTarget("</p?page=2>;rel=\"next\"") == "/p?page=2")
        #expect(nextLinkTarget("  </p?page=2> ;  rel=\"next\"  ") == "/p?page=2")
        // The SDK takes the FIRST "<" and the FIRST ">" of the part: a ">"
        // before the "<" means the part names no target, and an empty "<>"
        // yields an empty target rather than skipping to the next part.
        #expect(nextLinkTarget(">x</p?page=2>; rel=\"next\"") == nil)
        #expect(nextLinkTarget("<>; rel=\"next\", </p?page=2>; rel=\"next\"") == "")
        #expect(nextLinkTarget("<; rel=\"next\"") == nil)
    }
}
