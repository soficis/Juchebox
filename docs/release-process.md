# Release Process

Before each release:

1. Review Juchify's current public terms and privacy policy manually.
2. Confirm no Juchify branding, logos, protected screenshots, artwork, or copied assets were added.
3. Run all unit and UI tests.
4. Build with the Release configuration.
5. Confirm App Transport Security has no insecure exceptions.
6. Export diagnostics from a test device and inspect them for sensitive information.
7. Verify the external-domain policy fails closed.
8. Update `CHANGELOG.md`.
9. Tag the source release.
10. Publish a source archive and checksums.

Do not release if the website changes in a way that would require reverse engineering, scraping, page injection, content caching, or bypassing site controls.

