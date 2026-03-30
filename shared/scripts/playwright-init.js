// Suppress navigator.webdriver if exposed by automation context
// This runs before any page script
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
